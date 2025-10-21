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

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Message Operations

    /// Save a message to local storage
    func saveMessage(_ message: Message, conversationId: String) throws {
        // Check if message already exists
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { $0.id == message.id }
        )
        
        if let existingMessage = try modelContext.fetch(descriptor).first {
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
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { $0.conversationId == conversationId },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch all messages
    func fetchAllMessages() throws -> [LocalMessage] {
        let descriptor = FetchDescriptor<LocalMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Update message status
    func updateMessageStatus(messageId: String, status: MessageStatus) throws {
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { $0.id == messageId }
        )

        guard let message = try modelContext.fetch(descriptor).first else {
            throw LocalStorageError.messageNotFound
        }

        message.status = status.rawValue
        message.isPending = (status == .sending || status == .failed)
        try modelContext.save()
    }

    /// Update message with server ID after sync
    func updateMessageId(localId: String, serverId: String, status: MessageStatus) throws {
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { $0.localId == localId }
        )

        guard let message = try modelContext.fetch(descriptor).first else {
            throw LocalStorageError.messageNotFound
        }

        message.id = serverId
        message.status = status.rawValue
        message.isPending = false
        try modelContext.save()
    }

    /// Delete a message
    func deleteMessage(messageId: String) throws {
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { $0.id == messageId }
        )

        guard let message = try modelContext.fetch(descriptor).first else {
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
        // Check if conversation already exists
        let descriptor = FetchDescriptor<LocalConversation>(
            predicate: #Predicate { $0.id == conversation.id }
        )
        
        if let existingConversation = try modelContext.fetch(descriptor).first {
            // Update existing conversation
            existingConversation.participantIds = conversation.participantIds
            existingConversation.lastMessage = conversation.lastMessage
            existingConversation.lastMessageTimestamp = conversation.lastMessageTimestamp
            existingConversation.type = conversation.type.rawValue
            existingConversation.groupName = conversation.groupName
        } else {
            // Insert new conversation
            let localConversation = LocalConversation(
                id: conversation.id,
                participantIds: conversation.participantIds,
                lastMessage: conversation.lastMessage,
                lastMessageTimestamp: conversation.lastMessageTimestamp,
                type: conversation.type.rawValue,
                groupName: conversation.groupName
            )
            modelContext.insert(localConversation)
        }
        
        try modelContext.save()
    }

    /// Fetch all conversations
    func fetchConversations() throws -> [LocalConversation] {
        let descriptor = FetchDescriptor<LocalConversation>()
        let conversations = try modelContext.fetch(descriptor)
        
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
    }

    /// Fetch a specific conversation
    func fetchConversation(id: String) throws -> LocalConversation? {
        let descriptor = FetchDescriptor<LocalConversation>(
            predicate: #Predicate { $0.id == id }
        )

        return try modelContext.fetch(descriptor).first
    }

    /// Update conversation's last message
    func updateConversationLastMessage(
        conversationId: String,
        lastMessage: String,
        timestamp: Date
    ) throws {
        let descriptor = FetchDescriptor<LocalConversation>(
            predicate: #Predicate { $0.id == conversationId }
        )

        guard let conversation = try modelContext.fetch(descriptor).first else {
            throw LocalStorageError.conversationNotFound
        }

        conversation.lastMessage = lastMessage
        conversation.lastMessageTimestamp = timestamp
        try modelContext.save()
    }

    /// Delete a conversation
    func deleteConversation(conversationId: String) throws {
        let descriptor = FetchDescriptor<LocalConversation>(
            predicate: #Predicate { $0.id == conversationId }
        )

        guard let conversation = try modelContext.fetch(descriptor).first else {
            throw LocalStorageError.conversationNotFound
        }

        modelContext.delete(conversation)
        try modelContext.save()
    }

    // MARK: - Pending Messages

    /// Fetch all pending messages (failed or sending)
    func fetchPendingMessages() throws -> [LocalMessage] {
        let descriptor = FetchDescriptor<LocalMessage>(
            predicate: #Predicate { $0.isPending == true },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        return try modelContext.fetch(descriptor)
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
