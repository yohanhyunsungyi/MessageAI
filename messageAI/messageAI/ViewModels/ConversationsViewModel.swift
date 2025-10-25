//
//  ConversationsViewModel.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for managing conversations list state and interactions
@MainActor
class ConversationsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var conversations: [Conversation] = []
    @Published var filteredConversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = "" {
        didSet {
            filterConversations()
        }
    }

    // MARK: - Dependencies

    private let conversationService: ConversationService
    private let authService: AuthService
    private let messageService: MessageService
    private var cancellables = Set<AnyCancellable>()
    private var monitoredConversationIds: Set<String> = []

    // MARK: - Initialization

    init(
        conversationService: ConversationService,
        authService: AuthService,
        messageService: MessageService? = nil,
        notificationService: NotificationService? = nil
    ) {
        self.conversationService = conversationService
        self.authService = authService

        // Create or use provided message service for background monitoring
        if let msgService = messageService {
            self.messageService = msgService
        } else {
            // Create a shared message service for monitoring
            let localStorage = conversationService.localStorageService
            self.messageService = MessageService(
                localStorageService: localStorage,
                notificationService: notificationService
            )
        }

        // Set notification service if provided
        if let notifService = notificationService {
            conversationService.setNotificationService(notifService)
            self.messageService.setNotificationService(notifService)
        }

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Observe conversation service changes
        conversationService.$conversations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversations in
                guard let self = self else { return }
                print("🔔 ConversationsViewModel received \(conversations.count) conversations")
                self.conversations = conversations
                self.filterConversations()
                print("🔔 Filtered conversations: \(self.filteredConversations.count)")

                // Only start monitoring if conversation IDs changed (prevents duplicate listeners)
                let currentConversationIds = Set(conversations.map { $0.id })
                if currentConversationIds != self.monitoredConversationIds {
                    print("🔔 Conversation IDs changed - updating monitoring")
                    self.monitoredConversationIds = currentConversationIds
                    self.startMonitoringConversations()
                } else {
                    print("🔔 Same conversations - skipping duplicate monitoring setup")
                }
            }
            .store(in: &cancellables)

        conversationService.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)

        conversationService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Load conversations from local storage and Firestore
    func loadConversations() async {
        do {
            try await conversationService.fetchConversations()
        } catch {
            errorMessage = "Failed to load conversations"
            print("Error loading conversations: \(error.localizedDescription)")
        }
    }

    /// Start listening to real-time conversation updates
    func startListening() {
        guard let userId = authService.currentUser?.id else { return }
        conversationService.startListening(userId: userId)
    }

    /// Stop listening to conversation updates
    func stopListening() {
        conversationService.stopListening()
        // Also stop all conversation monitoring
        messageService.stopAllMonitoring()
    }

    /// Start monitoring all conversations for new messages (for notifications)
    func startMonitoringConversations() {
        print("🔔 Stopping existing monitors before restart")
        messageService.stopAllMonitoring()

        print("🔔 Starting to monitor \(conversations.count) conversations")
        for conversation in conversations {
            messageService.startMonitoring(conversationId: conversation.id)
        }
    }

    /// Get the shared message service (for ChatViewModel)
    func getSharedMessageService() -> MessageService {
        return messageService
    }

    /// Refresh conversations list
    func refresh() async {
        await loadConversations()
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Get display name for conversation (handles one-on-one and group)
    func getConversationName(_ conversation: Conversation) -> String {
        guard let currentUserId = authService.currentUser?.id else {
            return "Unknown"
        }

        if conversation.type == .group {
            return conversation.groupName ?? "Group Chat"
        } else {
            // For one-on-one, show other participant's name
            let otherParticipantId = conversation.participantIds.first { $0 != currentUserId }
            if let otherParticipantId = otherParticipantId {
                return conversation.participantNames[otherParticipantId] ?? "Unknown"
            }
            return "Unknown"
        }
    }

    /// Get subtitle for conversation (last message or participant count)
    func getConversationSubtitle(_ conversation: Conversation) -> String {
        if let lastMessage = conversation.lastMessage {
            return lastMessage
        } else if conversation.type == .group {
            return "\(conversation.participantIds.count) participants"
        } else {
            return "No messages yet"
        }
    }

    /// Get photo URL for conversation
    func getConversationPhotoURL(_ conversation: Conversation) -> String? {
        guard let currentUserId = authService.currentUser?.id else {
            return nil
        }

        if conversation.type == .group {
            // No group photo in MVP
            return nil
        } else {
            // For one-on-one, show other participant's photo
            let otherParticipantId = conversation.participantIds.first { $0 != currentUserId }
            if let otherParticipantId = otherParticipantId {
                return conversation.participantPhotos[otherParticipantId] ?? nil
            }
            return nil
        }
    }

    // MARK: - Private Methods

    /// Filter conversations based on search text and sort by priority
    private func filterConversations() {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        var filtered: [Conversation]
        if trimmedQuery.isEmpty {
            filtered = conversations
        } else {
            filtered = conversations.filter { conversation in
                let conversationName = getConversationName(conversation).lowercased()
                let lastMessage = conversation.lastMessage?.lowercased() ?? ""
                let query = trimmedQuery.lowercased()

                return conversationName.contains(query) || lastMessage.contains(query)
            }
        }

        // Sort conversations: priority first, then timestamp
        filtered.sort { conv1, conv2 in
            let priority1 = conv1.lastMessagePriority?.sortValue ?? 1
            let priority2 = conv2.lastMessagePriority?.sortValue ?? 1

            // Sort by priority (descending - higher value first)
            if priority1 != priority2 {
                return priority1 > priority2
            }

            // If same priority, sort by timestamp (most recent first)
            let timestamp1 = conv1.lastMessageTimestamp ?? Date.distantPast
            let timestamp2 = conv2.lastMessageTimestamp ?? Date.distantPast
            return timestamp1 > timestamp2
        }

        filteredConversations = filtered
    }
}


