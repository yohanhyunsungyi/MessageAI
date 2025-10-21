//
//  PresenceTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
import FirebaseFirestore
@testable import messageAI

@MainActor
final class PresenceTests: FirebaseIntegrationTestCase {
    var presenceService: PresenceService!
    var userService: UserService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        presenceService = PresenceService()
        userService = UserService()
    }

    override func tearDownWithError() throws {
        presenceService.stopListeningToAll()
        presenceService = nil
        userService = nil
        try super.tearDownWithError()
    }

    // MARK: - Set Online Tests

    func testSetOnline_UpdatesUserDocument() async throws {
        // Given
        let userId = "testUser\(UUID().uuidString)"
        try await createTestUser(userId: userId, displayName: "Test User")

        // When
        try await presenceService.setOnline(userId: userId)

        // Wait a bit for Firestore to propagate
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then
        let document = try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .getDocument()

        XCTAssertTrue(document.exists, "User document should exist")

        let data = try XCTUnwrap(document.data(), "Document data should not be nil")
        let isOnline = try XCTUnwrap(data["isOnline"] as? Bool, "isOnline should be a Bool")

        XCTAssertTrue(isOnline, "User should be online")
        XCTAssertNotNil(data["lastSeen"], "lastSeen should be updated")

        // Check local state
        XCTAssertTrue(presenceService.onlineUsers.contains(userId), "User should be in onlineUsers set")
        XCTAssertEqual(presenceService.presenceStates[userId], true, "User should be marked as online locally")

        // Cleanup
        try await deleteTestUser(userId: userId)
    }

    // MARK: - Set Offline Tests

    func testSetOffline_UpdatesUserDocument() async throws {
        // Given
        let userId = "testUser\(UUID().uuidString)"
        try await createTestUser(userId: userId, displayName: "Test User", isOnline: true)

        // When
        try await presenceService.setOffline(userId: userId)

        // Wait a bit for Firestore to propagate
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then
        let document = try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .getDocument()

        XCTAssertTrue(document.exists, "User document should exist")

        let data = try XCTUnwrap(document.data(), "Document data should not be nil")
        let isOnline = try XCTUnwrap(data["isOnline"] as? Bool, "isOnline should be a Bool")

        XCTAssertFalse(isOnline, "User should be offline")
        XCTAssertNotNil(data["lastSeen"], "lastSeen should be updated")

        // Check local state
        XCTAssertFalse(presenceService.onlineUsers.contains(userId), "User should not be in onlineUsers set")
        XCTAssertEqual(presenceService.presenceStates[userId], false, "User should be marked as offline locally")

        // Cleanup
        try await deleteTestUser(userId: userId)
    }

    // MARK: - Update Presence Tests

    func testUpdatePresence_SetOnline() async throws {
        // Given
        let userId = "testUser\(UUID().uuidString)"
        try await createTestUser(userId: userId, displayName: "Test User", isOnline: false)

        // When
        try await presenceService.updatePresence(userId: userId, isOnline: true)

        // Wait a bit for Firestore to propagate
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then
        let document = try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .getDocument()

        let data = try XCTUnwrap(document.data())
        let isOnline = try XCTUnwrap(data["isOnline"] as? Bool)

        XCTAssertTrue(isOnline, "User should be online")

        // Cleanup
        try await deleteTestUser(userId: userId)
    }

    func testUpdatePresence_SetOffline() async throws {
        // Given
        let userId = "testUser\(UUID().uuidString)"
        try await createTestUser(userId: userId, displayName: "Test User", isOnline: true)

        // When
        try await presenceService.updatePresence(userId: userId, isOnline: false)

        // Wait a bit for Firestore to propagate
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then
        let document = try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .getDocument()

        let data = try XCTUnwrap(document.data())
        let isOnline = try XCTUnwrap(data["isOnline"] as? Bool)

        XCTAssertFalse(isOnline, "User should be offline")

        // Cleanup
        try await deleteTestUser(userId: userId)
    }

    // MARK: - Last Seen Tests

    func testGetLastSeen_ReturnsCorrectDate() async throws {
        // Given
        let userId = "testUser\(UUID().uuidString)"
        let now = Date()
        try await createTestUser(userId: userId, displayName: "Test User", isOnline: false, lastSeen: now)

        // When
        let lastSeen = try await presenceService.getLastSeen(userId: userId)

        // Then
        XCTAssertNotNil(lastSeen, "Last seen should not be nil")

        // Check if the dates are within 2 seconds of each other (to account for rounding)
        if let lastSeen = lastSeen {
            let timeDifference = abs(lastSeen.timeIntervalSince(now))
            XCTAssertLessThan(timeDifference, 2.0, "Last seen should be within 2 seconds of the set time")
        }

        // Cleanup
        try await deleteTestUser(userId: userId)
    }

    func testGetLastSeen_NonExistentUser() async throws {
        // Given
        let userId = "nonExistentUser\(UUID().uuidString)"

        // When/Then - should not crash
        do {
            let lastSeen = try await presenceService.getLastSeen(userId: userId)
            XCTAssertNil(lastSeen, "Last seen should be nil for non-existent user")
        } catch {
            // It's okay if this throws an error
            XCTAssertTrue(true, "Getting last seen for non-existent user may throw")
        }
    }

    // MARK: - Real-time Listener Tests

    func testPresenceListener_DetectsOnlineChange() async throws {
        // Given
        let userId = "testUser\(UUID().uuidString)"
        try await createTestUser(userId: userId, displayName: "Test User", isOnline: false)

        let expectation = XCTestExpectation(description: "Presence listener detects online change")

        // Start listening
        presenceService.startListening(userId: userId)

        // Give listener time to attach
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // When - update presence via Firestore directly
        try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .updateData([
                "isOnline": true,
                "lastSeen": Timestamp(date: Date())
            ])

        // Wait for listener to detect change
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Then
        if presenceService.isUserOnline(userId) {
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertTrue(presenceService.onlineUsers.contains(userId), "User should be in online users set")
        XCTAssertEqual(presenceService.presenceStates[userId], true, "User should be marked as online")

        // Cleanup
        presenceService.stopListening(userId: userId)
        try await deleteTestUser(userId: userId)
    }

    func testPresenceListener_DetectsOfflineChange() async throws {
        // Given
        let userId = "testUser\(UUID().uuidString)"
        try await createTestUser(userId: userId, displayName: "Test User", isOnline: true)

        let expectation = XCTestExpectation(description: "Presence listener detects offline change")

        // Start listening
        presenceService.startListening(userId: userId)

        // Give listener time to attach
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // When - update presence via Firestore directly
        try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .updateData([
                "isOnline": false,
                "lastSeen": Timestamp(date: Date())
            ])

        // Wait for listener to detect change
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Then
        if !presenceService.isUserOnline(userId) {
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertFalse(presenceService.onlineUsers.contains(userId), "User should not be in online users set")
        XCTAssertEqual(presenceService.presenceStates[userId], false, "User should be marked as offline")

        // Cleanup
        presenceService.stopListening(userId: userId)
        try await deleteTestUser(userId: userId)
    }

    // MARK: - Multiple Users Tests

    func testPresenceListener_MultipleUsers() async throws {
        // Given
        let userId1 = "testUser1\(UUID().uuidString)"
        let userId2 = "testUser2\(UUID().uuidString)"
        let userId3 = "testUser3\(UUID().uuidString)"

        try await createTestUser(userId: userId1, displayName: "User 1", isOnline: true)
        try await createTestUser(userId: userId2, displayName: "User 2", isOnline: false)
        try await createTestUser(userId: userId3, displayName: "User 3", isOnline: true)

        // When
        presenceService.startListening(userIds: [userId1, userId2, userId3])

        // Give listeners time to attach
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then
        XCTAssertTrue(presenceService.isUserOnline(userId1), "User 1 should be online")
        XCTAssertFalse(presenceService.isUserOnline(userId2), "User 2 should be offline")
        XCTAssertTrue(presenceService.isUserOnline(userId3), "User 3 should be online")

        // Cleanup
        presenceService.stopListeningToAll()
        try await deleteTestUser(userId: userId1)
        try await deleteTestUser(userId: userId2)
        try await deleteTestUser(userId: userId3)
    }

    // MARK: - Performance Tests

    func testPresenceServicePerformance_SetOnline() async throws {
        let userId = "testUser\(UUID().uuidString)"
        try await createTestUser(userId: userId, displayName: "Test User")

        measure {
            Task {
                do {
                    try await presenceService.setOnline(userId: userId)
                } catch {
                    XCTFail("Failed to set user online: \(error)")
                }
            }
        }

        // Cleanup
        try await deleteTestUser(userId: userId)
    }

    func testPresenceServicePerformance_SetOffline() async throws {
        let userId = "testUser\(UUID().uuidString)"
        try await createTestUser(userId: userId, displayName: "Test User", isOnline: true)

        measure {
            Task {
                do {
                    try await presenceService.setOffline(userId: userId)
                } catch {
                    XCTFail("Failed to set user offline: \(error)")
                }
            }
        }

        // Cleanup
        try await deleteTestUser(userId: userId)
    }

    // MARK: - Helper Methods

    private func createTestUser(
        userId: String,
        displayName: String,
        isOnline: Bool = false,
        lastSeen: Date = Date()
    ) async throws {
        let userData: [String: Any] = [
            "displayName": displayName,
            "photoURL": "",
            "phoneNumber": "",
            "isOnline": isOnline,
            "lastSeen": Timestamp(date: lastSeen),
            "fcmToken": "",
            "createdAt": Timestamp(date: Date())
        ]

        try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .setData(userData)
    }

    private func deleteTestUser(userId: String) async throws {
        try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .delete()
    }
}
