//
//  GroupChatTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
@testable import messageAI

@MainActor
final class GroupChatTests: FirebaseIntegrationTestCase {

    var conversationService: ConversationService!
    var messageService: MessageService!
    var localStorageService: LocalStorageService!

    // Test users
    var testUser1Uid: String!
    var testUser1Email: String = "grouptest1@test.com"
    var testUser1Password: String!

    var testUser2Uid: String!
    var testUser2Email: String = "grouptest2@test.com"
    var testUser2Password: String!

    var testUser3Uid: String!
    var testUser3Email: String = "grouptest3@test.com"
    var testUser3Password: String!

    override func setUp() async throws {
        try await super.setUp()

        // Create local storage service
        localStorageService = LocalStorageService()

        // Create services
        conversationService = ConversationService(localStorageService: localStorageService)
        messageService = MessageService(localStorageService: localStorageService)

        // Create test users
        let user1 = try await createTestUser(email: testUser1Email)
        testUser1Uid = user1.uid
        testUser1Password = user1.password

        let user2 = try await createTestUser(email: testUser2Email)
        testUser2Uid = user2.uid
        testUser2Password = user2.password

        let user3 = try await createTestUser(email: testUser3Email)
        testUser3Uid = user3.uid
        testUser3Password = user3.password
    }

    override func tearDown() async throws {
        // Clean up
        conversationService = nil
        messageService = nil
        localStorageService = nil

        try await super.tearDown()
    }

    // MARK: - Group Creation Tests

    func testCreateGroupConversation() async throws {
        // Given: Sign in as user 1
        try await signIn(email: testUser1Email, password: testUser1Password)

        let participantIds = [testUser1Uid!, testUser2Uid!, testUser3Uid!]
        let groupName = "Test Group Chat"

        // When: Create group conversation
        let conversationId = try await conversationService.createGroupConversation(
            participantIds: participantIds,
            groupName: groupName
        )

        // Then: Conversation should be created
        XCTAssertFalse(conversationId.isEmpty, "Conversation ID should not be empty")

        // Verify conversation exists in Firestore
        let conversation = try await conversationService.getConversation(id: conversationId)

        XCTAssertEqual(conversation.id, conversationId)
        XCTAssertEqual(conversation.type, .group)
        XCTAssertEqual(conversation.groupName, groupName)
        XCTAssertEqual(Set(conversation.participantIds), Set(participantIds))
        XCTAssertEqual(conversation.participantIds.count, 3)
        XCTAssertEqual(conversation.createdBy, testUser1Uid)
    }

    func testCreateGroupWithMinimumParticipants() async throws {
        // Given: Sign in as user 1
        try await signIn(email: testUser1Email, password: testUser1Password)

        let participantIds = [testUser1Uid!, testUser2Uid!, testUser3Uid!]

        // When: Create group with exactly 3 participants (minimum for group)
        let conversationId = try await conversationService.createGroupConversation(
            participantIds: participantIds,
            groupName: "Trio Group"
        )

        // Then: Should succeed
        let conversation = try await conversationService.getConversation(id: conversationId)
        XCTAssertEqual(conversation.participantIds.count, 3)
    }

    func testCreateGroupWithInvalidParticipantCount() async throws {
        // Given: Sign in as user 1
        try await signIn(email: testUser1Email, password: testUser1Password)

        // Only 2 participants (should fail for group)
        let participantIds = [testUser1Uid!, testUser2Uid!]

        // When/Then: Should throw error
        do {
            _ = try await conversationService.createGroupConversation(
                participantIds: participantIds,
                groupName: "Invalid Group"
            )
            XCTFail("Should have thrown error for insufficient participants")
        } catch {
            XCTAssertTrue(error is ConversationError)
        }
    }

    func testCreateGroupWithEmptyName() async throws {
        // Given: Sign in as user 1
        try await signIn(email: testUser1Email, password: testUser1Password)

        let participantIds = [testUser1Uid!, testUser2Uid!, testUser3Uid!]

        // When/Then: Should throw error for empty name
        do {
            _ = try await conversationService.createGroupConversation(
                participantIds: participantIds,
                groupName: "   " // Whitespace only
            )
            XCTFail("Should have thrown error for empty group name")
        } catch {
            XCTAssertTrue(error is ConversationError)
        }
    }

    // MARK: - Group Messaging Tests

    func testSendMessageToGroup() async throws {
        // Given: Create group and sign in as user 1
        try await signIn(email: testUser1Email, password: testUser1Password)

        let participantIds = [testUser1Uid!, testUser2Uid!, testUser3Uid!]
        let conversationId = try await conversationService.createGroupConversation(
            participantIds: participantIds,
            groupName: "Test Group"
        )

        // When: Send message to group
        let messageText = "Hello everyone in the group!"
        try await messageService.sendMessage(
            conversationId: conversationId,
            text: messageText,
            senderName: "User 1",
            senderPhotoURL: nil
        )

        // Wait for message to propagate
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then: Message should exist in Firestore
        let messagesRef = firestore.collection(Constants.Collections.conversations)
            .document(conversationId)
            .collection("messages")

        let snapshot = try await messagesRef.getDocuments()
        XCTAssertFalse(snapshot.isEmpty, "Messages should exist")

        let message = try snapshot.documents.first?.data(as: Message.self)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.text, messageText)
        XCTAssertEqual(message?.senderId, testUser1Uid)
    }

    func testMultipleUsersReceiveGroupMessage() async throws {
        // Given: Create group as user 1
        try await signIn(email: testUser1Email, password: testUser1Password)

        let participantIds = [testUser1Uid!, testUser2Uid!, testUser3Uid!]
        let conversationId = try await conversationService.createGroupConversation(
            participantIds: participantIds,
            groupName: "Multi-User Group"
        )

        // User 1 sends a message
        try await messageService.sendMessage(
            conversationId: conversationId,
            text: "Message from User 1",
            senderName: "User 1",
            senderPhotoURL: nil
        )

        try await Task.sleep(nanoseconds: 300_000_000)

        // When: User 2 fetches messages
        try await signIn(email: testUser2Email, password: testUser2Password)
        let messageService2 = MessageService(localStorageService: localStorageService)
        messageService2.startListening(conversationId: conversationId)

        try await Task.sleep(nanoseconds: 500_000_000)

        // Then: User 2 should receive the message
        XCTAssertFalse(messageService2.messages.isEmpty, "User 2 should have messages")
        XCTAssertEqual(messageService2.messages.first?.text, "Message from User 1")
    }

    func testGroupMessageSenderAttribution() async throws {
        // Given: Create group
        try await signIn(email: testUser1Email, password: testUser1Password)

        let participantIds = [testUser1Uid!, testUser2Uid!, testUser3Uid!]
        let conversationId = try await conversationService.createGroupConversation(
            participantIds: participantIds,
            groupName: "Attribution Test"
        )

        // When: User 1 sends a message
        try await messageService.sendMessage(
            conversationId: conversationId,
            text: "Test message",
            senderName: "Test User One",
            senderPhotoURL: nil
        )

        try await Task.sleep(nanoseconds: 300_000_000)

        // Then: Message should have correct sender information
        let messagesRef = firestore.collection(Constants.Collections.conversations)
            .document(conversationId)
            .collection("messages")

        let snapshot = try await messagesRef.getDocuments()
        let message = try snapshot.documents.first?.data(as: Message.self)

        XCTAssertNotNil(message)
        XCTAssertEqual(message?.senderId, testUser1Uid)
        XCTAssertEqual(message?.senderName, "Test User One")
    }

    func testGroupConversationAppearsinList() async throws {
        // Given: Create group as user 1
        try await signIn(email: testUser1Email, password: testUser1Password)

        let participantIds = [testUser1Uid!, testUser2Uid!, testUser3Uid!]
        let conversationId = try await conversationService.createGroupConversation(
            participantIds: participantIds,
            groupName: "List Test Group"
        )

        // When: Fetch conversations
        try await conversationService.fetchConversations()

        let expectation = XCTestExpectation(description: "Wait for listener")
        conversationService.startListening(userId: testUser1Uid)

        // Give the listener time to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        // Then: Group conversation should be in list
        let conversations = conversationService.conversations
        XCTAssertFalse(conversations.isEmpty, "Should have conversations")

        let groupConversation = conversations.first { $0.id == conversationId }
        XCTAssertNotNil(groupConversation)
        XCTAssertEqual(groupConversation?.type, .group)
        XCTAssertEqual(groupConversation?.groupName, "List Test Group")
        conversationService.stopListening()
    }

    // MARK: - Group Metadata Tests

    func testGroupParticipantNames() async throws {
        // Given: Create test user documents
        try await signIn(email: testUser1Email, password: testUser1Password)

        // Create user documents with names
        try await createUserDocument(uid: testUser1Uid, displayName: "Alice")
        try await createUserDocument(uid: testUser2Uid, displayName: "Bob")
        try await createUserDocument(uid: testUser3Uid, displayName: "Charlie")

        // When: Create group
        let participantIds = [testUser1Uid!, testUser2Uid!, testUser3Uid!]
        let conversationId = try await conversationService.createGroupConversation(
            participantIds: participantIds,
            groupName: "Names Test"
        )

        // Then: Participant names should be stored
        let conversation = try await conversationService.getConversation(id: conversationId)

        XCTAssertEqual(conversation.participantNames[testUser1Uid], "Alice")
        XCTAssertEqual(conversation.participantNames[testUser2Uid], "Bob")
        XCTAssertEqual(conversation.participantNames[testUser3Uid], "Charlie")
    }

    func testGroupLastMessageUpdate() async throws {
        // Given: Create group
        try await signIn(email: testUser1Email, password: testUser1Password)

        let participantIds = [testUser1Uid!, testUser2Uid!, testUser3Uid!]
        let conversationId = try await conversationService.createGroupConversation(
            participantIds: participantIds,
            groupName: "Last Message Test"
        )

        // When: Send a message
        let messageText = "This is the last message"
        try await messageService.sendMessage(
            conversationId: conversationId,
            text: messageText,
            senderName: "User 1",
            senderPhotoURL: nil
        )

        try await Task.sleep(nanoseconds: 500_000_000)

        // Update last message manually (normally done by trigger)
        let messages = messageService.messages
        if let lastMessage = messages.last {
            try await conversationService.updateLastMessage(
                conversationId: conversationId,
                message: lastMessage
            )
        }

        try await Task.sleep(nanoseconds: 300_000_000)

        // Then: Conversation should have updated last message
        let conversation = try await conversationService.getConversation(id: conversationId)
        XCTAssertEqual(conversation.lastMessage, messageText)
        XCTAssertEqual(conversation.lastMessageSenderId, testUser1Uid)
    }

    // MARK: - Helper Methods

    private func createUserDocument(uid: String, displayName: String) async throws {
        let user = User(
            id: uid,
            displayName: displayName,
            photoURL: nil,
            phoneNumber: nil,
            isOnline: false,
            lastSeen: Date(),
            fcmToken: nil,
            createdAt: Date()
        )

        try firestore
            .collection(Constants.Collections.users)
            .document(uid)
            .setData(from: user)
    }
}
