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
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        conversationService: ConversationService,
        authService: AuthService,
        notificationService: NotificationService? = nil
    ) {
        self.conversationService = conversationService
        self.authService = authService

        // Set notification service if provided
        if let notifService = notificationService {
            conversationService.setNotificationService(notifService)
        }

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Observe conversation service changes
        conversationService.$conversations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversations in
                print("🔔 ConversationsViewModel received \(conversations.count) conversations")
                self?.conversations = conversations
                self?.filterConversations()
                print("🔔 Filtered conversations: \(self?.filteredConversations.count ?? 0)")
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

    /// Filter conversations based on search text
    private func filterConversations() {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedQuery.isEmpty {
            filteredConversations = conversations
        } else {
            filteredConversations = conversations.filter { conversation in
                let conversationName = getConversationName(conversation).lowercased()
                let lastMessage = conversation.lastMessage?.lowercased() ?? ""
                let query = trimmedQuery.lowercased()

                return conversationName.contains(query) || lastMessage.contains(query)
            }
        }
    }
}


