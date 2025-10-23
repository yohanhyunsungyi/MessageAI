//
//  ChatViewModel.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messageText: String = ""
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var typingUsers: [String] = []
    @Published var conversation: Conversation?

    // MARK: - Private Properties

    private let messageService: MessageService
    private let conversationService: ConversationService
    private let localStorageService: LocalStorageService
    private let authService: AuthService
    private let presenceService: PresenceService

    private var conversationId: String
    private var cancellables = Set<AnyCancellable>()
    private var typingRefreshTimer: Timer?
    private var otherParticipantId: String?
    private var isCurrentlyTyping = false

    // MARK: - Computed Properties

    var currentUserId: String {
        FirebaseManager.shared.currentUserId ?? ""
    }

    var currentUser: User? {
        authService.currentUser
    }

    var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var navigationTitle: String {
        if let conversation = conversation {
            if conversation.type == .group {
                return conversation.groupName ?? "Group Chat"
            } else {
                // Get the other participant's name
                let otherUserIds = conversation.participantIds.filter { $0 != currentUserId }
                if let firstOtherId = otherUserIds.first,
                   let otherName = conversation.participantNames[firstOtherId] {
                    return otherName
                }
            }
        }
        return "Chat"
    }

    var navigationSubtitle: String? {
        if let conversation = conversation, conversation.type == .oneOnOne {
            // Show "typing..." first if someone is typing
            if !typingUsers.isEmpty {
                return "typing..."
            }

            // Show online status for 1-on-1 chats
            if let otherUserId = otherParticipantId {
                if presenceService.isUserOnline(otherUserId) {
                    return "Online"
                } else {
                    // Show "Last seen..." if offline
                    return "Offline"
                }
            }

            return nil
        } else if let conversation = conversation, conversation.type == .group {
            let participantCount = conversation.participantIds.count
            return "\(participantCount) members"
        }
        return nil
    }

    // MARK: - Initialization

    init(
        conversationId: String,
        messageService: MessageService? = nil,
        conversationService: ConversationService? = nil,
        localStorageService: LocalStorageService? = nil,
        authService: AuthService? = nil,
        presenceService: PresenceService? = nil,
        notificationService: NotificationService? = nil
    ) {
        self.conversationId = conversationId

        // Use dependency injection or create defaults
        let localStorage = localStorageService ?? LocalStorageService()
        self.localStorageService = localStorage
        
        let msgService = messageService ?? MessageService(localStorageService: localStorage, notificationService: notificationService)
        self.messageService = msgService
        
        // Set notification service if provided
        if let notifService = notificationService {
            msgService.setNotificationService(notifService)
        }
        
        self.conversationService = conversationService ?? ConversationService(localStorageService: localStorage)
        self.authService = authService ?? AuthService()
        self.presenceService = presenceService ?? PresenceService()

        setupSubscriptions()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Subscribe to message service updates
        messageService.$messages
            .receive(on: DispatchQueue.main)
            .assign(to: &$messages)

        messageService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)

        messageService.$typingUsers
            .receive(on: DispatchQueue.main)
            .assign(to: &$typingUsers)

        // Subscribe to presence updates to trigger UI refresh
        presenceService.$presenceStates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Lifecycle Methods

    func onAppear() async {
        // Mark this conversation as active (suppresses notifications for it)
        messageService.setActiveConversation(conversationId)

        await loadConversation()
        await loadMessages()
        startListening()
        startPresenceListening()
        await markMessagesAsRead()
    }

    func onDisappear() {
        // Clear active conversation (allows notifications again)
        messageService.setActiveConversation(nil)

        stopListening()
        stopPresenceListening()
        stopTyping()
    }

    // MARK: - Data Loading

    private func loadConversation() async {
        do {
            conversation = try await conversationService.getConversation(id: conversationId)
            print("Loaded conversation: \(conversationId)")

            // Get other participant ID for 1-on-1 chats
            if let conversation = conversation, conversation.type == .oneOnOne {
                let otherUserIds = conversation.participantIds.filter { $0 != currentUserId }
                otherParticipantId = otherUserIds.first
            }
        } catch {
            print("Failed to load conversation: \(error)")
            // Don't set errorMessage here - conversation might still load from cache
            // and we want to allow the chat to work even if Firestore is temporarily unavailable
        }
    }

    private func loadMessages() async {
        isLoading = true

        // Load from local storage first for instant display
        await messageService.fetchLocalMessages(conversationId: conversationId)

        isLoading = false
    }

    private func startListening() {
        messageService.startListening(conversationId: conversationId)
        messageService.startListeningForTyping(conversationId: conversationId)
    }

    private func stopListening() {
        messageService.stopListening()
        messageService.stopListeningForTyping()
    }

    // MARK: - Presence Listening

    private func startPresenceListening() {
        // Only listen for presence in 1-on-1 chats
        guard let conversation = conversation,
              conversation.type == .oneOnOne,
              let otherUserId = otherParticipantId else {
            return
        }

        presenceService.startListening(userId: otherUserId)
        print("Started listening to presence for user: \(otherUserId)")
    }

    private func stopPresenceListening() {
        if let otherUserId = otherParticipantId {
            presenceService.stopListening(userId: otherUserId)
            print("Stopped listening to presence for user: \(otherUserId)")
        }
    }

    // MARK: - Message Sending

    func sendMessage() async {
        let textToSend = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSend.isEmpty else { return }

        guard let currentUser = currentUser else {
            errorMessage = "User not authenticated"
            return
        }

        // Clear input immediately for better UX
        let messageCopy = textToSend
        messageText = ""

        // Stop typing indicator
        stopTyping()

        do {
            try await messageService.sendMessage(
                conversationId: conversationId,
                text: messageCopy,
                senderName: currentUser.displayName,
                senderPhotoURL: currentUser.photoURL
            )
        } catch {
            print("Failed to send message: \(error)")
            errorMessage = "Failed to send message. Please try again."
            // Restore message text on failure
            messageText = messageCopy
        }
    }

    // MARK: - Read Receipts

    func markMessagesAsRead() async {
        let unreadMessages = messages.filter { message in
            message.senderId != currentUserId &&
            message.readBy[currentUserId] == nil
        }

        guard !unreadMessages.isEmpty else { return }

        let messageIds = unreadMessages.map { $0.id }

        do {
            try await messageService.markAsRead(
                conversationId: conversationId,
                messageIds: messageIds
            )
        } catch {
            print("Failed to mark messages as read: \(error)")
        }
    }

    // MARK: - Typing Indicators

    func onMessageTextChanged() {
        // Only show typing indicator if there's actually text
        let hasText = !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if hasText {
            // Start typing if not already started
            if !isCurrentlyTyping {
                startTyping()
            }
            // Note: We don't use a debounce timer anymore
            // The typing indicator stays active as long as there's text
            // The refresh timer keeps it alive continuously
        } else {
            // Text is empty, stop typing immediately
            stopTyping()
        }
    }

    private func startTyping() {
        guard !isCurrentlyTyping else { return }
        isCurrentlyTyping = true

        // Send initial typing indicator
        Task {
            try? await messageService.setTyping(conversationId: conversationId, isTyping: true)
        }

        // Start refresh timer - send typing update every 3 seconds to keep it alive
        typingRefreshTimer?.invalidate()
        typingRefreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // Only refresh if we still have text
                let hasText = !self.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                if hasText && self.isCurrentlyTyping {
                    try? await self.messageService.setTyping(conversationId: self.conversationId, isTyping: true)
                }
            }
        }
    }

    private func stopTyping() {
        guard isCurrentlyTyping else { return }
        isCurrentlyTyping = false

        typingRefreshTimer?.invalidate()
        typingRefreshTimer = nil

        Task {
            try? await messageService.setTyping(conversationId: conversationId, isTyping: false)
        }
    }

    // MARK: - Helper Methods

    func getOtherParticipantName() -> String {
        guard let conversation = conversation else { return "Unknown" }

        let otherUserIds = conversation.participantIds.filter { $0 != currentUserId }
        if let firstOtherId = otherUserIds.first,
           let otherName = conversation.participantNames[firstOtherId] {
            return otherName
        }

        return "Unknown"
    }

    func isMessageFromCurrentUser(_ message: Message) -> Bool {
        message.senderId == currentUserId
    }

    func shouldShowSenderName(for message: Message, at index: Int) -> Bool {
        guard conversation?.type == .group else { return false }
        guard !isMessageFromCurrentUser(message) else { return false }

        // Show name if first message or different sender from previous
        if index == 0 {
            return true
        }

        let previousMessage = messages[index - 1]
        return previousMessage.senderId != message.senderId
    }
}
