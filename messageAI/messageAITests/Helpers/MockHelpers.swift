//
//  MockHelpers.swift
//  messageAITests
//
//  Created by MessageAI on 10/20/25.
//

import Foundation

/// Mock data and helpers for unit testing
class MockHelpers {

    // MARK: - Mock User Data

    static func mockUser(
        id: String = "user123",
        displayName: String = "Test User",
        email: String = "test@example.com",
        photoURL: String? = nil,
        isOnline: Bool = true
    ) -> [String: Any] {
        return [
            "id": id,
            "displayName": displayName,
            "email": email,
            "photoURL": photoURL as Any,
            "isOnline": isOnline,
            "lastSeen": Date(),
            "fcmToken": "mock_fcm_token",
            "createdAt": Date()
        ]
    }

    // MARK: - Mock Message Data

    static func mockMessage(
        id: String = "msg123",
        senderId: String = "user123",
        senderName: String = "Test User",
        text: String = "Hello, World!",
        timestamp: Date = Date(),
        status: String = "sent"
    ) -> [String: Any] {
        return [
            "id": id,
            "senderId": senderId,
            "senderName": senderName,
            "senderPhotoURL": NSNull(),
            "text": text,
            "timestamp": timestamp,
            "status": status,
            "readBy": [:] as [String: Date],
            "deliveredTo": [:] as [String: Date],
            "localId": NSNull()
        ]
    }

    // MARK: - Mock Conversation Data

    static func mockConversation(
        id: String = "conv123",
        participantIds: [String] = ["user123", "user456"],
        type: String = "oneOnOne",
        lastMessage: String? = "Hello!",
        lastMessageTimestamp: Date? = Date()
    ) -> [String: Any] {
        return [
            "id": id,
            "participantIds": participantIds,
            "participantNames": [
                "user123": "Test User 1",
                "user456": "Test User 2"
            ],
            "participantPhotos": [:] as [String: String?],
            "lastMessage": lastMessage ?? NSNull(),
            "lastMessageTimestamp": lastMessageTimestamp ?? NSNull(),
            "lastMessageSenderId": participantIds.first ?? NSNull(),
            "type": type,
            "groupName": NSNull(),
            "createdAt": Date(),
            "createdBy": participantIds.first ?? ""
        ]
    }

    // MARK: - Mock Group Conversation Data

    static func mockGroupConversation(
        id: String = "group123",
        participantIds: [String] = ["user123", "user456", "user789"],
        groupName: String = "Test Group",
        lastMessage: String? = "Group message"
    ) -> [String: Any] {
        return [
            "id": id,
            "participantIds": participantIds,
            "participantNames": [
                "user123": "Test User 1",
                "user456": "Test User 2",
                "user789": "Test User 3"
            ],
            "participantPhotos": [:] as [String: String?],
            "lastMessage": lastMessage as Any,
            "lastMessageTimestamp": Date(),
            "lastMessageSenderId": participantIds.first as Any,
            "type": "group",
            "groupName": groupName,
            "createdAt": Date(),
            "createdBy": participantIds.first ?? ""
        ]
    }

    // MARK: - Test Credentials

    static let testEmail1 = "test1@messageai.com"
    static let testEmail2 = "test2@messageai.com"
    static let testEmail3 = "test3@messageai.com"
    static let testPassword = "TestPassword123!"

    // MARK: - Helper Methods

    /// Generate a unique test email
    static func uniqueTestEmail() -> String {
        return "test_\(UUID().uuidString.prefix(8))@messageai.com"
    }

    /// Generate a unique test user ID
    static func uniqueUserId() -> String {
        return "user_\(UUID().uuidString)"
    }

    /// Generate a unique conversation ID
    static func uniqueConversationId() -> String {
        return "conv_\(UUID().uuidString)"
    }

    /// Generate a unique message ID
    static func uniqueMessageId() -> String {
        return "msg_\(UUID().uuidString)"
    }

    /// Create a delay for async testing
    static func wait(seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - XCTestCase Extensions

import XCTest

extension XCTestCase {
    /// Assert that a value is not nil and return it
    func XCTUnwrapAsync<T>(
        _ expression: @autoclosure () throws -> T?,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T {
        return try XCTUnwrap(try expression(), message, file: file, line: line)
    }
}
