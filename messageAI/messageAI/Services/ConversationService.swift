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
    let localStorageService: LocalStorageService  // Internal access for ConversationsViewModel
    private var conversationsListener: ListenerRegistration?
    private var notificationService: NotificationService?
    private var previousConversations: [String: Conversation] = [:]  // Track previous state for change detection
    private var currentUserId: String?

    // MARK: - Initialization

    init(localStorageService: LocalStorageService, notificationService: NotificationService? = nil) {
        self.firestore = FirebaseManager.shared.firestore
        self.localStorageService = localStorageService
        self.notificationService = notificationService
    }

    deinit {
        conversationsListener?.remove()
    }

    /// Set the notification service (for late injection)
    func setNotificationService(_ service: NotificationService) {
        self.notificationService = service
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

        let now = Date()
        let conversation = Conversation(
            id: conversationId,
            participantIds: participantIds,
            participantNames: participantNames,
            participantPhotos: participantPhotos,
            lastMessage: nil,
            lastMessageTimestamp: now,  // Set to creation time so it appears in queries
            lastMessageSenderId: nil,
            type: .oneOnOne,
            groupName: nil,
            createdAt: now,
            createdBy: currentUserId
        )

        // Save to Firestore (source of truth) with explicit Timestamp conversion
        let conversationData: [String: Any] = [
            "id": conversationId,
            "participantIds": participantIds,
            "participantNames": participantNames,
            "participantPhotos": participantPhotos.mapValues { $0 ?? "" },
            "lastMessage": NSNull(),
            "lastMessageTimestamp": Timestamp(date: now),  // Explicit Timestamp
            "lastMessageSenderId": NSNull(),
            "type": conversation.type.rawValue,
            "groupName": NSNull(),
            "createdAt": Timestamp(date: now),  // Explicit Timestamp
            "createdBy": currentUserId
        ]
        
        try await firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .setData(conversationData)

        print("✅ Created conversation: \(conversationId) (listener will cache it)")
        
        // Note: We DON'T save to local storage here
        // The real-time listener will cache it automatically

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

        let now = Date()
        let conversation = Conversation(
            id: conversationId,
            participantIds: participantIds,
            participantNames: participantNames,
            participantPhotos: participantPhotos,
            lastMessage: nil,
            lastMessageTimestamp: now,  // Set to creation time so it appears in queries
            lastMessageSenderId: nil,
            type: .group,
            groupName: trimmedName,
            createdAt: now,
            createdBy: currentUserId
        )

        // Save to Firestore (source of truth) with explicit Timestamp conversion
        let conversationData: [String: Any] = [
            "id": conversationId,
            "participantIds": participantIds,
            "participantNames": participantNames,
            "participantPhotos": participantPhotos.mapValues { $0 ?? "" },
            "lastMessage": NSNull(),
            "lastMessageTimestamp": Timestamp(date: now),  // Explicit Timestamp
            "lastMessageSenderId": NSNull(),
            "type": conversation.type.rawValue,
            "groupName": trimmedName,
            "createdAt": Timestamp(date: now),  // Explicit Timestamp
            "createdBy": currentUserId
        ]
        
        try await firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .setData(conversationData)

        print("✅ Created group conversation: \(conversationId) with \(participantIds.count) participants (listener will cache it)")
        
        // Note: We DON'T save to local storage here
        // The real-time listener will cache it automatically

        return conversationId
    }

    // MARK: - Fetch Conversations

    /// Get a specific conversation by ID
    /// - Parameter id: Conversation ID
    /// - Returns: Conversation object
    func getConversation(id: String) async throws -> Conversation {
        print("🔍 Getting conversation: \(id)")
        
        // Try local storage first
        if let localConv = localStorageService.fetchConversation(id: id),
           let conversation = localConv.toConversation() {
            print("✅ Found conversation in local storage")
            return conversation
        }

        // Fetch from Firestore
        print("📡 Fetching from Firestore...")
        let conversation = try await firestore
            .collection(Constants.Collections.conversations)
            .document(id)
            .getDocument(as: Conversation.self)

        // Save to local storage
        do {
            try localStorageService.saveConversation(conversation)
            print("✅ Cached conversation locally")
        } catch {
            print("⚠️ Failed to cache (non-fatal): \(error)")
        }

        return conversation
    }

    /// Load cached conversations from local storage for instant UI
    /// Real data will come from the real-time listener
    func fetchConversations() async throws {
        guard let currentUserId = FirebaseManager.shared.currentUserId else {
            throw ConversationError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Load from local cache for instant UI
        // The real-time listener will provide the source of truth
        let localConversations = localStorageService.fetchConversations()
        if !localConversations.isEmpty {
            let conversations = convertLocalConversations(localConversations)
            self.conversations = conversations
            print("📱 Loaded \(conversations.count) conversations from local cache")
        } else {
            print("📱 No local cache, waiting for real-time listener...")
        }
        
        // Note: We DON'T fetch from Firestore here to avoid race condition
        // The real-time listener (startListening) is the ONLY source of Firestore data
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
            do {
                try localStorageService.updateConversationLastMessage(
                    conversationId: conversationId,
                    lastMessage: message.text,
                    timestamp: message.timestamp
                )
            } catch {
                print("⚠️ Failed to update local storage (non-fatal): \(error)")
            }

            print("Updated last message for conversation: \(conversationId)")
        } catch {
            print("Failed to update last message: \(error.localizedDescription)")
            throw ConversationError.updateFailed
        }
    }

    // MARK: - Real-Time Listener

    /// Start listening to conversation changes in real-time
    /// This is the ONLY source of Firestore data (no race condition with fetch)
    /// - Parameter userId: Current user ID
    func startListening(userId: String) {
        // Remove existing listener
        conversationsListener?.remove()
        
        // Store current user ID for change detection
        self.currentUserId = userId

        print("🔥 Starting real-time listener for user: \(userId)")
        print("🔍 Query: participantIds arrayContains \(userId), order by lastMessageTimestamp desc")

        // Create new listener - ordered by lastMessageTimestamp for proper sorting
        conversationsListener = firestore
            .collection(Constants.Collections.conversations)
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)  // Changed from createdAt
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Listener error: \(error.localizedDescription)")
                    print("❌ Full error: \(error)")
                    Task { @MainActor in
                        self.errorMessage = "Failed to sync conversations"
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ Snapshot documents are nil")
                    return
                }

                print("📦 Listener received \(documents.count) documents from Firestore")

                let conversations = documents.compactMap { doc -> Conversation? in
                    let conv = try? doc.data(as: Conversation.self)
                    if conv == nil {
                        print("⚠️ Failed to decode conversation: \(doc.documentID)")
                    }
                    return conv
                }

                print("✅ Successfully decoded \(conversations.count) conversations")

                Task { @MainActor in
                    // Update previous state for future change detection (no notifications here)
                    // MessageService handles notifications for individual messages
                    for conversation in conversations {
                        self.previousConversations[conversation.id] = conversation
                    }

                    // Update UI - Firestore is the source of truth
                    self.conversations = conversations
                    print("✅ Real-time update: \(conversations.count) conversations")

                    // Cache to local storage (non-blocking background task)
                    Task { @MainActor in
                        for conversation in conversations {
                            do {
                                try self.localStorageService.saveConversation(conversation)
                            } catch {
                                print("⚠️ Cache failed for \(conversation.id): \(error)")
                            }
                        }
                        print("💾 Cached \(conversations.count) conversations locally")
                    }
                }
            }
    }

    /// Stop listening to conversation changes
    func stopListening() {
        conversationsListener?.remove()
        conversationsListener = nil
        previousConversations.removeAll()
        currentUserId = nil
        print("Stopped listening to conversations")
    }

    // MARK: - Notification Detection
    // NOTE: Notifications are now handled by MessageService to avoid duplicates
    // This method is commented out but kept for reference

    /*
    /// Detect new messages and show notifications
    private func detectNewMessagesAndNotify(_ conversations: [Conversation], userId: String) async {
        print("🔍 detectNewMessagesAndNotify called for \(conversations.count) conversations")
        print("   NotificationService is: \(notificationService == nil ? "nil" : "set")")
        print("   Previous conversations count: \(previousConversations.count)")
        
        guard let notificationService = notificationService else {
            print("⚠️ NotificationService not set - caching state only")
            // First load - just cache the state
            for conversation in conversations {
                previousConversations[conversation.id] = conversation
            }
            return
        }

        // Check each conversation for new messages
        for conversation in conversations {
            print("📋 Checking conversation: \(conversation.id)")
            print("   lastMessage: \(conversation.lastMessage ?? "nil")")
            print("   lastMessageSenderId: \(conversation.lastMessageSenderId ?? "nil")")
            print("   lastMessageTimestamp: \(conversation.lastMessageTimestamp?.description ?? "nil")")
            
            guard let lastMessage = conversation.lastMessage,
                  let lastMessageSenderId = conversation.lastMessageSenderId,
                  lastMessageSenderId != userId else {
                // Skip if no message or message is from current user
                print("   ⏭️ Skipped (no message or from self)")
                continue
            }

            let previousConversation = previousConversations[conversation.id]
            print("   Previous conversation exists: \(previousConversation != nil)")
            
            // Check if this is a new message (timestamp changed or first time seeing this conversation)
            let isNewMessage: Bool
            if let prev = previousConversation,
               let currentTimestamp = conversation.lastMessageTimestamp,
               let prevTimestamp = prev.lastMessageTimestamp {
                isNewMessage = currentTimestamp > prevTimestamp
                print("   Comparing timestamps: current=\(currentTimestamp), prev=\(prevTimestamp)")
                print("   Is new message: \(isNewMessage)")
            } else if let timestamp = conversation.lastMessageTimestamp, previousConversation == nil {
                // First time seeing this conversation - check if message is recent (within last 10 seconds)
                let timeSinceMessage = Date().timeIntervalSince(timestamp)
                isNewMessage = timeSinceMessage < 10
                print("   First time seeing conversation, time since message: \(timeSinceMessage)s")
                print("   Is new message: \(isNewMessage)")
            } else {
                isNewMessage = false
                print("   Is new message: false (no valid timestamps)")
            }

            if isNewMessage {
                print("🔔 New message detected in conversation: \(conversation.id)")
                print("   From: \(lastMessageSenderId)")
                print("   Message: \(lastMessage)")

                // Get sender name
                let senderName = conversation.participantNames[lastMessageSenderId] ?? "Someone"

                // Show notification
                await notificationService.showForegroundNotification(
                    from: senderName,
                    message: lastMessage,
                    conversationId: conversation.id
                )
                print("✅ Notification shown")
            }

            // Update previous state
            previousConversations[conversation.id] = conversation
        }
        
        print("✅ detectNewMessagesAndNotify complete")
    }
    */

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

    /// Convert LocalConversations to Conversations (no network call needed!)
    private func convertLocalConversations(_ localConversations: [LocalConversation]) -> [Conversation] {
        print("🔄 Converting \(localConversations.count) local conversations...")
        
        let conversations = localConversations.compactMap { local -> Conversation? in
            if let conversation = local.toConversation() {
                return conversation
            } else {
                print("⚠️ Failed to convert local conversation \(local.id)")
                // Clean up bad data
                try? localStorageService.deleteConversation(conversationId: local.id)
                return nil
            }
        }
        
        print("✅ Successfully converted \(conversations.count) conversations")
        return conversations
    }
    
    /// Clear all local conversations (useful for debugging or reset)
    func clearLocalConversations() {
        let localConvs = localStorageService.fetchConversations()
        for conv in localConvs {
            try? localStorageService.deleteConversation(conversationId: conv.id)
        }
        print("Cleared \(localConvs.count) local conversations")
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


