//
//  ModelTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
@testable import messageAI

final class ModelTests: XCTestCase {

    // MARK: - MessageStatus Tests

    func testMessageStatusRawValues() {
        XCTAssertEqual(MessageStatus.sending.rawValue, "sending")
        XCTAssertEqual(MessageStatus.sent.rawValue, "sent")
        XCTAssertEqual(MessageStatus.delivered.rawValue, "delivered")
        XCTAssertEqual(MessageStatus.read.rawValue, "read")
        XCTAssertEqual(MessageStatus.failed.rawValue, "failed")
    }

    func testMessageStatusCodable() throws {
        let status = MessageStatus.sent
        let encoded = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(MessageStatus.self, from: encoded)
        XCTAssertEqual(decoded, status)
    }

    // MARK: - ConversationType Tests

    func testConversationTypeRawValues() {
        XCTAssertEqual(ConversationType.oneOnOne.rawValue, "oneOnOne")
        XCTAssertEqual(ConversationType.group.rawValue, "group")
    }

    func testConversationTypeCodable() throws {
        let type = ConversationType.group
        let encoded = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(ConversationType.self, from: encoded)
        XCTAssertEqual(decoded, type)
    }

    // MARK: - User Model Tests

    func testUserModelCreation() {
        let user = User(
            id: "user123",
            displayName: "Test User",
            photoURL: "https://example.com/photo.jpg",
            phoneNumber: "+1234567890",
            isOnline: true,
            lastSeen: Date(),
            fcmToken: "fcm_token_123",
            createdAt: Date()
        )

        XCTAssertEqual(user.id, "user123")
        XCTAssertEqual(user.displayName, "Test User")
        XCTAssertEqual(user.photoURL, "https://example.com/photo.jpg")
        XCTAssertTrue(user.isOnline)
    }

    func testUserModelCodable() throws {
        let user = User(
            id: "user123",
            displayName: "Test User",
            photoURL: nil,
            phoneNumber: nil,
            isOnline: false,
            lastSeen: Date(),
            fcmToken: nil,
            createdAt: Date()
        )

        let encoded = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(User.self, from: encoded)

        XCTAssertEqual(decoded.id, user.id)
        XCTAssertEqual(decoded.displayName, user.displayName)
        XCTAssertEqual(decoded.isOnline, user.isOnline)
    }

    // MARK: - Message Model Tests

    func testMessageModelCreation() {
        let message = Message(
            id: "msg123",
            senderId: "user123",
            senderName: "Test User",
            senderPhotoURL: nil,
            text: "Hello, World!",
            timestamp: Date(),
            status: .sent,
            readBy: ["user456": Date()],
            deliveredTo: ["user456": Date()],
            localId: "local_msg_123"
        )

        XCTAssertEqual(message.id, "msg123")
        XCTAssertEqual(message.senderId, "user123")
        XCTAssertEqual(message.text, "Hello, World!")
        XCTAssertEqual(message.status, .sent)
        XCTAssertEqual(message.readBy.count, 1)
    }

    func testMessageModelCodable() throws {
        let message = Message(
            id: "msg123",
            senderId: "user123",
            senderName: "Test User",
            senderPhotoURL: nil,
            text: "Test message",
            timestamp: Date(),
            status: .delivered,
            readBy: [:],
            deliveredTo: [:],
            localId: nil
        )

        let encoded = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(Message.self, from: encoded)

        XCTAssertEqual(decoded.id, message.id)
        XCTAssertEqual(decoded.text, message.text)
        XCTAssertEqual(decoded.status, message.status)
    }

    func testMessageStatusTransitions() {
        var message = Message(
            id: "msg123",
            senderId: "user123",
            senderName: "Test User",
            senderPhotoURL: nil,
            text: "Test",
            timestamp: Date(),
            status: .sending,
            readBy: [:],
            deliveredTo: [:],
            localId: "local_123"
        )

        XCTAssertEqual(message.status, .sending)
        message.status = .sent
        XCTAssertEqual(message.status, .sent)
        message.status = .delivered
        XCTAssertEqual(message.status, .delivered)
        message.status = .read
        XCTAssertEqual(message.status, .read)
    }

    // MARK: - Conversation Model Tests

    func testConversationModelOneOnOne() {
        let conversation = Conversation(
            id: "conv123",
            participantIds: ["user123", "user456"],
            participantNames: ["user123": "Alice", "user456": "Bob"],
            participantPhotos: [:],
            lastMessage: "Hello!",
            lastMessageTimestamp: Date(),
            lastMessageSenderId: "user123",
            type: .oneOnOne,
            groupName: nil,
            createdAt: Date(),
            createdBy: "user123"
        )

        XCTAssertEqual(conversation.id, "conv123")
        XCTAssertEqual(conversation.participantIds.count, 2)
        XCTAssertEqual(conversation.type, .oneOnOne)
        XCTAssertNil(conversation.groupName)
    }

    func testConversationModelGroup() {
        let conversation = Conversation(
            id: "conv456",
            participantIds: ["user123", "user456", "user789"],
            participantNames: ["user123": "Alice", "user456": "Bob", "user789": "Charlie"],
            participantPhotos: [:],
            lastMessage: "Group message",
            lastMessageTimestamp: Date(),
            lastMessageSenderId: "user456",
            type: .group,
            groupName: "Test Group",
            createdAt: Date(),
            createdBy: "user123"
        )

        XCTAssertEqual(conversation.participantIds.count, 3)
        XCTAssertEqual(conversation.type, .group)
        XCTAssertEqual(conversation.groupName, "Test Group")
    }

    func testConversationModelCodable() throws {
        let conversation = Conversation(
            id: "conv123",
            participantIds: ["user123", "user456"],
            participantNames: ["user123": "Alice", "user456": "Bob"],
            participantPhotos: [:],
            lastMessage: "Test",
            lastMessageTimestamp: Date(),
            lastMessageSenderId: "user123",
            type: .oneOnOne,
            groupName: nil,
            createdAt: Date(),
            createdBy: "user123"
        )

        let encoded = try JSONEncoder().encode(conversation)
        let decoded = try JSONDecoder().decode(Conversation.self, from: encoded)

        XCTAssertEqual(decoded.id, conversation.id)
        XCTAssertEqual(decoded.type, conversation.type)
    }

    // MARK: - LocalMessage Model Tests

    func testLocalMessageCreation() {
        let localMessage = LocalMessage(
            id: "local_msg_123",
            conversationId: "conv123",
            senderId: "user123",
            senderName: "Test User",
            text: "Local message",
            timestamp: Date(),
            status: "sending",
            isPending: true,
            localId: "local_123"
        )

        XCTAssertEqual(localMessage.id, "local_msg_123")
        XCTAssertEqual(localMessage.conversationId, "conv123")
        XCTAssertEqual(localMessage.status, "sending")
        XCTAssertTrue(localMessage.isPending)
    }

    func testLocalMessageStatusUpdate() {
        let localMessage = LocalMessage(
            id: "msg123",
            conversationId: "conv123",
            senderId: "user123",
            senderName: "Test User",
            text: "Test",
            timestamp: Date(),
            status: "sending",
            isPending: true,
            localId: "local_123"
        )

        XCTAssertEqual(localMessage.status, "sending")
        localMessage.status = "sent"
        localMessage.isPending = false
        XCTAssertEqual(localMessage.status, "sent")
        XCTAssertFalse(localMessage.isPending)
    }

    // MARK: - LocalConversation Model Tests

    func testLocalConversationCreation() {
        let localConversation = LocalConversation(
            id: "conv123",
            participantIds: ["user123", "user456"],
            lastMessage: "Hello",
            lastMessageTimestamp: Date(),
            type: "oneOnOne",
            groupName: nil
        )

        XCTAssertEqual(localConversation.id, "conv123")
        XCTAssertEqual(localConversation.participantIds.count, 2)
        XCTAssertEqual(localConversation.type, "oneOnOne")
        XCTAssertNil(localConversation.groupName)
    }

    func testLocalConversationGroupType() {
        let localConversation = LocalConversation(
            id: "conv456",
            participantIds: ["user123", "user456", "user789"],
            lastMessage: "Group chat",
            lastMessageTimestamp: Date(),
            type: "group",
            groupName: "Test Group"
        )

        XCTAssertEqual(localConversation.type, "group")
        XCTAssertEqual(localConversation.groupName, "Test Group")
        XCTAssertEqual(localConversation.participantIds.count, 3)
    }

    func testLocalConversationUpdate() {
        let localConversation = LocalConversation(
            id: "conv123",
            participantIds: ["user123", "user456"],
            lastMessage: "First message",
            lastMessageTimestamp: Date(),
            type: "oneOnOne",
            groupName: nil
        )

        XCTAssertEqual(localConversation.lastMessage, "First message")
        localConversation.lastMessage = "Updated message"
        XCTAssertEqual(localConversation.lastMessage, "Updated message")
    }
}
