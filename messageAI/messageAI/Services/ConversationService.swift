//
//  ConversationService.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// Service for managing conversations
/// Handles creating, fetching, and updating conversations with real-time sync
@MainActor
class ConversationService: ObservableObject {

    // MARK: - Published Properties

    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let firestore: Firestore
    private let localStorageService: LocalStorageService
    private var conversationsListener: ListenerRegistration?

    // MARK: - Initialization

    init(localStorageService: LocalStorageService) {
        self.firestore = FirebaseManager.shared.firestore
        self.localStorageService = localStorageService
    }

    deinit {
        conversationsListener?.remove()
    }

    // MARK: - Create Conversations

    /// Create or get an existing one-on-one conversation
    /// - Parameter participantIds: Array of user IDs (must include current user)
    /// - Returns: Conversation ID
    func createOrGetConversation(participantIds: [String]) async throws -> String {
        guard let currentUserId = FirebaseManager.shared.currentUserId else {
            throw ConversationError.notAuthenticated
        }

        // Validate participants
        guard participantIds.count == 2 else {
            throw ConversationError.invalidParticipantCount
        }

        guard participantIds.contains(currentUserId) else {
            throw ConversationError.currentUserNotInParticipants
        }

        // Check if conversation already exists
        // For one-on-one, search for conversation with same participants
        let existingConversation = try await findExistingConversation(
            participantIds: participantIds,
            type: .oneOnOne
        )

        if let existing = existingConversation {
            print("Found existing conversation: \(existing.id)")
            return existing.id
        }

        // Create new conversation
        let conversationId = UUID().uuidString

        // Get participant details
        let participantNames = try await fetchParticipantNames(participantIds: participantIds)
        let participantPhotos = try await fetchParticipantPhotos(participantIds: participantIds)

        let conversation = Conversation(
            id: conversationId,
            participantIds: participantIds,
            participantNames: participantNames,
            participantPhotos: participantPhotos,
            lastMessage: nil,
            lastMessageTimestamp: nil,
            lastMessageSenderId: nil,
            type: .oneOnOne,
            groupName: nil,
            createdAt: Date(),
            createdBy: currentUserId
        )

        // Save to Firestore
        try firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .setData(from: conversation)

        // Save to local storage
        try localStorageService.saveConversation(conversation)

        print("Created new one-on-one conversation: \(conversationId)")

        return conversationId
    }

    /// Create a new group conversation
    /// - Parameters:
    ///   - participantIds: Array of user IDs (must include current user)
    ///   - groupName: Name of the group
    /// - Returns: Conversation ID
    func createGroupConversation(participantIds: [String], groupName: String) async throws -> String {
        guard let currentUserId = FirebaseManager.shared.currentUserId else {
            throw ConversationError.notAuthenticated
        }

        // Validate participants (minimum 3 for group)
        guard participantIds.count >= 3 else {
            throw ConversationError.invalidParticipantCount
        }

        guard participantIds.contains(currentUserId) else {
            throw ConversationError.currentUserNotInParticipants
        }

        // Validate group name
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw ConversationError.invalidGroupName
        }

        // Create new group conversation
        let conversationId = UUID().uuidString

        // Get participant details
        let participantNames = try await fetchParticipantNames(participantIds: participantIds)
        let participantPhotos = try await fetchParticipantPhotos(participantIds: participantIds)

        let conversation = Conversation(
            id: conversationId,
            participantIds: participantIds,
            participantNames: participantNames,
            participantPhotos: participantPhotos,
            lastMessage: nil,
            lastMessageTimestamp: nil,
            lastMessageSenderId: nil,
            type: .group,
            groupName: trimmedName,
            createdAt: Date(),
            createdBy: currentUserId
        )

        // Save to Firestore
        try firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .setData(from: conversation)

        // Save to local storage
        try localStorageService.saveConversation(conversation)

        print("Created new group conversation: \(conversationId) with \(participantIds.count) participants")

        return conversationId
    }

    // MARK: - Fetch Conversations

    /// Get a specific conversation by ID
    /// - Parameter id: Conversation ID
    /// - Returns: Conversation object
    func getConversation(id: String) async throws -> Conversation {
        // Try local storage first
        if let _ = try? localStorageService.fetchConversation(id: id) {
            // Found in local storage, fetch from Firestore to get full data
            let conversation = try await firestore
                .collection(Constants.Collections.conversations)
                .document(id)
                .getDocument(as: Conversation.self)

            return conversation
        }

        // Fetch from Firestore
        let conversation = try await firestore
            .collection(Constants.Collections.conversations)
            .document(id)
            .getDocument(as: Conversation.self)

        // Save to local storage
        try localStorageService.saveConversation(conversation)

        return conversation
    }

    /// Fetch all conversations for the current user
    func fetchConversations() async throws {
        guard let currentUserId = FirebaseManager.shared.currentUserId else {
            throw ConversationError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Load from local storage first (instant UI)
            let localConversations = try localStorageService.fetchConversations()

            if !localConversations.isEmpty {
                // Convert LocalConversations to Conversations and update UI immediately
                let conversations = try await convertLocalConversations(localConversations)
                self.conversations = conversations
                print("Loaded \(conversations.count) conversations from local storage")
            }

            // Then fetch from Firestore to get updates
            let snapshot = try await firestore
                .collection(Constants.Collections.conversations)
                .whereField("participantIds", arrayContains: currentUserId)
                .order(by: "lastMessageTimestamp", descending: true)
                .getDocuments()

            let firestoreConversations = snapshot.documents.compactMap { doc -> Conversation? in
                try? doc.data(as: Conversation.self)
            }

            // Update local storage
            for conversation in firestoreConversations {
                try localStorageService.saveConversation(conversation)
            }

            // Update published property
            self.conversations = firestoreConversations

            print("Fetched \(firestoreConversations.count) conversations from Firestore")
        } catch {
            errorMessage = "Failed to fetch conversations"
            throw ConversationError.fetchFailed
        }
    }

    // MARK: - Update Conversations

    /// Update the last message in a conversation
    /// - Parameters:
    ///   - conversationId: Conversation ID
    ///   - message: The last message
    func updateLastMessage(conversationId: String, message: Message) async throws {
        let updates: [String: Any] = [
            "lastMessage": message.text,
            "lastMessageTimestamp": Timestamp(date: message.timestamp),
            "lastMessageSenderId": message.senderId
        ]

        do {
            // Update Firestore
            try await firestore
                .collection(Constants.Collections.conversations)
                .document(conversationId)
                .updateData(updates)

            // Update local storage
            try localStorageService.updateConversationLastMessage(
                conversationId: conversationId,
                lastMessage: message.text,
                timestamp: message.timestamp
            )

            print("Updated last message for conversation: \(conversationId)")
        } catch {
            print("Failed to update last message: \(error.localizedDescription)")
            throw ConversationError.updateFailed
        }
    }

    // MARK: - Real-Time Listener

    /// Start listening to conversation changes in real-time
    /// - Parameter userId: Current user ID
    func startListening(userId: String) {
        // Remove existing listener
        conversationsListener?.remove()

        // Create new listener
        conversationsListener = firestore
            .collection(Constants.Collections.conversations)
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error listening to conversations: \(error.localizedDescription)")
                    Task { @MainActor in
                        self.errorMessage = "Failed to sync conversations"
                    }
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let conversations = documents.compactMap { doc -> Conversation? in
                    try? doc.data(as: Conversation.self)
                }

                Task { @MainActor in
                    self.conversations = conversations

                    // Update local storage
                    for conversation in conversations {
                        try? self.localStorageService.saveConversation(conversation)
                    }

                    print("Real-time update: \(conversations.count) conversations")
                }
            }

        print("Started listening to conversations for user: \(userId)")
    }

    /// Stop listening to conversation changes
    func stopListening() {
        conversationsListener?.remove()
        conversationsListener = nil
        print("Stopped listening to conversations")
    }

    // MARK: - Helper Methods

    /// Find existing conversation with same participants
    private func findExistingConversation(
        participantIds: [String],
        type: ConversationType
    ) async throws -> Conversation? {
        guard let currentUserId = FirebaseManager.shared.currentUserId else {
            return nil
        }

        // Query conversations where current user is participant
        let snapshot = try await firestore
            .collection(Constants.Collections.conversations)
            .whereField("participantIds", arrayContains: currentUserId)
            .whereField("type", isEqualTo: type.rawValue)
            .getDocuments()

        // Find conversation with exact same participants
        let conversations = snapshot.documents.compactMap { doc -> Conversation? in
            try? doc.data(as: Conversation.self)
        }

        return conversations.first { conversation in
            Set(conversation.participantIds) == Set(participantIds)
        }
    }

    /// Fetch participant names from Firestore
    private func fetchParticipantNames(participantIds: [String]) async throws -> [String: String] {
        var names: [String: String] = [:]

        for userId in participantIds {
            let userDoc = try await firestore
                .collection(Constants.Collections.users)
                .document(userId)
                .getDocument()

            if let user = try? userDoc.data(as: User.self) {
                names[userId] = user.displayName
            }
        }

        return names
    }

    /// Fetch participant photos from Firestore
    private func fetchParticipantPhotos(participantIds: [String]) async throws -> [String: String?] {
        var photos: [String: String?] = [:]

        for userId in participantIds {
            let userDoc = try await firestore
                .collection(Constants.Collections.users)
                .document(userId)
                .getDocument()

            if let user = try? userDoc.data(as: User.self) {
                photos[userId] = user.photoURL
            }
        }

        return photos
    }

    /// Convert LocalConversations to Conversations by fetching from Firestore
    private func convertLocalConversations(_ localConversations: [LocalConversation]) async throws -> [Conversation] {
        var conversations: [Conversation] = []

        for local in localConversations {
            do {
                let conversation = try await getConversation(id: local.id)
                conversations.append(conversation)
            } catch {
                print("Failed to convert local conversation \(local.id): \(error.localizedDescription)")
            }
        }

        return conversations
    }
}

// MARK: - Error Types

enum ConversationError: LocalizedError {
    case notAuthenticated
    case invalidParticipantCount
    case currentUserNotInParticipants
    case invalidGroupName
    case fetchFailed
    case updateFailed
    case conversationNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to create conversations"
        case .invalidParticipantCount:
            return "Invalid number of participants"
        case .currentUserNotInParticipants:
            return "Current user must be in conversation"
        case .invalidGroupName:
            return "Group name cannot be empty"
        case .fetchFailed:
            return "Failed to fetch conversations"
        case .updateFailed:
            return "Failed to update conversation"
        case .conversationNotFound:
            return "Conversation not found"
        }
    }
}


