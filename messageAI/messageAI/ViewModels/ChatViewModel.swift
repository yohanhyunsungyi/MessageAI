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

    private var conversationId: String
    private var cancellables = Set<AnyCancellable>()
    private var typingDebounceTimer: Timer?

    // MARK: - Computed Properties

    var currentUserId: String {
        FirebaseManager.shared.currentUserId ?? ""
    }

    var currentUser: User? {
        authService.currentUser
    }

    var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
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
            // Show online status or "typing..." for 1-on-1 chats
            if !typingUsers.isEmpty {
                return "typing..."
            }
            // Could add presence check here later
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
        authService: AuthService? = nil
    ) {
        self.conversationId = conversationId

        // Use dependency injection or create defaults
        let localStorage = localStorageService ?? LocalStorageService()
        self.localStorageService = localStorage
        self.messageService = messageService ?? MessageService(localStorageService: localStorage)
        self.conversationService = conversationService ?? ConversationService(localStorageService: localStorage)
        self.authService = authService ?? AuthService()

        setupSubscriptions()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Subscribe to message service updates
        messageService.$messages
            .receive(on: DispatchQueue.main)
            .assign(to: &$messages)

        messageService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        messageService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)

        messageService.$typingUsers
            .receive(on: DispatchQueue.main)
            .assign(to: &$typingUsers)
    }

    // MARK: - Lifecycle Methods

    func onAppear() async {
        await loadConversation()
        await loadMessages()
        startListening()
        await markMessagesAsRead()
    }

    func onDisappear() {
        stopListening()
        stopTypingIfNeeded()
    }

    // MARK: - Data Loading

    private func loadConversation() async {
        do {
            conversation = try await conversationService.getConversation(id: conversationId)
            print("Loaded conversation: \(conversationId)")
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
        stopTypingIfNeeded()

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
        // Start typing indicator
        Task {
            try? await messageService.setTyping(conversationId: conversationId, isTyping: true)
        }

        // Reset debounce timer
        typingDebounceTimer?.invalidate()
        typingDebounceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.stopTypingIfNeeded()
        }
    }

    private func stopTypingIfNeeded() {
        typingDebounceTimer?.invalidate()
        typingDebounceTimer = nil

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
