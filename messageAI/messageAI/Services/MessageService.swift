//
//  MessageService.swift
//  messageAI
//
//  Created by MessageAI on 10/21/25.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class MessageService: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var typingUsers: [String] = []

    // MARK: - Private Properties
    private let firestore = FirebaseManager.shared.firestore
    private let localStorageService: LocalStorageService
    private var listener: ListenerRegistration?
    private var typingListener: ListenerRegistration?
    private var offlineQueue: [Message] = []
    private var isOnline = true
    private var currentConversationId: String?
    private var notificationService: NotificationService?

    // MARK: - Initialization
    init(localStorageService: LocalStorageService, notificationService: NotificationService? = nil) {
        self.localStorageService = localStorageService
        self.notificationService = notificationService
        observeNetworkStatus()
    }

    /// Set the notification service (for late injection)
    func setNotificationService(_ service: NotificationService) {
        self.notificationService = service
    }

    nonisolated deinit {
        // Capture listeners to avoid capturing self in Task
        let messageListener = listener
        let typingListenerRef = typingListener

        Task { @MainActor in
            messageListener?.remove()
            typingListenerRef?.remove()
        }
    }

    // MARK: - Helper Properties

    private var currentUserId: String {
        FirebaseManager.shared.currentUserId ?? ""
    }

    // MARK: - Network Monitoring
    private func observeNetworkStatus() {
        // Simple network monitoring
        // In production, use NWPathMonitor or similar
        isOnline = true
    }

    // MARK: - Local-First Message Sending

    /// Send a message with local-first approach
    func sendMessage(
        conversationId: String,
        text: String,
        senderName: String,
        senderPhotoURL: String? = nil
    ) async throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MessageError.emptyMessage
        }

        let localId = UUID().uuidString
        var message = createMessage(
            localId: localId,
            text: text,
            senderName: senderName,
            senderPhotoURL: senderPhotoURL
        )

        try await saveMessageLocally(message, conversationId: conversationId)
        messages.append(message)

        if isOnline {
            try await syncMessageToFirestore(
                &message,
                conversationId: conversationId,
                localId: localId
            )
        } else {
            offlineQueue.append(message)
        }
    }

    private func createMessage(
        localId: String,
        text: String,
        senderName: String,
        senderPhotoURL: String?
    ) -> Message {
        Message(
            id: localId,
            senderId: currentUserId,
            senderName: senderName,
            senderPhotoURL: senderPhotoURL,
            text: text,
            timestamp: Date(),
            status: .sending,
            readBy: [:],
            deliveredTo: [:],
            localId: localId
        )
    }

    private func saveMessageLocally(_ message: Message, conversationId: String) async throws {
        do {
            try await localStorageService.saveMessage(message, conversationId: conversationId)
        } catch {
            print("Failed to save message locally: \(error)")
            // Non-fatal - Firestore is source of truth
        }
    }

    private func syncMessageToFirestore(
        _ message: inout Message,
        conversationId: String,
        localId: String
    ) async throws {
        do {
            print("📤 Syncing message to Firestore...")
            print("   - conversationId: \(conversationId)")
            print("   - text: \(message.text)")

            let docRef = try await firestore
                .collection(Constants.Collections.conversations)
                .document(conversationId)
                .collection(Constants.Collections.messages)
                .addDocument(data: message.toDictionary())

            print("✅ Message saved to Firestore: \(docRef.documentID)")

            // Create updated message with server ID
            let updatedMessage = Message(
                id: docRef.documentID,
                senderId: message.senderId,
                senderName: message.senderName,
                senderPhotoURL: message.senderPhotoURL,
                text: message.text,
                timestamp: message.timestamp,
                status: .sent,
                readBy: message.readBy,
                deliveredTo: message.deliveredTo,
                localId: message.localId
            )

            message = updatedMessage

            try await localStorageService.updateMessageId(
                localId: localId,
                serverId: docRef.documentID,
                status: .sent
            )

            if let index = messages.firstIndex(where: { $0.localId == localId }) {
                messages[index] = updatedMessage
            }

            print("📊 Updating conversation last message...")
            try await updateConversationLastMessage(
                conversationId: conversationId,
                message: updatedMessage
            )
            print("✅ Message send complete!")
        } catch {
            print("❌ Firestore sync failed: \(error)")
            try await handleSendFailure(message, localId: localId, error: error)
        }
    }

    private func handleSendFailure(_ message: Message, localId: String, error: Error) async throws {
        var failedMessage = message
        failedMessage.status = .failed

        try await localStorageService.updateMessageStatus(
            messageId: localId,
            status: .failed
        )

        if let index = messages.firstIndex(where: { $0.localId == localId }) {
            messages[index].status = .failed
        }

        offlineQueue.append(failedMessage)
        print("Failed to send message: \(error)")
        throw MessageError.sendFailed
    }

    // MARK: - Fetch Messages

    func fetchLocalMessages(conversationId: String) async {
        do {
            let localMessages = try localStorageService.fetchMessages(conversationId: conversationId)
            messages = convertLocalMessages(localMessages)
            print("📱 Loaded \(messages.count) messages from local cache")
        } catch {
            print("❌ Failed to fetch local messages: \(error)")
            messages = []
        }

        // Note: Local is just a cache for instant UI
        // Real-time listener is the source of truth
    }

    private func convertLocalMessages(_ localMessages: [LocalMessage]) -> [Message] {
        localMessages.map { localMsg in
            Message(
                id: localMsg.id,
                senderId: localMsg.senderId,
                senderName: localMsg.senderName,
                senderPhotoURL: nil,
                text: localMsg.text,
                timestamp: localMsg.timestamp,
                status: MessageStatus(rawValue: localMsg.status) ?? .sent,
                readBy: [:],
                deliveredTo: [:],
                localId: localMsg.localId
            )
        }
    }

    // MARK: - Real-Time Listener

    func startListening(conversationId: String) {
        stopListening()

        // Track the current conversation
        self.currentConversationId = conversationId

        print("🔥 Starting messages listener for: \(conversationId)")
        print("🔍 Path: conversations/\(conversationId)/messages")
        print("🔍 Current user: \(currentUserId)")

        listener = firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .collection(Constants.Collections.messages)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Messages listener error: \(error)")
                    Task { @MainActor in
                        self.errorMessage = "Failed to sync messages"
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ Snapshot documents are nil")
                    return
                }

                print("📦 Listener snapshot: \(documents.count) raw documents")
                for (idx, doc) in documents.enumerated() {
                    print("   [\(idx)] ID: \(doc.documentID)")
                }

                Task { @MainActor in
                    let fetchedMessages = documents.compactMap { doc -> Message? in
                        let data = doc.data()

                        // Manually decode since Firestore doc.data(as:) doesn't include doc.id
                        guard let senderId = data["senderId"] as? String,
                              let senderName = data["senderName"] as? String,
                              let text = data["text"] as? String,
                              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                              let statusRaw = data["status"] as? String,
                              let status = MessageStatus(rawValue: statusRaw) else {
                            print("⚠️ Missing required fields in: \(doc.documentID)")
                            return nil
                        }

                        let readBy = (data["readBy"] as? [String: Timestamp])?.mapValues { $0.dateValue() } ?? [:]
                        let deliveredTo = (data["deliveredTo"] as? [String: Timestamp])?.mapValues { $0.dateValue() } ?? [:]

                        return Message(
                            id: doc.documentID,  // Use Firestore document ID
                            senderId: senderId,
                            senderName: senderName,
                            senderPhotoURL: data["senderPhotoURL"] as? String,
                            text: text,
                            timestamp: timestamp,
                            status: status,
                            readBy: readBy,
                            deliveredTo: deliveredTo,
                            localId: data["localId"] as? String
                        )
                    }
                    print("✅ Listener decoded \(fetchedMessages.count) messages successfully")
                    await self.mergeMessages(fetchedMessages, conversationId: conversationId)
                    await self.autoMarkAsDelivered(conversationId: conversationId)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        currentConversationId = nil
    }

    // MARK: - Message Merging

    private func mergeMessages(_ remoteMessages: [Message], conversationId: String) async {
        print("🔄 Merging: local=\(messages.count), remote=\(remoteMessages.count)")

        // Detect new messages for notifications (only from others)
        let existingMessageIds = Set(messages.map { $0.id })
        let newMessages = remoteMessages.filter { message in
            !existingMessageIds.contains(message.id) &&
            message.senderId != currentUserId
        }

        // Firestore is the source of truth - use remote data directly
        messages = remoteMessages.sorted { $0.timestamp < $1.timestamp }

        print("✅ Merged result: \(messages.count) messages")

        // Show notifications for new messages (only when not in this conversation)
        if !newMessages.isEmpty {
            await showNotificationsForNewMessages(newMessages, conversationId: conversationId)
        }

        // Cache to local storage (async, non-blocking)
        Task { @MainActor in
            for message in remoteMessages {
                do {
                    try await localStorageService.saveMessage(message, conversationId: conversationId)
                } catch {
                    print("⚠️ Failed to cache message: \(error)")
                }
            }
            print("💾 Cached \(remoteMessages.count) messages locally")
        }
    }

    /// Show foreground notifications for new messages
    private func showNotificationsForNewMessages(_ newMessages: [Message], conversationId: String) async {
        guard let notificationService = notificationService else {
            print("⚠️ NotificationService not available")
            return
        }

        // Only show notification if NOT currently viewing this conversation
        // Check if this is the active conversation being viewed
        let isCurrentConversation = currentConversationId == conversationId

        if isCurrentConversation {
            print("📱 User is viewing conversation \(conversationId) - skipping notification")
            return
        }

        // Show notifications for messages from other conversations
        for message in newMessages {
            print("🔔 Showing notification for message from \(message.senderName)")
            await notificationService.showForegroundNotification(
                from: message.senderName,
                message: message.text,
                conversationId: conversationId
            )
        }
    }

    // MARK: - Message Status Updates

    private func autoMarkAsDelivered(conversationId: String) async {
        let undeliveredMessages = messages.filter { message in
            message.senderId != currentUserId &&
            (message.deliveredTo[currentUserId] == nil)
        }

        guard !undeliveredMessages.isEmpty else { return }

        for message in undeliveredMessages {
            try? await markAsDelivered(
                conversationId: conversationId,
                messageId: message.id
            )
        }
    }

    func markAsDelivered(conversationId: String, messageId: String) async throws {
        let timestamp = Date()

        try await firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .collection(Constants.Collections.messages)
            .document(messageId)
            .updateData([
                "deliveredTo.\(currentUserId)": timestamp,
                "status": MessageStatus.delivered.rawValue
            ])

        try await localStorageService.updateMessageStatus(
            messageId: messageId,
            status: .delivered
        )

        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index].deliveredTo[currentUserId] = timestamp
            messages[index].status = .delivered
        }
    }

    func markAsRead(conversationId: String, messageIds: [String]) async throws {
        let timestamp = Date()

        for messageId in messageIds {
            try await firestore
                .collection(Constants.Collections.conversations)
                .document(conversationId)
                .collection(Constants.Collections.messages)
                .document(messageId)
                .updateData([
                    "readBy.\(currentUserId)": timestamp,
                    "status": MessageStatus.read.rawValue
                ])

            try await localStorageService.updateMessageStatus(
                messageId: messageId,
                status: .read
            )

            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                messages[index].readBy[currentUserId] = timestamp
                messages[index].status = .read
            }
        }
    }

    // MARK: - Offline Queue Management

    func processOfflineQueue() async {
        guard !offlineQueue.isEmpty else { return }
        print("Processing \(offlineQueue.count) offline messages...")
        offlineQueue.removeAll()
    }

    // MARK: - Typing Indicators

    func setTyping(conversationId: String, isTyping: Bool) async throws {
        if isTyping {
            try await firestore
                .collection(Constants.Collections.conversations)
                .document(conversationId)
                .collection("typing")
                .document(currentUserId)
                .setData([
                    "userId": currentUserId,
                    "timestamp": FieldValue.serverTimestamp()
                ])
        } else {
            try await firestore
                .collection(Constants.Collections.conversations)
                .document(conversationId)
                .collection("typing")
                .document(currentUserId)
                .delete()
        }
    }

    func startListeningForTyping(conversationId: String) {
        stopListeningForTyping()

        typingListener = firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .collection("typing")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error listening to typing indicators: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                Task { @MainActor in
                    let typingUserIds = documents
                        .compactMap { $0.data()["userId"] as? String }
                        .filter { $0 != self.currentUserId }
                    self.typingUsers = typingUserIds
                }
            }
    }

    func stopListeningForTyping() {
        typingListener?.remove()
        typingListener = nil
    }

    // MARK: - Helper Methods

    private func updateConversationLastMessage(
        conversationId: String,
        message: Message
    ) async throws {
        try await firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .updateData([
                "lastMessage": message.text,
                "lastMessageTimestamp": Timestamp(date: message.timestamp),
                "lastMessageSenderId": message.senderId
            ])
        
        print("✅ Updated conversation lastMessage: \(message.text)")
        print("   Timestamp: \(message.timestamp)")
        print("   SenderId: \(message.senderId)")
    }
}

// MARK: - Message Extension

extension Message {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "senderId": senderId,
            "senderName": senderName,
            "text": text,
            "timestamp": timestamp,
            "status": status.rawValue,
            "readBy": readBy.mapValues { $0 },
            "deliveredTo": deliveredTo.mapValues { $0 }
        ]

        if let senderPhotoURL = senderPhotoURL {
            dict["senderPhotoURL"] = senderPhotoURL
        }

        if let localId = localId {
            dict["localId"] = localId
        }

        return dict
    }
}

// MARK: - Message Errors

enum MessageError: LocalizedError {
    case emptyMessage
    case localStorageFailed
    case sendFailed
    case notFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            return "Message cannot be empty"
        case .localStorageFailed:
            return "Failed to save message locally"
        case .sendFailed:
            return "Failed to send message"
        case .notFound:
            return "Message not found"
        case .unauthorized:
            return "You are not authorized to perform this action"
        }
    }
}
