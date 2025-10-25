//
//  LocalStorageService.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import SwiftData
import Combine

/// Service for managing local storage using SwiftData
/// Provides offline persistence for messages and conversations
@MainActor
class LocalStorageService: ObservableObject {
    private let modelContext: ModelContext

    /// Initialize with existing ModelContext
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Initialize with default ModelContainer
    convenience init() {
        let schema = Schema([
            LocalMessage.self,
            LocalConversation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.init(modelContext: container.mainContext)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // MARK: - Message Operations

    /// Save a message to local storage
    func saveMessage(_ message: Message, conversationId: String) throws {
        // Fetch all and filter in Swift (avoids predicate crashes)
        let descriptor = FetchDescriptor<LocalMessage>()
        let allMessages = try modelContext.fetch(descriptor)

        if let existingMessage = allMessages.first(where: { $0.id == message.id }) {
            // Update existing message
            existingMessage.conversationId = conversationId
            existingMessage.senderId = message.senderId
            existingMessage.senderName = message.senderName
            existingMessage.text = message.text
            existingMessage.timestamp = message.timestamp
            existingMessage.status = message.status.rawValue
            existingMessage.isPending = message.status == .sending || message.status == .failed
            existingMessage.localId = message.localId
        } else {
            // Insert new message
            let localMessage = LocalMessage(
                id: message.id,
                conversationId: conversationId,
                senderId: message.senderId,
                senderName: message.senderName,
                text: message.text,
                timestamp: message.timestamp,
                status: message.status.rawValue,
                isPending: message.status == .sending || message.status == .failed,
                localId: message.localId
            )
            modelContext.insert(localMessage)
        }

        try modelContext.save()
    }

    /// Fetch messages for a specific conversation
    func fetchMessages(conversationId: String) throws -> [LocalMessage] {
        print("🔍 Fetching messages for conversation: \(conversationId)")

        do {
            // Fetch ALL messages without predicate (avoids SwiftData crashes)
            let descriptor = FetchDescriptor<LocalMessage>()
            let allMessages = try modelContext.fetch(descriptor)
            print("✅ Fetched \(allMessages.count) total messages from store")

            // Filter and sort in Swift
            let filteredMessages = allMessages
                .filter { $0.conversationId == conversationId }
                .sorted { $0.timestamp < $1.timestamp }

            print("✅ Found \(filteredMessages.count) messages for conversation")
            return filteredMessages
        } catch {
            print("❌ Error fetching messages: \(error)")
            // Try to recover by clearing data
            try? clearAllData()
            return []
        }
    }

    /// Fetch all messages
    func fetchAllMessages() throws -> [LocalMessage] {
        do {
            let descriptor = FetchDescriptor<LocalMessage>()
            let messages = try modelContext.fetch(descriptor)
            // Sort in Swift
            return messages.sorted { $0.timestamp > $1.timestamp }
        } catch {
            print("❌ Error fetching all messages: \(error)")
            try? clearAllData()
            return []
        }
    }

    /// Update message status
    func updateMessageStatus(messageId: String, status: MessageStatus) throws {
        do {
            // Fetch all and filter in Swift
            let descriptor = FetchDescriptor<LocalMessage>()
            let allMessages = try modelContext.fetch(descriptor)

            guard let message = allMessages.first(where: { $0.id == messageId }) else {
                throw LocalStorageError.messageNotFound
            }

            message.status = status.rawValue
            message.isPending = (status == .sending || status == .failed)
            try modelContext.save()
        } catch {
            print("❌ Error updating message status: \(error)")
            throw error
        }
    }

    /// Update message with server ID after sync
    func updateMessageId(localId: String, serverId: String, status: MessageStatus) throws {
        // Fetch all and filter in Swift
        let descriptor = FetchDescriptor<LocalMessage>()
        let allMessages = try modelContext.fetch(descriptor)

        guard let message = allMessages.first(where: { $0.localId == localId }) else {
            throw LocalStorageError.messageNotFound
        }

        message.id = serverId
        message.status = status.rawValue
        message.isPending = false
        try modelContext.save()
    }

    /// Delete a message
    func deleteMessage(messageId: String) throws {
        // Fetch all and filter in Swift
        let descriptor = FetchDescriptor<LocalMessage>()
        let allMessages = try modelContext.fetch(descriptor)

        guard let message = allMessages.first(where: { $0.id == messageId }) else {
            throw LocalStorageError.messageNotFound
        }

        modelContext.delete(message)
        try modelContext.save()
    }

    /// Delete all messages for a conversation
    func deleteMessages(conversationId: String) throws {
        let messages = try fetchMessages(conversationId: conversationId)

        for message in messages {
            modelContext.delete(message)
        }

        try modelContext.save()
    }

    // MARK: - Conversation Operations

    /// Save a conversation to local storage
    func saveConversation(_ conversation: Conversation) throws {
        print("💾 Saving conversation: \(conversation.id)")

        guard let localConversation = LocalConversation.from(conversation) else {
            print("❌ Failed to convert Conversation to LocalConversation")
            throw LocalStorageError.saveFailed
        }

        do {
            // Fetch all to avoid predicate issues
            let descriptor = FetchDescriptor<LocalConversation>()
            let allConversations = try modelContext.fetch(descriptor)

            // Check if already exists
            if let existing = allConversations.first(where: { $0.id == conversation.id }) {
                print("📝 Updating existing conversation")
                // Delete old and insert new (safer than updating all fields)
                modelContext.delete(existing)
            } else {
                print("➕ Inserting new conversation")
            }

            // Insert the new/updated conversation
            modelContext.insert(localConversation)
            try modelContext.save()
            print("✅ Successfully saved conversation")
        } catch {
            print("❌ Error saving conversation: \(error)")
            throw error
        }
    }

    /// Fetch all conversations
    func fetchConversations(userId: String? = nil) -> [LocalConversation] {
        if let userId = userId {
            print("🔍 Fetching conversations for user \(userId) from local storage...")
        } else {
            print("🔍 Fetching all conversations from local storage...")
        }

        do {
            let descriptor = FetchDescriptor<LocalConversation>()
            let allConversations = try modelContext.fetch(descriptor)

            // Filter by userId if provided
            let conversations: [LocalConversation]
            if let userId = userId {
                conversations = allConversations.filter { conversation in
                    // Decode participantIdsJSON to check if user is participant
                    guard let participantIdsData = conversation.participantIdsJSON.data(using: .utf8),
                          let participantIds = try? JSONDecoder().decode([String].self, from: participantIdsData) else {
                        return false
                    }
                    return participantIds.contains(userId)
                }
                print("✅ Successfully fetched \(conversations.count) conversations for user (out of \(allConversations.count) total)")
            } else {
                conversations = allConversations
                print("✅ Successfully fetched \(conversations.count) conversations")
            }

            // Sort in Swift to handle optional lastMessageTimestamp
            return conversations.sorted { conv1, conv2 in
                // Put conversations with timestamps first, sorted newest to oldest
                switch (conv1.lastMessageTimestamp, conv2.lastMessageTimestamp) {
                case (.some(let date1), .some(let date2)):
                    return date1 > date2
                case (.some, .none):
                    return true  // Conversations with messages come first
                case (.none, .some):
                    return false
                case (.none, .none):
                    return false // Both nil, maintain order
                }
            }
        } catch {
            print("❌ FATAL ERROR fetching conversations: \(error)")
            print("🆘 This indicates SwiftData store corruption")
            print("🗑️  Attempting emergency data clear...")

            // Emergency recovery
            do {
                try clearAllData()
                print("✅ Successfully cleared all corrupted data")
            } catch let clearError {
                print("❌ Failed to clear data: \(clearError)")
            }

            return []
        }
    }

    /// Fetch a specific conversation
    func fetchConversation(id: String) -> LocalConversation? {
        print("🔍 Attempting to fetch conversation: \(id)")

        do {
            // Fetch ALL conversations first (safer than predicate on corrupted data)
            print("📦 Fetching all conversations...")
            let allDescriptor = FetchDescriptor<LocalConversation>()
            let allConversations = try modelContext.fetch(allDescriptor)
            print("✅ Fetched \(allConversations.count) total conversations")

            // Filter in Swift (avoids SwiftData predicate crashes)
            let result = allConversations.first { $0.id == id }
            print(result != nil ? "✅ Found conversation \(id)" : "❌ Conversation \(id) not found")
            return result
        } catch {
            print("❌ Fatal error fetching conversations: \(error)")
            print("🗑️  Clearing ALL local data to recover...")

            // Emergency recovery: clear all data
            do {
                try clearAllData()
                print("✅ Successfully cleared all corrupted data")
            } catch {
                print("❌ Failed to clear data: \(error)")
            }
            return nil
        }
    }

    /// Update conversation's last message
    func updateConversationLastMessage(
        conversationId: String,
        lastMessage: String,
        timestamp: Date
    ) throws {
        // Fetch all and filter in Swift
        let descriptor = FetchDescriptor<LocalConversation>()
        let allConversations = try modelContext.fetch(descriptor)

        guard let conversation = allConversations.first(where: { $0.id == conversationId }) else {
            throw LocalStorageError.conversationNotFound
        }

        conversation.lastMessage = lastMessage
        conversation.lastMessageTimestamp = timestamp
        try modelContext.save()
    }

    /// Delete a conversation
    func deleteConversation(conversationId: String) throws {
        // Fetch all and filter in Swift
        let descriptor = FetchDescriptor<LocalConversation>()
        let allConversations = try modelContext.fetch(descriptor)

        guard let conversation = allConversations.first(where: { $0.id == conversationId }) else {
            throw LocalStorageError.conversationNotFound
        }

        modelContext.delete(conversation)
        try modelContext.save()
    }

    // MARK: - Pending Messages

    /// Fetch all pending messages (failed or sending)
    func fetchPendingMessages() throws -> [LocalMessage] {
        do {
            // Fetch all and filter in Swift
            let descriptor = FetchDescriptor<LocalMessage>()
            let allMessages = try modelContext.fetch(descriptor)

            // Filter and sort in Swift
            return allMessages
                .filter { $0.isPending == true }
                .sorted { $0.timestamp < $1.timestamp }
        } catch {
            print("❌ Error fetching pending messages: \(error)")
            try? clearAllData()
            return []
        }
    }

    // MARK: - Cleanup

    /// Clear all local data
    func clearAllData() throws {
        try modelContext.delete(model: LocalMessage.self)
        try modelContext.delete(model: LocalConversation.self)
        try modelContext.save()
    }
}

// MARK: - Error Types

enum LocalStorageError: LocalizedError {
    case messageNotFound
    case conversationNotFound
    case saveFailed
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .messageNotFound:
            return "Message not found in local storage"
        case .conversationNotFound:
            return "Conversation not found in local storage"
        case .saveFailed:
            return "Failed to save data to local storage"
        case .fetchFailed:
            return "Failed to fetch data from local storage"
        }
    }
}
