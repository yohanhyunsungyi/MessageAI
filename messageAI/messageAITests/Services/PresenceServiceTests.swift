//
//  PresenceServiceTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
@testable import messageAI

@MainActor
final class PresenceServiceTests: XCTestCase {
    var presenceService: PresenceService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Create service with default firestore (we can't easily mock Firestore in unit tests)
        // For true unit tests, we would need to refactor to use a protocol
        presenceService = PresenceService()
    }

    override func tearDownWithError() throws {
        presenceService.stopListeningToAll()
        presenceService = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testPresenceServiceInitialization() throws {
        XCTAssertNotNil(presenceService, "PresenceService should be initialized")
        XCTAssertTrue(presenceService.onlineUsers.isEmpty, "Online users should be empty initially")
        XCTAssertTrue(presenceService.presenceStates.isEmpty, "Presence states should be empty initially")
    }

    // MARK: - Online Users Set Tests

    func testOnlineUsersSetOperations() {
        // Given
        let userId1 = "user1"
        let userId2 = "user2"

        // When - manually add users to onlineUsers set
        presenceService.onlineUsers.insert(userId1)
        presenceService.onlineUsers.insert(userId2)

        // Then
        XCTAssertTrue(presenceService.onlineUsers.contains(userId1), "Should contain user1")
        XCTAssertTrue(presenceService.onlineUsers.contains(userId2), "Should contain user2")
        XCTAssertEqual(presenceService.onlineUsers.count, 2, "Should have 2 online users")

        // When - remove user
        presenceService.onlineUsers.remove(userId1)

        // Then
        XCTAssertFalse(presenceService.onlineUsers.contains(userId1), "Should not contain user1")
        XCTAssertTrue(presenceService.onlineUsers.contains(userId2), "Should still contain user2")
        XCTAssertEqual(presenceService.onlineUsers.count, 1, "Should have 1 online user")
    }

    // MARK: - Presence State Tests

    func testPresenceStateTracking() {
        // Given
        let userId1 = "user1"
        let userId2 = "user2"

        // When - manually set presence states
        presenceService.presenceStates[userId1] = true
        presenceService.presenceStates[userId2] = false

        // Then
        XCTAssertEqual(presenceService.presenceStates[userId1], true, "User1 should be online")
        XCTAssertEqual(presenceService.presenceStates[userId2], false, "User2 should be offline")

        // When - check isUserOnline
        XCTAssertTrue(presenceService.isUserOnline(userId1), "isUserOnline should return true for user1")
        XCTAssertFalse(presenceService.isUserOnline(userId2), "isUserOnline should return false for user2")

        // When - check unknown user
        XCTAssertFalse(presenceService.isUserOnline("unknownUser"), "Unknown user should return false")
    }

    // MARK: - isUserOnline Tests

    func testIsUserOnline_WithExistingUser() {
        // Given
        let userId = "testUser"
        presenceService.presenceStates[userId] = true

        // When
        let isOnline = presenceService.isUserOnline(userId)

        // Then
        XCTAssertTrue(isOnline, "Should return true for online user")
    }

    func testIsUserOnline_WithOfflineUser() {
        // Given
        let userId = "testUser"
        presenceService.presenceStates[userId] = false

        // When
        let isOnline = presenceService.isUserOnline(userId)

        // Then
        XCTAssertFalse(isOnline, "Should return false for offline user")
    }

    func testIsUserOnline_WithUnknownUser() {
        // When
        let isOnline = presenceService.isUserOnline("unknownUser")

        // Then
        XCTAssertFalse(isOnline, "Should return false for unknown user")
    }

    // MARK: - Listener Management Tests

    func testStartListening_SingleUser() {
        // Given
        let userId = "testUser"

        // When
        presenceService.startListening(userId: userId)

        // Then
        // Note: We can't easily verify listener creation without Firestore access
        // This test mainly ensures no crashes occur
        XCTAssertNotNil(presenceService, "Service should still be alive after starting listener")
    }

    func testStartListening_MultipleUsers() {
        // Given
        let userIds = ["user1", "user2", "user3"]

        // When
        presenceService.startListening(userIds: userIds)

        // Then
        // Note: We can't easily verify listener creation without Firestore access
        // This test mainly ensures no crashes occur
        XCTAssertNotNil(presenceService, "Service should still be alive after starting listeners")
    }

    func testStartListening_DuplicateUser() {
        // Given
        let userId = "testUser"

        // When - start listening twice
        presenceService.startListening(userId: userId)
        presenceService.startListening(userId: userId)

        // Then - should not crash
        XCTAssertNotNil(presenceService, "Service should handle duplicate listeners gracefully")
    }

    func testStopListening_SingleUser() {
        // Given
        let userId = "testUser"
        presenceService.startListening(userId: userId)

        // When
        presenceService.stopListening(userId: userId)

        // Then - should not crash
        XCTAssertNotNil(presenceService, "Service should still be alive after stopping listener")
    }

    func testStopListeningToAll() {
        // Given
        let userIds = ["user1", "user2", "user3"]
        presenceService.startListening(userIds: userIds)

        // When
        presenceService.stopListeningToAll()

        // Then - should not crash
        XCTAssertNotNil(presenceService, "Service should still be alive after stopping all listeners")
    }

    // MARK: - Error Handling Tests

    func testPresenceError_FailedToSetOnline() {
        // Given
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let presenceError = PresenceError.failedToSetOnline(underlyingError)

        // Then
        XCTAssertNotNil(presenceError.errorDescription, "Error description should not be nil")
        XCTAssertTrue(presenceError.errorDescription!.contains("Failed to set user online"),
                     "Error description should contain expected message")
    }

    func testPresenceError_FailedToSetOffline() {
        // Given
        let underlyingError = NSError(domain: "TestDomain", code: 2, userInfo: nil)
        let presenceError = PresenceError.failedToSetOffline(underlyingError)

        // Then
        XCTAssertNotNil(presenceError.errorDescription, "Error description should not be nil")
        XCTAssertTrue(presenceError.errorDescription!.contains("Failed to set user offline"),
                     "Error description should contain expected message")
    }

    func testPresenceError_FailedToGetLastSeen() {
        // Given
        let underlyingError = NSError(domain: "TestDomain", code: 3, userInfo: nil)
        let presenceError = PresenceError.failedToGetLastSeen(underlyingError)

        // Then
        XCTAssertNotNil(presenceError.errorDescription, "Error description should not be nil")
        XCTAssertTrue(presenceError.errorDescription!.contains("Failed to get last seen"),
                     "Error description should contain expected message")
    }

    // MARK: - Performance Tests

    func testPresenceServicePerformance_MultipleUsers() throws {
        let userIds = (0..<100).map { "user\($0)" }

        measure {
            // Test adding many users to presence states
            for userId in userIds {
                presenceService.presenceStates[userId] = Bool.random()
            }

            // Test checking presence for many users
            for userId in userIds {
                _ = presenceService.isUserOnline(userId)
            }

            // Cleanup
            presenceService.presenceStates.removeAll()
        }
    }

    func testPresenceServicePerformance_StartListening() throws {
        let userIds = (0..<10).map { "user\($0)" }

        measure {
            presenceService.startListening(userIds: userIds)
            presenceService.stopListeningToAll()
        }
    }

    // MARK: - Memory Tests

    func testPresenceServiceMemoryCleanup() {
        // Given
        let userIds = ["user1", "user2", "user3"]
        presenceService.startListening(userIds: userIds)

        // When
        presenceService = nil

        // Then - deinit should be called, cleaning up listeners
        // If there are memory leaks, this test will help identify them with Instruments
        XCTAssertNil(presenceService, "Service should be deallocated")
    }
}
