//
//  ReadReceiptsTests.swift
//  messageAITests
//
//  Created by MessageAI on 10/21/25.
//

import XCTest
import FirebaseAuth
import FirebaseFirestore
@testable import messageAI

@MainActor
final class ReadReceiptsTests: FirebaseIntegrationTestCase {

    var messageService: MessageService!
    var conversationService: ConversationService!
    var testConversationId: String!
    var testUser1Id: String!
    var testUser2Id: String!

    override func setUp() async throws {
        try await super.setUp()

        // Initialize services
        messageService = MessageService(localStorageService: localStorageService)
        conversationService = ConversationService(localStorageService: localStorageService)

        // Create test users
        testUser1Id = try await createTestUser(email: "readreceipts1@test.com", password: "password123")
        testUser2Id = try await createTestUser(email: "readreceipts2@test.com", password: "password123")

        // Sign in as user1
        try await signInTestUser(email: "readreceipts1@test.com", password: "password123")

        // Create test conversation
        testConversationId = try await conversationService.createOrGetConversation(
            participantIds: [testUser1Id, testUser2Id]
        )

        print("✅ Setup complete: conversation=\(testConversationId ?? "nil")")
    }

    override func tearDown() async throws {
        messageService = nil
        conversationService = nil
        testConversationId = nil
        testUser1Id = nil
        testUser2Id = nil

        try await super.tearDown()
    }

    // MARK: - Message Status Tests

    func testMessageStatusTransition() async throws {
        // Given: User1 sends a message
        try await messageService.sendMessage(
            conversationId: testConversationId,
            text: "Test message for status transition",
            senderName: "User 1"
        )

        // Wait for message to sync
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then: Message should have status transitions
        let messages = messageService.messages
        XCTAssertFalse(messages.isEmpty, "Should have at least one message")

        if let message = messages.first {
            // Message should be at least 'sent' after syncing
            XCTAssertTrue(
                [.sent, .delivered, .read].contains(message.status),
                "Message status should be sent, delivered, or read, but was \(message.status)"
            )
        }
    }

    func testMarkAsDelivered() async throws {
        // Given: User1 sends a message
        try await messageService.sendMessage(
            conversationId: testConversationId,
            text: "Test message for delivered",
            senderName: "User 1"
        )

        // Wait for message to sync
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        guard let message = messageService.messages.first else {
            XCTFail("No messages found")
            return
        }

        // When: User2 marks it as delivered
        try await signInTestUser(email: "readreceipts2@test.com", password: "password123")
        let messageService2 = MessageService(localStorageService: localStorageService)

        try await messageService2.markAsDelivered(
            conversationId: testConversationId,
            messageId: message.id
        )

        // Then: Message should be marked as delivered
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second

        // Verify in Firestore
        let docRef = firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection(Constants.Collections.messages)
            .document(message.id)

        let snapshot = try await docRef.getDocument()
        XCTAssertTrue(snapshot.exists, "Message document should exist")

        let data = snapshot.data()
        let deliveredTo = data?["deliveredTo"] as? [String: Any]
        XCTAssertNotNil(deliveredTo, "deliveredTo should not be nil")
        XCTAssertNotNil(deliveredTo?[testUser2Id], "User2 should be in deliveredTo")
    }

    func testMarkAsRead() async throws {
        // Given: User1 sends a message
        try await messageService.sendMessage(
            conversationId: testConversationId,
            text: "Test message for read",
            senderName: "User 1"
        )

        // Wait for message to sync
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        guard let message = messageService.messages.first else {
            XCTFail("No messages found")
            return
        }

        // When: User2 marks it as read
        try await signInTestUser(email: "readreceipts2@test.com", password: "password123")
        let messageService2 = MessageService(localStorageService: localStorageService)

        try await messageService2.markAsRead(
            conversationId: testConversationId,
            messageIds: [message.id]
        )

        // Then: Message should be marked as read
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second

        // Verify in Firestore
        let docRef = firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection(Constants.Collections.messages)
            .document(message.id)

        let snapshot = try await docRef.getDocument()
        XCTAssertTrue(snapshot.exists, "Message document should exist")

        let data = snapshot.data()
        let readBy = data?["readBy"] as? [String: Any]
        XCTAssertNotNil(readBy, "readBy should not be nil")
        XCTAssertNotNil(readBy?[testUser2Id], "User2 should be in readBy")

        // Status should be 'read'
        let status = data?["status"] as? String
        XCTAssertEqual(status, MessageStatus.read.rawValue, "Status should be 'read'")
    }

    func testAutoMarkAsDelivered() async throws {
        // Given: User1 sends a message
        try await signInTestUser(email: "readreceipts1@test.com", password: "password123")
        try await messageService.sendMessage(
            conversationId: testConversationId,
            text: "Test auto delivered",
            senderName: "User 1"
        )

        // Wait for message to sync
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        guard let message = messageService.messages.first else {
            XCTFail("No messages found")
            return
        }

        // When: User2 starts listening (should auto-mark as delivered)
        try await signInTestUser(email: "readreceipts2@test.com", password: "password123")
        let messageService2 = MessageService(localStorageService: localStorageService)
        messageService2.startListening(conversationId: testConversationId)

        // Wait for listener to process
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Then: Message should be auto-marked as delivered
        let docRef = firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection(Constants.Collections.messages)
            .document(message.id)

        let snapshot = try await docRef.getDocument()
        let data = snapshot.data()
        let deliveredTo = data?["deliveredTo"] as? [String: Any]

        // Should eventually be marked as delivered
        XCTAssertNotNil(deliveredTo, "deliveredTo should not be nil")

        messageService2.stopListening()
    }

    func testReadReceiptsWithMultipleMessages() async throws {
        // Given: User1 sends multiple messages
        let messageTexts = ["Message 1", "Message 2", "Message 3"]

        for text in messageTexts {
            try await messageService.sendMessage(
                conversationId: testConversationId,
                text: text,
                senderName: "User 1"
            )
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second between messages
        }

        // Wait for all messages to sync
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        let sentMessages = messageService.messages
        XCTAssertEqual(sentMessages.count, 3, "Should have 3 messages")

        let messageIds = sentMessages.map { $0.id }

        // When: User2 marks all as read
        try await signInTestUser(email: "readreceipts2@test.com", password: "password123")
        let messageService2 = MessageService(localStorageService: localStorageService)

        try await messageService2.markAsRead(
            conversationId: testConversationId,
            messageIds: messageIds
        )

        // Wait for updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then: All messages should be marked as read
        for messageId in messageIds {
            let docRef = firestore
                .collection(Constants.Collections.conversations)
                .document(testConversationId)
                .collection(Constants.Collections.messages)
                .document(messageId)

            let snapshot = try await docRef.getDocument()
            let data = snapshot.data()
            let readBy = data?["readBy"] as? [String: Any]

            XCTAssertNotNil(readBy?[testUser2Id], "Message \(messageId) should be read by User2")
        }
    }

    // MARK: - Performance Tests

    func testReadReceiptsPerformance() throws {
        measure {
            Task {
                // Performance test: Mark 10 messages as read
                var messageIds: [String] = []

                // Send messages
                for index in 1...10 {
                    do {
                        try await self.messageService.sendMessage(
                            conversationId: self.testConversationId,
                            text: "Performance test message \(index)",
                            senderName: "User 1"
                        )
                        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                    } catch {
                        print("Error sending message: \(error)")
                    }
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                messageIds = self.messageService.messages.map { $0.id }

                // Mark as read
                do {
                    try await self.messageService.markAsRead(
                        conversationId: self.testConversationId,
                        messageIds: messageIds
                    )
                } catch {
                    print("Error marking as read: \(error)")
                }
            }
        }
    }
}

