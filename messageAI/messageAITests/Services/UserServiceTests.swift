//
//  UserServiceTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
@testable import messageAI

@MainActor
final class UserServiceTests: XCTestCase {

    var userService: UserService!

    override func setUp() async throws {
        try await super.setUp()
        userService = UserService()
    }

    override func tearDown() async throws {
        userService = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(userService)
        XCTAssertTrue(userService.allUsers.isEmpty)
        XCTAssertFalse(userService.isLoading)
        XCTAssertNil(userService.errorMessage)
    }

    // MARK: - Search Tests

    func testSearchUsersWithEmptyQuery() {
        // Given
        let user1 = MockHelpers.createMockUser(id: "1", displayName: "Alice")
        let user2 = MockHelpers.createMockUser(id: "2", displayName: "Bob")
        userService.allUsers = [user1, user2]

        // When
        let results = userService.searchUsers(query: "")

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results, [user1, user2])
    }

    func testSearchUsersWithMatchingQuery() {
        // Given
        let alice = MockHelpers.createMockUser(id: "1", displayName: "Alice")
        let bob = MockHelpers.createMockUser(id: "2", displayName: "Bob")
        let charlie = MockHelpers.createMockUser(id: "3", displayName: "Charlie")
        userService.allUsers = [alice, bob, charlie]

        // When
        let results = userService.searchUsers(query: "ali")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, "1")
        XCTAssertEqual(results.first?.displayName, "Alice")
    }

    func testSearchUsersWithNonMatchingQuery() {
        // Given
        let alice = MockHelpers.createMockUser(id: "1", displayName: "Alice")
        let bob = MockHelpers.createMockUser(id: "2", displayName: "Bob")
        userService.allUsers = [alice, bob]

        // When
        let results = userService.searchUsers(query: "xyz")

        // Then
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchUsersIsCaseInsensitive() {
        // Given
        let alice = MockHelpers.createMockUser(id: "1", displayName: "Alice")
        let bob = MockHelpers.createMockUser(id: "2", displayName: "Bob")
        userService.allUsers = [alice, bob]

        // When
        let results1 = userService.searchUsers(query: "ALICE")
        let results2 = userService.searchUsers(query: "alice")
        let results3 = userService.searchUsers(query: "AlIcE")

        // Then
        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results2.count, 1)
        XCTAssertEqual(results3.count, 1)
    }

    func testSearchUsersWithPartialMatch() {
        // Given
        let alice = MockHelpers.createMockUser(id: "1", displayName: "Alice Smith")
        let bob = MockHelpers.createMockUser(id: "2", displayName: "Bob Johnson")
        userService.allUsers = [alice, bob]

        // When
        let results1 = userService.searchUsers(query: "Smith")
        let results2 = userService.searchUsers(query: "Johns")

        // Then
        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results1.first?.displayName, "Alice Smith")
        XCTAssertEqual(results2.count, 1)
        XCTAssertEqual(results2.first?.displayName, "Bob Johnson")
    }

    // MARK: - Online Status Tests

    func testIsUserOnlineWhenUserIsOnline() {
        // Given
        let onlineUser = MockHelpers.createMockUser(id: "1", displayName: "Alice", isOnline: true)
        userService.allUsers = [onlineUser]

        // When
        let isOnline = userService.isUserOnline("1")

        // Then
        XCTAssertTrue(isOnline)
    }

    func testIsUserOnlineWhenUserIsOffline() {
        // Given
        let offlineUser = MockHelpers.createMockUser(id: "1", displayName: "Alice", isOnline: false)
        userService.allUsers = [offlineUser]

        // When
        let isOnline = userService.isUserOnline("1")

        // Then
        XCTAssertFalse(isOnline)
    }

    func testIsUserOnlineWhenUserDoesNotExist() {
        // Given
        userService.allUsers = []

        // When
        let isOnline = userService.isUserOnline("nonexistent")

        // Then
        XCTAssertFalse(isOnline)
    }

    // MARK: - Last Seen Tests

    func testGetUserLastSeenWhenUserExists() {
        // Given
        let lastSeen = Date()
        let user = MockHelpers.createMockUser(id: "1", displayName: "Alice", lastSeen: lastSeen)
        userService.allUsers = [user]

        // When
        let retrievedLastSeen = userService.getUserLastSeen("1")

        // Then
        XCTAssertNotNil(retrievedLastSeen)
        XCTAssertEqual(retrievedLastSeen?.timeIntervalSince1970, lastSeen.timeIntervalSince1970, accuracy: 1)
    }

    func testGetUserLastSeenWhenUserDoesNotExist() {
        // Given
        userService.allUsers = []

        // When
        let lastSeen = userService.getUserLastSeen("nonexistent")

        // Then
        XCTAssertNil(lastSeen)
    }

    // MARK: - Array Chunking Tests (Internal Extension)

    func testArrayChunking() {
        // Given
        let numbers = Array(1...25)

        // When
        let chunks = numbers.chunked(into: 10)

        // Then
        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0].count, 10)
        XCTAssertEqual(chunks[1].count, 10)
        XCTAssertEqual(chunks[2].count, 5)
        XCTAssertEqual(chunks[0], Array(1...10))
        XCTAssertEqual(chunks[1], Array(11...20))
        XCTAssertEqual(chunks[2], Array(21...25))
    }

    func testArrayChunkingWithSingleChunk() {
        // Given
        let numbers = Array(1...5)

        // When
        let chunks = numbers.chunked(into: 10)

        // Then
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0].count, 5)
    }

    func testArrayChunkingWithExactChunks() {
        // Given
        let numbers = Array(1...20)

        // When
        let chunks = numbers.chunked(into: 10)

        // Then
        XCTAssertEqual(chunks.count, 2)
        XCTAssertEqual(chunks[0].count, 10)
        XCTAssertEqual(chunks[1].count, 10)
    }

    // MARK: - Performance Tests

    func testSearchPerformance() {
        // Given
        let users = (1...1000).map { index in
            MockHelpers.createMockUser(id: "\(index)", displayName: "User \(index)")
        }
        userService.allUsers = users

        // When/Then
        measure {
            _ = userService.searchUsers(query: "User 500")
        }
    }

    func testFilterUsersPerformance() {
        // Given
        let users = (1...1000).map { index in
            MockHelpers.createMockUser(id: "\(index)", displayName: "User \(index)")
        }
        userService.allUsers = users

        // When/Then
        measure {
            _ = userService.searchUsers(query: "User")
        }
    }
}

// MARK: - Helper Extensions

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
