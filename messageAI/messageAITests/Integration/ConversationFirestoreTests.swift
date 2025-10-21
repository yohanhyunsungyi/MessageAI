//
//  ConversationFirestoreTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
import FirebaseFirestore
@testable import messageAI

/// Integration tests for ConversationService with Firestore
/// Tests real Firestore operations (requires Firebase Emulator)
@MainActor
final class ConversationFirestoreTests: FirebaseIntegrationTestCase {

    var conversationService: ConversationService!
    var testUserIds: [String] = []
    var conversationIds: [String] = []

    override func setUp() async throws {
        try await super.setUp()

        // Create test users
        let user1Id = try await createTestUser(
            email: "conv.test1@test.com",
            password: "Test123456",
            displayName: "Conv User 1"
        )

        let user2Id = try await createTestUser(
            email: "conv.test2@test.com",
            password: "Test123456",
            displayName: "Conv User 2"
        )

        let user3Id = try await createTestUser(
            email: "conv.test3@test.com",
            password: "Test123456",
            displayName: "Conv User 3"
        )

        testUserIds = [user1Id, user2Id, user3Id]

        // Sign in as first user
        try await signInTestUser(email: "conv.test1@test.com", password: "Test123456")

        // Initialize service
        conversationService = ConversationService()
    }

    override func tearDown() async throws {
        // Clean up conversations
        for conversationId in conversationIds {
            try await deleteConversation(conversationId: conversationId)
        }
        conversationIds.removeAll()

        // Clean up test users
        for userId in testUserIds {
            try await deleteTestUser(userId: userId)
        }
        testUserIds.removeAll()

        conversationService = nil

        try await super.tearDown()
    }

    // MARK: - One-on-One Conversation Tests

    func testCreateOneOnOneConversation() async throws {
        // Given: Two users
        let participantIds = [testUserIds[0], testUserIds[1]]

        // When: Create one-on-one conversation
        let conversationId = try await conversationService.createOrGetConversation(
            participantIds: participantIds
        )

        conversationIds.append(conversationId)

        // Then: Conversation should exist in Firestore
        let snapshot = try await firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .getDocument()

        XCTAssertTrue(snapshot.exists, "Conversation should exist in Firestore")

        let conversation = try snapshot.data(as: Conversation.self)
        XCTAssertEqual(conversation.type, .oneOnOne)
        XCTAssertEqual(Set(conversation.participantIds), Set(participantIds))
        XCTAssertNil(conversation.groupName)
        XCTAssertEqual(conversation.createdBy, testUserIds[0])
    }

    func testCreateOrGetConversationReturnsSameConversation() async throws {
        // Given: Two users with existing conversation
        let participantIds = [testUserIds[0], testUserIds[1]]

        // When: Create conversation twice
        let conversationId1 = try await conversationService.createOrGetConversation(
            participantIds: participantIds
        )
        conversationIds.append(conversationId1)

        let conversationId2 = try await conversationService.createOrGetConversation(
            participantIds: participantIds
        )

        // Then: Should return same conversation ID
        XCTAssertEqual(conversationId1, conversationId2)
    }

    func testCreateOneOnOneConversationFetchesParticipantDetails() async throws {
        // Given: Two users with profiles
        let participantIds = [testUserIds[0], testUserIds[1]]

        // When: Create conversation
        let conversationId = try await conversationService.createOrGetConversation(
            participantIds: participantIds
        )
        conversationIds.append(conversationId)

        // Then: Participant names should be populated
        let conversation = try await conversationService.getConversation(id: conversationId)

        XCTAssertEqual(conversation.participantNames.count, 2)
        XCTAssertEqual(conversation.participantNames[testUserIds[0]], "Conv User 1")
        XCTAssertEqual(conversation.participantNames[testUserIds[1]], "Conv User 2")
    }

    // MARK: - Group Conversation Tests

    func testCreateGroupConversation() async throws {
        // Given: Three users
        let participantIds = [testUserIds[0], testUserIds[1], testUserIds[2]]
        let groupName = "Test Group"

        // When: Create group conversation
        let conversationId = try await conversationService.createGroupConversation(
            participantIds: participantIds,
            groupName: groupName
        )
        conversationIds.append(conversationId)

        // Then: Conversation should exist in Firestore
        let snapshot = try await firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .getDocument()

        XCTAssertTrue(snapshot.exists, "Group conversation should exist in Firestore")

        let conversation = try snapshot.data(as: Conversation.self)
        XCTAssertEqual(conversation.type, .group)
        XCTAssertEqual(Set(conversation.participantIds), Set(participantIds))
        XCTAssertEqual(conversation.groupName, groupName)
        XCTAssertEqual(conversation.createdBy, testUserIds[0])
    }

    func testGroupConversationTrimsWhitespaceInName() async throws {
        // Given: Group name with whitespace
        let participantIds = [testUserIds[0], testUserIds[1], testUserIds[2]]
        let groupName = "  Test Group  "

        // When: Create group conversation
        let conversationId = try await conversationService.createGroupConversation(
            participantIds: participantIds,
            groupName: groupName
        )
        conversationIds.append(conversationId)

        // Then: Group name should be trimmed
        let conversation = try await conversationService.getConversation(id: conversationId)
        XCTAssertEqual(conversation.groupName, "Test Group")
    }

    // MARK: - Fetch Conversations Tests

    func testFetchConversationsReturnsUserConversations() async throws {
        // Given: Multiple conversations
        let conv1Id = try await conversationService.createOrGetConversation(
            participantIds: [testUserIds[0], testUserIds[1]]
        )
        conversationIds.append(conv1Id)

        let conv2Id = try await conversationService.createGroupConversation(
            participantIds: [testUserIds[0], testUserIds[1], testUserIds[2]],
            groupName: "Group 1"
        )
        conversationIds.append(conv2Id)

        // When: Fetch conversations
        try await conversationService.fetchConversations()

        // Then: Should return all user's conversations
        XCTAssertEqual(conversationService.conversations.count, 2)

        let conversationIds = conversationService.conversations.map { $0.id }
        XCTAssertTrue(conversationIds.contains(conv1Id))
        XCTAssertTrue(conversationIds.contains(conv2Id))
    }

    func testFetchConversationsOnlyReturnsUserParticipatingIn() async throws {
        // Given: Conversation where user1 is not a participant
        // Sign in as user2
        try await signInTestUser(email: "conv.test2@test.com", password: "Test123456")

        let otherService = ConversationService()
        let conv1Id = try await otherService.createOrGetConversation(
            participantIds: [testUserIds[1], testUserIds[2]]
        )
        conversationIds.append(conv1Id)

        // Sign back in as user1
        try await signInTestUser(email: "conv.test1@test.com", password: "Test123456")

        // When: User1 fetches conversations
        try await conversationService.fetchConversations()

        // Then: Should not include conversation where user1 is not participant
        let conversationIds = conversationService.conversations.map { $0.id }
        XCTAssertFalse(conversationIds.contains(conv1Id))
    }

    // MARK: - Update Conversation Tests

    func testUpdateLastMessage() async throws {
        // Given: A conversation
        let conversationId = try await conversationService.createOrGetConversation(
            participantIds: [testUserIds[0], testUserIds[1]]
        )
        conversationIds.append(conversationId)

        // When: Update last message
        let message = MockHelpers.mockMessage(
            id: "msg1",
            conversationId: conversationId,
            senderId: testUserIds[0],
            text: "Hello World"
        )

        try await conversationService.updateLastMessage(
            conversationId: conversationId,
            message: message
        )

        // Wait for Firestore to update
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then: Last message should be updated in Firestore
        let conversation = try await conversationService.getConversation(id: conversationId)

        XCTAssertEqual(conversation.lastMessage, "Hello World")
        XCTAssertEqual(conversation.lastMessageSenderId, testUserIds[0])
        XCTAssertNotNil(conversation.lastMessageTimestamp)
    }

    // MARK: - Real-Time Listener Tests

    func testRealTimeListenerReceivesUpdates() async throws {
        // Given: Service with active listener
        conversationService.startListening(userId: testUserIds[0])

        // Wait for initial load
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        let initialCount = conversationService.conversations.count

        // When: Create new conversation
        let conversationId = try await conversationService.createOrGetConversation(
            participantIds: [testUserIds[0], testUserIds[1]]
        )
        conversationIds.append(conversationId)

        // Wait for listener to receive update
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then: Conversations should be updated
        XCTAssertEqual(
            conversationService.conversations.count,
            initialCount + 1,
            "Should receive real-time update"
        )

        let conversationIds = conversationService.conversations.map { $0.id }
        XCTAssertTrue(conversationIds.contains(conversationId))

        // Cleanup
        conversationService.stopListening()
    }

    func testRealTimeListenerReceivesMessageUpdates() async throws {
        // Given: Conversation with listener
        let conversationId = try await conversationService.createOrGetConversation(
            participantIds: [testUserIds[0], testUserIds[1]]
        )
        conversationIds.append(conversationId)

        conversationService.startListening(userId: testUserIds[0])
        try await Task.sleep(nanoseconds: 500_000_000)

        // When: Update last message
        let message = MockHelpers.mockMessage(
            id: "msg1",
            conversationId: conversationId,
            senderId: testUserIds[0],
            text: "Real-time test"
        )

        try await conversationService.updateLastMessage(
            conversationId: conversationId,
            message: message
        )

        // Wait for listener to receive update
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then: Should receive updated conversation
        let updatedConversation = conversationService.conversations.first { $0.id == conversationId }
        XCTAssertNotNil(updatedConversation)
        XCTAssertEqual(updatedConversation?.lastMessage, "Real-time test")

        // Cleanup
        conversationService.stopListening()
    }

    // MARK: - Local Storage Integration Tests

    func testConversationSavedToLocalStorage() async throws {
        // Given: A conversation
        let conversationId = try await conversationService.createOrGetConversation(
            participantIds: [testUserIds[0], testUserIds[1]]
        )
        conversationIds.append(conversationId)

        // Then: Should be saved to local storage
        let localStorageService = LocalStorageService.shared
        let localConversation = await localStorageService.fetchConversation(id: conversationId)

        XCTAssertNotNil(localConversation)
        XCTAssertEqual(localConversation?.id, conversationId)
    }

    // MARK: - Error Handling Tests

    func testGetNonExistentConversationThrowsError() async throws {
        // Given: Non-existent conversation ID
        let fakeId = "nonexistent-conversation-id"

        // When: Try to get conversation
        // Then: Should throw error
        do {
            _ = try await conversationService.getConversation(id: fakeId)
            XCTFail("Should throw error for non-existent conversation")
        } catch {
            // Expected error
            XCTAssertTrue(true, "Correctly threw error for non-existent conversation")
        }
    }

    // MARK: - Performance Tests

    func testFetchConversationsPerformance() async throws {
        // Create multiple conversations
        for index in 0..<5 {
            let convId = try await conversationService.createOrGetConversation(
                participantIds: [testUserIds[0], testUserIds[1]]
            )
            conversationIds.append(convId)

            // Make each conversation unique by updating with different message
            let message = MockHelpers.mockMessage(
                id: "msg\(index)",
                conversationId: convId,
                senderId: testUserIds[0],
                text: "Message \(index)"
            )
            try await conversationService.updateLastMessage(
                conversationId: convId,
                message: message
            )
        }

        measure {
            let expectation = XCTestExpectation(description: "Fetch conversations")

            Task {
                do {
                    try await conversationService.fetchConversations()
                    expectation.fulfill()
                } catch {
                    XCTFail("Fetch failed: \(error.localizedDescription)")
                }
            }

            wait(for: [expectation], timeout: 5.0)
        }
    }

    // MARK: - Helper Methods

    private func deleteConversation(conversationId: String) async throws {
        try await firestore
            .collection(Constants.Collections.conversations)
            .document(conversationId)
            .delete()
    }
}
