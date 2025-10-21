//
//  MessageFirestoreTests.swift
//  messageAITests
//
//  Created by MessageAI on 10/21/25.
//

import XCTest
import FirebaseAuth
import FirebaseFirestore
@testable import messageAI

@MainActor
final class MessageFirestoreTests: FirebaseIntegrationTestCase {
    var messageService: MessageService!
    var conversationService: ConversationService!
    var testUserId: String!
    var testConversationId: String!

    override func setUp() async throws {
        try await super.setUp()

        // Create test user
        testUserId = try await createTestUser(
            email: "messagetest@example.com",
            password: "testpass123"
        )

        // Create in-memory local storage
        let container = try ModelContainer(
            for: LocalMessage.self, LocalConversation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let localStorage = LocalStorageService(modelContext: container.mainContext)

        // Initialize services
        messageService = MessageService(localStorageService: localStorage)

        conversationService = ConversationService(localStorageService: localStorage)

        // Create test conversation
        testConversationId = try await conversationService.createOrGetConversation(
            participantIds: [testUserId, "other-user-123"]
        )
    }

    override func tearDown() async throws {
        messageService?.stopListening()
        messageService = nil
        conversationService = nil
        try await deleteTestUser(userId: testUserId)
        try await cleanupFirestoreData()
        try await super.tearDown()
    }

    // MARK: - Message Creation Tests

    func testSendMessage_CreatesInFirestore() async throws {
        // Given
        let text = "Integration test message"
        let senderName = "Test User"

        // When
        try await messageService.sendMessage(
            conversationId: testConversationId,
            text: text,
            senderName: senderName
        )

        // Wait for Firestore sync
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then
        let snapshot = try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection(Constants.Collections.messages)
            .getDocuments()

        XCTAssertGreaterThan(snapshot.documents.count, 0)
        let firstDoc = snapshot.documents.first
        XCTAssertEqual(firstDoc?.data()["text"] as? String, text)
        XCTAssertEqual(firstDoc?.data()["senderId"] as? String, testUserId)
    }

    func testSendMessage_UpdatesConversationLastMessage() async throws {
        // Given
        let text = "Last message test"
        let senderName = "Test User"

        // When
        try await messageService.sendMessage(
            conversationId: testConversationId,
            text: text,
            senderName: senderName
        )

        // Wait for Firestore sync
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then
        let doc = try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .getDocument()

        let lastMessage = doc.data()?["lastMessage"] as? String
        XCTAssertEqual(lastMessage, text)
    }

    // MARK: - Real-Time Listener Tests

    func testRealTimeListener_ReceivesNewMessages() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Receive message via listener")

        // Start listening
        messageService.startListening(conversationId: testConversationId)

        // When - Add message directly to Firestore
        let messageData: [String: Any] = [
            "senderId": "other-user-123",
            "senderName": "Other User",
            "text": "Listener test message",
            "timestamp": Date(),
            "status": "sent",
            "readBy": [:],
            "deliveredTo": [:]
        ]

        try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection(Constants.Collections.messages)
            .addDocument(data: messageData)

        // Wait for listener to fire
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Then
        XCTAssertGreaterThan(messageService.messages.count, 0)
        let receivedMessage = messageService.messages.first { $0.text == "Listener test message" }
        XCTAssertNotNil(receivedMessage)

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 3.0)
    }

    func testRealTimeListener_FiltersOwnMessages() async throws {
        // Given
        let text = "Own message test"
        let senderName = "Test User"

        messageService.startListening(conversationId: testConversationId)

        // When
        try await messageService.sendMessage(
            conversationId: testConversationId,
            text: text,
            senderName: senderName
        )

        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Then
        let ownMessages = messageService.messages.filter { $0.senderId == testUserId }
        XCTAssertGreaterThan(ownMessages.count, 0)
    }

    // MARK: - Message Status Tests

    func testMarkAsDelivered_UpdatesFirestore() async throws {
        // Given - Create a message
        let messageData: [String: Any] = [
            "senderId": "other-user-123",
            "senderName": "Other User",
            "text": "Delivery test",
            "timestamp": Date(),
            "status": "sent",
            "readBy": [:],
            "deliveredTo": [:]
        ]

        let docRef = try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection(Constants.Collections.messages)
            .addDocument(data: messageData)

        let messageId = docRef.documentID

        // When
        try await messageService.markAsDelivered(
            conversationId: testConversationId,
            messageId: messageId
        )

        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then
        let doc = try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection(Constants.Collections.messages)
            .document(messageId)
            .getDocument()

        let deliveredTo = doc.data()?["deliveredTo"] as? [String: Any]
        XCTAssertNotNil(deliveredTo?[testUserId])
    }

    func testMarkAsRead_UpdatesFirestore() async throws {
        // Given - Create a message
        let messageData: [String: Any] = [
            "senderId": "other-user-123",
            "senderName": "Other User",
            "text": "Read test",
            "timestamp": Date(),
            "status": "delivered",
            "readBy": [:],
            "deliveredTo": [testUserId: Date()]
        ]

        let docRef = try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection(Constants.Collections.messages)
            .addDocument(data: messageData)

        let messageId = docRef.documentID

        // When
        try await messageService.markAsRead(
            conversationId: testConversationId,
            messageIds: [messageId]
        )

        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        let doc = try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection(Constants.Collections.messages)
            .document(messageId)
            .getDocument()

        let readBy = doc.data()?["readBy"] as? [String: Any]
        XCTAssertNotNil(readBy?[testUserId])
        XCTAssertEqual(doc.data()?["status"] as? String, "read")
    }

    // MARK: - Typing Indicators Tests

    func testSetTyping_CreatesIndicatorInFirestore() async throws {
        // When - Set typing to true
        try await messageService.setTyping(
            conversationId: testConversationId,
            isTyping: true
        )

        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        let doc = try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection("typing")
            .document(testUserId)
            .getDocument()

        XCTAssertTrue(doc.exists)
        XCTAssertEqual(doc.data()?["userId"] as? String, testUserId)
    }

    func testSetTyping_RemovesIndicatorWhenFalse() async throws {
        // Given - Set typing to true first
        try await messageService.setTyping(
            conversationId: testConversationId,
            isTyping: true
        )

        try await Task.sleep(nanoseconds: 500_000_000)

        // When - Set typing to false
        try await messageService.setTyping(
            conversationId: testConversationId,
            isTyping: false
        )

        try await Task.sleep(nanoseconds: 500_000_000)

        // Then
        let doc = try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection("typing")
            .document(testUserId)
            .getDocument()

        XCTAssertFalse(doc.exists)
    }

    func testTypingListener_DetectsOtherUsersTyping() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Detect typing user")

        messageService.startListeningForTyping(conversationId: testConversationId)

        // When - Simulate another user typing
        try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection("typing")
            .document("other-user-123")
            .setData([
                "userId": "other-user-123",
                "timestamp": FieldValue.serverTimestamp()
            ])

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then
        XCTAssertTrue(messageService.typingUsers.contains("other-user-123"))
        XCTAssertFalse(messageService.typingUsers.contains(testUserId))

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Multiple Messages Tests

    func testMultipleMessages_MaintainsOrder() async throws {
        // Given
        let messages = ["First", "Second", "Third"]
        let senderName = "Test User"

        // When
        for text in messages {
            try await messageService.sendMessage(
                conversationId: testConversationId,
                text: text,
                senderName: senderName
            )
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        }

        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Then
        let snapshot = try await firestore
            .collection(Constants.Collections.conversations)
            .document(testConversationId)
            .collection(Constants.Collections.messages)
            .order(by: "timestamp", descending: false)
            .getDocuments()

        XCTAssertEqual(snapshot.documents.count, 3)

        let fetchedMessages = snapshot.documents.compactMap { $0.data()["text"] as? String }
        XCTAssertEqual(fetchedMessages, messages)
    }

    // MARK: - Performance Tests

    func testPerformance_SendMessages() {
        let senderName = "Test User"

        measure {
            Task {
                do {
                    for index in 0..<5 {
                        try await messageService.sendMessage(
                            conversationId: testConversationId,
                            text: "Performance test \(index)",
                            senderName: senderName
                        )
                    }
                } catch {
                    XCTFail("Failed to send messages: \(error)")
                }
            }
        }
    }
}


