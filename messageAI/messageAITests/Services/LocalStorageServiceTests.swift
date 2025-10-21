//
//  LocalStorageServiceTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
import SwiftData
@testable import messageAI

@MainActor
final class LocalStorageServiceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: LocalStorageService!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory container for testing
        let schema = Schema([
            LocalMessage.self,
            LocalConversation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        service = LocalStorageService(modelContext: modelContext)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        modelContainer = nil
        modelContext = nil
        service = nil
    }

    // MARK: - Message Tests

    func testSaveMessage() throws {
        // Given
        let message = createTestMessage()
        let conversationId = "conv-123"

        // When
        try service.saveMessage(message, conversationId: conversationId)

        // Then
        let fetchedMessages = try service.fetchMessages(conversationId: conversationId)
        XCTAssertEqual(fetchedMessages.count, 1)
        XCTAssertEqual(fetchedMessages.first?.id, message.id)
        XCTAssertEqual(fetchedMessages.first?.text, message.text)
        XCTAssertEqual(fetchedMessages.first?.senderId, message.senderId)
    }

    func testFetchMessagesForConversation() throws {
        // Given
        let conversationId = "conv-123"
        let message1 = createTestMessage(id: "msg-1", text: "First")
        let message2 = createTestMessage(id: "msg-2", text: "Second")
        let message3 = createTestMessage(id: "msg-3", text: "Third")

        // When
        try service.saveMessage(message1, conversationId: conversationId)
        try service.saveMessage(message2, conversationId: conversationId)
        try service.saveMessage(message3, conversationId: "other-conv")

        // Then
        let fetchedMessages = try service.fetchMessages(conversationId: conversationId)
        XCTAssertEqual(fetchedMessages.count, 2)
        XCTAssertTrue(fetchedMessages.contains { $0.id == "msg-1" })
        XCTAssertTrue(fetchedMessages.contains { $0.id == "msg-2" })
        XCTAssertFalse(fetchedMessages.contains { $0.id == "msg-3" })
    }

    func testFetchAllMessages() throws {
        // Given
        let message1 = createTestMessage(id: "msg-1")
        let message2 = createTestMessage(id: "msg-2")
        let message3 = createTestMessage(id: "msg-3")

        // When
        try service.saveMessage(message1, conversationId: "conv-1")
        try service.saveMessage(message2, conversationId: "conv-2")
        try service.saveMessage(message3, conversationId: "conv-3")

        // Then
        let allMessages = try service.fetchAllMessages()
        XCTAssertEqual(allMessages.count, 3)
    }

    func testUpdateMessageStatus() throws {
        // Given
        let message = createTestMessage(status: .sending)
        try service.saveMessage(message, conversationId: "conv-123")

        // When
        try service.updateMessageStatus(messageId: message.id, status: .sent)

        // Then
        let fetchedMessages = try service.fetchMessages(conversationId: "conv-123")
        XCTAssertEqual(fetchedMessages.first?.status, MessageStatus.sent.rawValue)
        XCTAssertFalse(fetchedMessages.first?.isPending ?? true)
    }

    func testUpdateMessageStatusToPending() throws {
        // Given
        let message = createTestMessage(status: .sent)
        try service.saveMessage(message, conversationId: "conv-123")

        // When
        try service.updateMessageStatus(messageId: message.id, status: .failed)

        // Then
        let fetchedMessages = try service.fetchMessages(conversationId: "conv-123")
        XCTAssertEqual(fetchedMessages.first?.status, MessageStatus.failed.rawValue)
        XCTAssertTrue(fetchedMessages.first?.isPending ?? false)
    }

    func testUpdateMessageId() throws {
        // Given
        let localId = "local-123"
        let message = createTestMessage(id: localId, status: .sending, localId: localId)
        try service.saveMessage(message, conversationId: "conv-123")

        // When
        let serverId = "server-456"
        try service.updateMessageId(localId: localId, serverId: serverId, status: .sent)

        // Then
        let fetchedMessages = try service.fetchMessages(conversationId: "conv-123")
        XCTAssertEqual(fetchedMessages.first?.id, serverId)
        XCTAssertEqual(fetchedMessages.first?.localId, localId)
        XCTAssertEqual(fetchedMessages.first?.status, MessageStatus.sent.rawValue)
        XCTAssertFalse(fetchedMessages.first?.isPending ?? true)
    }

    func testDeleteMessage() throws {
        // Given
        let message = createTestMessage()
        try service.saveMessage(message, conversationId: "conv-123")

        // When
        try service.deleteMessage(messageId: message.id)

        // Then
        let fetchedMessages = try service.fetchMessages(conversationId: "conv-123")
        XCTAssertEqual(fetchedMessages.count, 0)
    }

    func testDeleteMessagesForConversation() throws {
        // Given
        let conversationId = "conv-123"
        let message1 = createTestMessage(id: "msg-1")
        let message2 = createTestMessage(id: "msg-2")
        let message3 = createTestMessage(id: "msg-3")

        try service.saveMessage(message1, conversationId: conversationId)
        try service.saveMessage(message2, conversationId: conversationId)
        try service.saveMessage(message3, conversationId: "other-conv")

        // When
        try service.deleteMessages(conversationId: conversationId)

        // Then
        let fetchedMessages = try service.fetchMessages(conversationId: conversationId)
        XCTAssertEqual(fetchedMessages.count, 0)

        let otherMessages = try service.fetchMessages(conversationId: "other-conv")
        XCTAssertEqual(otherMessages.count, 1)
    }

    func testFetchPendingMessages() throws {
        // Given
        let sendingMessage = createTestMessage(id: "msg-1", status: .sending)
        let failedMessage = createTestMessage(id: "msg-2", status: .failed)
        let sentMessage = createTestMessage(id: "msg-3", status: .sent)

        try service.saveMessage(sendingMessage, conversationId: "conv-123")
        try service.saveMessage(failedMessage, conversationId: "conv-123")
        try service.saveMessage(sentMessage, conversationId: "conv-123")

        // When
        let pendingMessages = try service.fetchPendingMessages()

        // Then
        XCTAssertEqual(pendingMessages.count, 2)
        XCTAssertTrue(pendingMessages.contains { $0.id == "msg-1" })
        XCTAssertTrue(pendingMessages.contains { $0.id == "msg-2" })
        XCTAssertFalse(pendingMessages.contains { $0.id == "msg-3" })
    }

    // MARK: - Conversation Tests

    func testSaveConversation() throws {
        // Given
        let conversation = createTestConversation()

        // When
        try service.saveConversation(conversation)

        // Then
        let fetchedConversations = try service.fetchConversations()
        XCTAssertEqual(fetchedConversations.count, 1)
        XCTAssertEqual(fetchedConversations.first?.id, conversation.id)
        XCTAssertEqual(fetchedConversations.first?.participantIds, conversation.participantIds)
    }

    func testFetchConversations() throws {
        // Given
        let conv1 = createTestConversation(id: "conv-1", timestamp: Date().addingTimeInterval(-100))
        let conv2 = createTestConversation(id: "conv-2", timestamp: Date().addingTimeInterval(-50))
        let conv3 = createTestConversation(id: "conv-3", timestamp: Date())

        // When
        try service.saveConversation(conv1)
        try service.saveConversation(conv2)
        try service.saveConversation(conv3)

        // Then
        let conversations = try service.fetchConversations()
        XCTAssertEqual(conversations.count, 3)
        // Should be sorted by timestamp descending (newest first)
        XCTAssertEqual(conversations[0].id, "conv-3")
        XCTAssertEqual(conversations[1].id, "conv-2")
        XCTAssertEqual(conversations[2].id, "conv-1")
    }

    func testFetchConversationById() throws {
        // Given
        let conversation = createTestConversation(id: "conv-123")
        try service.saveConversation(conversation)

        // When
        let fetchedConversation = try service.fetchConversation(id: "conv-123")

        // Then
        XCTAssertNotNil(fetchedConversation)
        XCTAssertEqual(fetchedConversation?.id, "conv-123")
    }

    func testFetchNonExistentConversation() throws {
        // When
        let fetchedConversation = try service.fetchConversation(id: "non-existent")

        // Then
        XCTAssertNil(fetchedConversation)
    }

    func testUpdateConversationLastMessage() throws {
        // Given
        let conversation = createTestConversation(lastMessage: "Old message")
        try service.saveConversation(conversation)

        // When
        let newMessage = "New message"
        let newTimestamp = Date()
        try service.updateConversationLastMessage(
            conversationId: conversation.id,
            lastMessage: newMessage,
            timestamp: newTimestamp
        )

        // Then
        let fetchedConversation = try service.fetchConversation(id: conversation.id)
        XCTAssertEqual(fetchedConversation?.lastMessage, newMessage)
        XCTAssertEqual(fetchedConversation?.lastMessageTimestamp, newTimestamp)
    }

    func testDeleteConversation() throws {
        // Given
        let conversation = createTestConversation()
        try service.saveConversation(conversation)

        // When
        try service.deleteConversation(conversationId: conversation.id)

        // Then
        let fetchedConversations = try service.fetchConversations()
        XCTAssertEqual(fetchedConversations.count, 0)
    }

    func testClearAllData() throws {
        // Given
        let message1 = createTestMessage(id: "msg-1")
        let message2 = createTestMessage(id: "msg-2")
        let conv1 = createTestConversation(id: "conv-1")
        let conv2 = createTestConversation(id: "conv-2")

        try service.saveMessage(message1, conversationId: "conv-1")
        try service.saveMessage(message2, conversationId: "conv-2")
        try service.saveConversation(conv1)
        try service.saveConversation(conv2)

        // When
        try service.clearAllData()

        // Then
        let messages = try service.fetchAllMessages()
        let conversations = try service.fetchConversations()
        XCTAssertEqual(messages.count, 0)
        XCTAssertEqual(conversations.count, 0)
    }

    // MARK: - Error Tests

    func testUpdateNonExistentMessageStatus() {
        // When/Then
        XCTAssertThrowsError(try service.updateMessageStatus(messageId: "non-existent", status: .sent)) { error in
            XCTAssertTrue(error is LocalStorageError)
            XCTAssertEqual(error as? LocalStorageError, .messageNotFound)
        }
    }

    func testDeleteNonExistentMessage() {
        // When/Then
        XCTAssertThrowsError(try service.deleteMessage(messageId: "non-existent")) { error in
            XCTAssertTrue(error is LocalStorageError)
            XCTAssertEqual(error as? LocalStorageError, .messageNotFound)
        }
    }

    // MARK: - Helper Methods

    private func createTestMessage(
        id: String = "test-msg-id",
        text: String = "Test message",
        senderId: String = "user-123",
        senderName: String = "Test User",
        status: MessageStatus = .sent,
        localId: String? = nil
    ) -> Message {
        return Message(
            id: id,
            senderId: senderId,
            senderName: senderName,
            senderPhotoURL: nil,
            text: text,
            timestamp: Date(),
            status: status,
            readBy: [:],
            deliveredTo: [:],
            localId: localId
        )
    }

    private func createTestConversation(
        id: String = "test-conv-id",
        participantIds: [String] = ["user-1", "user-2"],
        lastMessage: String? = "Last message",
        timestamp: Date? = nil,
        type: ConversationType = .oneOnOne
    ) -> Conversation {
        return Conversation(
            id: id,
            participantIds: participantIds,
            participantNames: ["user-1": "User One", "user-2": "User Two"],
            participantPhotos: [:],
            lastMessage: lastMessage,
            lastMessageTimestamp: timestamp ?? Date(),
            lastMessageSenderId: "user-1",
            type: type,
            groupName: nil,
            createdAt: Date(),
            createdBy: "user-1"
        )
    }
}
