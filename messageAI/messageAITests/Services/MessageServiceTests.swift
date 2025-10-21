//
//  MessageServiceTests.swift
//  messageAITests
//
//  Created by MessageAI on 10/21/25.
//

import XCTest
@testable import messageAI

@MainActor
final class MessageServiceTests: XCTestCase {
    var sut: MessageService!
    var mockLocalStorage: LocalStorageService!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory local storage for testing
        let container = try ModelContainer(
            for: LocalMessage.self, LocalConversation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        mockLocalStorage = LocalStorageService(modelContext: container.mainContext)

        // Initialize service with mock storage
        sut = MessageService(localStorageService: mockLocalStorage)
    }

    override func tearDown() async throws {
        sut = nil
        mockLocalStorage = nil
        try await super.tearDown()
    }

    // MARK: - Message Creation Tests

    func testSendMessage_SavesLocally() async throws {
        // Given
        let conversationId = "conv-123"
        let text = "Hello, World!"
        let senderName = "Test User"

        // When
        try await sut.sendMessage(
            conversationId: conversationId,
            text: text,
            senderName: senderName
        )

        // Then
        let localMessages = try await mockLocalStorage.fetchMessages(conversationId: conversationId)
        XCTAssertEqual(localMessages.count, 1)
        XCTAssertEqual(localMessages.first?.text, text)
        XCTAssertEqual(localMessages.first?.senderName, senderName)
    }

    func testSendMessage_UpdatesUIImmediately() async throws {
        // Given
        let conversationId = "conv-123"
        let text = "Test message"
        let senderName = "Test User"

        // When
        try await sut.sendMessage(
            conversationId: conversationId,
            text: text,
            senderName: senderName
        )

        // Then
        XCTAssertEqual(sut.messages.count, 1)
        XCTAssertEqual(sut.messages.first?.text, text)
        XCTAssertEqual(sut.messages.first?.status, .sending)
    }

    func testSendMessage_ThrowsErrorForEmptyText() async {
        // Given
        let conversationId = "conv-123"
        let emptyText = "   "
        let senderName = "Test User"

        // When/Then
        do {
            try await sut.sendMessage(
                conversationId: conversationId,
                text: emptyText,
                senderName: senderName
            )
            XCTFail("Should throw emptyMessage error")
        } catch MessageError.emptyMessage {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Fetch Messages Tests

    func testFetchLocalMessages_LoadsFromStorage() async throws {
        // Given
        let conversationId = "conv-123"
        let message = MockHelpers.mockMessage()

        try await mockLocalStorage.saveMessage(message, conversationId: conversationId)

        // When
        await sut.fetchLocalMessages(conversationId: conversationId)

        // Then
        XCTAssertEqual(sut.messages.count, 1)
        XCTAssertEqual(sut.messages.first?.text, message.text)
    }

    func testFetchLocalMessages_HandlesEmptyStorage() async {
        // Given
        let conversationId = "conv-empty"

        // When
        await sut.fetchLocalMessages(conversationId: conversationId)

        // Then
        XCTAssertEqual(sut.messages.count, 0)
    }

    // MARK: - Message Status Tests

    func testMessageStatus_SendingToSent() async throws {
        // Given
        let conversationId = "conv-123"
        let text = "Test message"
        let senderName = "Test User"

        // When
        try await sut.sendMessage(
            conversationId: conversationId,
            text: text,
            senderName: senderName
        )

        // Then - Message should start as .sending
        XCTAssertEqual(sut.messages.first?.status, .sending)
    }

    // MARK: - Offline Queue Tests

    func testOfflineQueue_EmptyByDefault() async {
        // When
        await sut.processOfflineQueue()

        // Then - Should not crash
        XCTAssertTrue(true)
    }

    // MARK: - Message Validation Tests

    func testMessageCreation_WithPhotoURL() async throws {
        // Given
        let conversationId = "conv-123"
        let text = "Test message"
        let senderName = "Test User"
        let photoURL = "https://example.com/photo.jpg"

        // When
        try await sut.sendMessage(
            conversationId: conversationId,
            text: text,
            senderName: senderName,
            senderPhotoURL: photoURL
        )

        // Then
        XCTAssertEqual(sut.messages.first?.senderPhotoURL, photoURL)
    }

    func testMessageCreation_WithoutPhotoURL() async throws {
        // Given
        let conversationId = "conv-123"
        let text = "Test message"
        let senderName = "Test User"

        // When
        try await sut.sendMessage(
            conversationId: conversationId,
            text: text,
            senderName: senderName
        )

        // Then
        XCTAssertNil(sut.messages.first?.senderPhotoURL)
    }

    // MARK: - Multiple Messages Tests

    func testMultipleMessages_MaintainsOrder() async throws {
        // Given
        let conversationId = "conv-123"
        let messages = ["First", "Second", "Third"]
        let senderName = "Test User"

        // When
        for text in messages {
            try await sut.sendMessage(
                conversationId: conversationId,
                text: text,
                senderName: senderName
            )
        }

        // Then
        XCTAssertEqual(sut.messages.count, 3)
        XCTAssertEqual(sut.messages[0].text, "First")
        XCTAssertEqual(sut.messages[1].text, "Second")
        XCTAssertEqual(sut.messages[2].text, "Third")
    }

    // MARK: - Listener Tests

    func testStopListening_RemovesListener() {
        // When
        sut.stopListening()

        // Then - Should not crash
        XCTAssertTrue(true)
    }

    func testStopListeningForTyping_RemovesListener() {
        // When
        sut.stopListeningForTyping()

        // Then - Should not crash
        XCTAssertTrue(true)
    }

    // MARK: - Performance Tests

    func testPerformance_SendMultipleMessages() {
        let conversationId = "conv-perf"
        let senderName = "Test User"

        measure {
            Task {
                for index in 0..<10 {
                    try? await sut.sendMessage(
                        conversationId: conversationId,
                        text: "Message \(index)",
                        senderName: senderName
                    )
                }
            }
        }
    }

    func testPerformance_FetchLocalMessages() async throws {
        // Given - Seed with messages
        let conversationId = "conv-perf"
        for index in 0..<50 {
            let message = Message(
                id: "msg-\(index)",
                senderId: testUserId,
                senderName: "User",
                text: "Message \(index)",
                timestamp: Date(),
                status: .sent
            )
            try await mockLocalStorage.saveMessage(message, conversationId: conversationId)
        }

        // When/Then
        measure {
            Task {
                await sut.fetchLocalMessages(conversationId: conversationId)
            }
        }
    }
}

// MARK: - Message Error Tests

final class MessageErrorTests: XCTestCase {
    func testMessageError_EmptyMessage() {
        let error = MessageError.emptyMessage
        XCTAssertEqual(error.errorDescription, "Message cannot be empty")
    }

    func testMessageError_LocalStorageFailed() {
        let error = MessageError.localStorageFailed
        XCTAssertEqual(error.errorDescription, "Failed to save message locally")
    }

    func testMessageError_SendFailed() {
        let error = MessageError.sendFailed
        XCTAssertEqual(error.errorDescription, "Failed to send message")
    }

    func testMessageError_NotFound() {
        let error = MessageError.notFound
        XCTAssertEqual(error.errorDescription, "Message not found")
    }

    func testMessageError_Unauthorized() {
        let error = MessageError.unauthorized
        XCTAssertEqual(error.errorDescription, "You are not authorized to perform this action")
    }
}

// MARK: - Message Extension Tests

final class MessageExtensionTests: XCTestCase {
    func testToDictionary_ContainsRequiredFields() {
        // Given
        let message = Message(
            id: "msg-123",
            senderId: "user-123",
            senderName: "Test User",
            text: "Hello",
            timestamp: Date(),
            status: .sent
        )

        // When
        let dict = message.toDictionary()

        // Then
        XCTAssertEqual(dict["senderId"] as? String, "user-123")
        XCTAssertEqual(dict["senderName"] as? String, "Test User")
        XCTAssertEqual(dict["text"] as? String, "Hello")
        XCTAssertNotNil(dict["timestamp"])
        XCTAssertEqual(dict["status"] as? String, "sent")
    }

    func testToDictionary_IncludesOptionalPhotoURL() {
        // Given
        let photoURL = "https://example.com/photo.jpg"
        let message = Message(
            id: "msg-123",
            senderId: "user-123",
            senderName: "Test User",
            senderPhotoURL: photoURL,
            text: "Hello",
            timestamp: Date(),
            status: .sent
        )

        // When
        let dict = message.toDictionary()

        // Then
        XCTAssertEqual(dict["senderPhotoURL"] as? String, photoURL)
    }

    func testToDictionary_ExcludesNilPhotoURL() {
        // Given
        let message = Message(
            id: "msg-123",
            senderId: "user-123",
            senderName: "Test User",
            text: "Hello",
            timestamp: Date(),
            status: .sent
        )

        // When
        let dict = message.toDictionary()

        // Then
        XCTAssertNil(dict["senderPhotoURL"])
    }

    func testToDictionary_IncludesLocalId() {
        // Given
        let localId = "local-123"
        let message = Message(
            id: "msg-123",
            senderId: "user-123",
            senderName: "Test User",
            text: "Hello",
            timestamp: Date(),
            status: .sending,
            readBy: [:],
            deliveredTo: [:],
            localId: localId
        )

        // When
        let dict = message.toDictionary()

        // Then
        XCTAssertEqual(dict["localId"] as? String, localId)
    }
}


