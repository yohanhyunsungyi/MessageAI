//
//  UserFirestoreTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
import FirebaseFirestore
@testable import messageAI

@MainActor
final class UserFirestoreTests: FirebaseIntegrationTestCase {

    var userService: UserService!
    var testUsers: [User] = []

    override func setUp() async throws {
        try await super.setUp()
        userService = UserService()
        testUsers = []
    }

    override func tearDown() async throws {
        // Clean up test users
        for user in testUsers {
            try await deleteUser(userId: user.id)
        }
        testUsers = []
        userService = nil
        try await super.tearDown()
    }

    // MARK: - Fetch Users Tests

    func testFetchAllUsersFromEmptyDatabase() async throws {
        // When
        try await userService.fetchAllUsers()

        // Then
        XCTAssertTrue(userService.allUsers.isEmpty)
        XCTAssertFalse(userService.isLoading)
    }

    func testFetchAllUsersWithMultipleUsers() async throws {
        // Given
        let user1 = try await createTestUser(displayName: "Alice")
        let user2 = try await createTestUser(displayName: "Bob")
        let user3 = try await createTestUser(displayName: "Charlie")
        testUsers = [user1, user2, user3]

        // When
        try await userService.fetchAllUsers()

        // Then
        XCTAssertEqual(userService.allUsers.count, 3)
        XCTAssertTrue(userService.allUsers.contains(where: { $0.displayName == "Alice" }))
        XCTAssertTrue(userService.allUsers.contains(where: { $0.displayName == "Bob" }))
        XCTAssertTrue(userService.allUsers.contains(where: { $0.displayName == "Charlie" }))
    }

    func testFetchAllUsersExcludesCurrentUser() async throws {
        // Given
        let currentUser = try await signInTestUser()
        let otherUser1 = try await createTestUser(displayName: "Alice")
        let otherUser2 = try await createTestUser(displayName: "Bob")
        testUsers = [currentUser, otherUser1, otherUser2]

        // When
        try await userService.fetchAllUsers()

        // Then
        XCTAssertEqual(userService.allUsers.count, 2)
        XCTAssertFalse(userService.allUsers.contains(where: { $0.id == currentUser.id }))
        XCTAssertTrue(userService.allUsers.contains(where: { $0.displayName == "Alice" }))
        XCTAssertTrue(userService.allUsers.contains(where: { $0.displayName == "Bob" }))
    }

    func testFetchAllUsersSortsByDisplayName() async throws {
        // Given
        let charlie = try await createTestUser(displayName: "Charlie")
        let alice = try await createTestUser(displayName: "Alice")
        let bob = try await createTestUser(displayName: "Bob")
        testUsers = [charlie, alice, bob]

        // When
        try await userService.fetchAllUsers()

        // Then
        XCTAssertEqual(userService.allUsers.count, 3)
        XCTAssertEqual(userService.allUsers[0].displayName, "Alice")
        XCTAssertEqual(userService.allUsers[1].displayName, "Bob")
        XCTAssertEqual(userService.allUsers[2].displayName, "Charlie")
    }

    // MARK: - Get User Tests

    func testGetUserByIdWhenUserExists() async throws {
        // Given
        let testUser = try await createTestUser(displayName: "Test User")
        testUsers = [testUser]

        // When
        let retrievedUser = try await userService.getUser(id: testUser.id)

        // Then
        XCTAssertEqual(retrievedUser.id, testUser.id)
        XCTAssertEqual(retrievedUser.displayName, "Test User")
    }

    func testGetUserByIdWhenUserDoesNotExist() async throws {
        // When/Then
        do {
            _ = try await userService.getUser(id: "nonexistent")
            XCTFail("Should throw userNotFound error")
        } catch UserServiceError.userNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Get Multiple Users Tests

    func testGetUsersWithEmptyArray() async throws {
        // When
        let users = try await userService.getUsers(ids: [])

        // Then
        XCTAssertTrue(users.isEmpty)
    }

    func testGetUsersWithSingleId() async throws {
        // Given
        let testUser = try await createTestUser(displayName: "Test User")
        testUsers = [testUser]

        // When
        let users = try await userService.getUsers(ids: [testUser.id])

        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users[0].id, testUser.id)
    }

    func testGetUsersWithMultipleIds() async throws {
        // Given
        let user1 = try await createTestUser(displayName: "User 1")
        let user2 = try await createTestUser(displayName: "User 2")
        let user3 = try await createTestUser(displayName: "User 3")
        testUsers = [user1, user2, user3]

        // When
        let users = try await userService.getUsers(ids: [user1.id, user2.id, user3.id])

        // Then
        XCTAssertEqual(users.count, 3)
    }

    func testGetUsersWithMoreThan10Ids() async throws {
        // Given - Create 15 users (Firestore 'in' query limit is 10)
        var createdUsers: [User] = []
        for index in 1...15 {
            let user = try await createTestUser(displayName: "User \(index)")
            createdUsers.append(user)
        }
        testUsers = createdUsers

        let userIds = createdUsers.map { $0.id }

        // When
        let users = try await userService.getUsers(ids: userIds)

        // Then
        XCTAssertEqual(users.count, 15)
    }

    // MARK: - Update Profile Tests

    func testUpdateProfileDisplayName() async throws {
        // Given
        let testUser = try await createTestUser(displayName: "Old Name")
        testUsers = [testUser]

        // When
        try await userService.updateProfile(
            userId: testUser.id,
            displayName: "New Name",
            photoURL: nil
        )

        // Then
        let updatedUser = try await userService.getUser(id: testUser.id)
        XCTAssertEqual(updatedUser.displayName, "New Name")
    }

    func testUpdateProfilePhotoURL() async throws {
        // Given
        let testUser = try await createTestUser(displayName: "Test User")
        testUsers = [testUser]

        // When
        try await userService.updateProfile(
            userId: testUser.id,
            displayName: nil,
            photoURL: "https://example.com/photo.jpg"
        )

        // Then
        let updatedUser = try await userService.getUser(id: testUser.id)
        XCTAssertEqual(updatedUser.photoURL, "https://example.com/photo.jpg")
    }

    func testUpdateProfileBothFields() async throws {
        // Given
        let testUser = try await createTestUser(displayName: "Old Name")
        testUsers = [testUser]

        // When
        try await userService.updateProfile(
            userId: testUser.id,
            displayName: "New Name",
            photoURL: "https://example.com/photo.jpg"
        )

        // Then
        let updatedUser = try await userService.getUser(id: testUser.id)
        XCTAssertEqual(updatedUser.displayName, "New Name")
        XCTAssertEqual(updatedUser.photoURL, "https://example.com/photo.jpg")
    }

    func testUpdateProfileWithEmptyUpdates() async throws {
        // Given
        let testUser = try await createTestUser(displayName: "Test User")
        testUsers = [testUser]

        // When - Both params nil should do nothing
        try await userService.updateProfile(
            userId: testUser.id,
            displayName: nil,
            photoURL: nil
        )

        // Then - User unchanged
        let updatedUser = try await userService.getUser(id: testUser.id)
        XCTAssertEqual(updatedUser.displayName, "Test User")
    }

    // MARK: - Real-Time Listener Tests

    func testStartListeningReceivesUpdates() async throws {
        // Given
        let currentUser = try await signInTestUser()
        testUsers = [currentUser]

        let expectation = XCTestExpectation(description: "Listener receives user updates")

        // Start listening
        userService.startListening()

        // Wait a bit for listener to be set up
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // When - Add a new user
        let newUser = try await createTestUser(displayName: "New User")
        testUsers.append(newUser)

        // Wait for listener to receive update
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then
        XCTAssertTrue(userService.allUsers.contains(where: { $0.displayName == "New User" }))

        userService.stopListening()
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testStopListeningStopsReceivingUpdates() async throws {
        // Given
        let currentUser = try await signInTestUser()
        testUsers = [currentUser]

        userService.startListening()
        try await Task.sleep(nanoseconds: 500_000_000)

        // When - Stop listening
        userService.stopListening()

        let countBeforeNewUser = userService.allUsers.count

        // Add new user after stopping
        let newUser = try await createTestUser(displayName: "New User")
        testUsers.append(newUser)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Then - Count should not change
        XCTAssertEqual(userService.allUsers.count, countBeforeNewUser)
    }

    // MARK: - Helper Methods

    private func createTestUser(displayName: String) async throws -> User {
        let userId = UUID().uuidString
        let user = User(
            id: userId,
            displayName: displayName,
            photoURL: nil,
            phoneNumber: nil,
            isOnline: false,
            lastSeen: Date(),
            fcmToken: nil,
            createdAt: Date()
        )

        try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .setData(from: user)

        return user
    }

    private func deleteUser(userId: String) async throws {
        try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .delete()
    }

    private func signInTestUser() async throws -> User {
        let userId = try await createTestFirebaseUser(
            email: "testuser@example.com",
            password: "testpass123"
        )

        let user = User(
            id: userId,
            displayName: "Test Current User",
            photoURL: nil,
            phoneNumber: nil,
            isOnline: true,
            lastSeen: Date(),
            fcmToken: nil,
            createdAt: Date()
        )

        try await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .setData(from: user)

        return user
    }
}
