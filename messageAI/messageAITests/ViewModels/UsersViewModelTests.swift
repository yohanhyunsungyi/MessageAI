//
//  UsersViewModelTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
import Combine
@testable import messageAI

@MainActor
final class UsersViewModelTests: XCTestCase {

    var viewModel: UsersViewModel!
    var mockUserService: MockUserService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        mockUserService = MockUserService()
        viewModel = UsersViewModel(userService: mockUserService)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        cancellables = nil
        viewModel = nil
        mockUserService = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    // MARK: - Load Users Tests

    func testLoadUsersSuccess() async {
        // Given
        let expectedUsers = [
            MockHelpers.createMockUser(id: "1", displayName: "Alice"),
            MockHelpers.createMockUser(id: "2", displayName: "Bob")
        ]
        mockUserService.mockUsers = expectedUsers

        let expectation = XCTestExpectation(description: "Users loaded")

        // When
        viewModel.$users
            .dropFirst()
            .sink { users in
                if users.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.loadUsers()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.users.count, 2)
        XCTAssertEqual(viewModel.users[0].displayName, "Alice")
        XCTAssertEqual(viewModel.users[1].displayName, "Bob")
    }

    func testLoadUsersHandlesError() async {
        // Given
        mockUserService.shouldThrowError = true

        let expectation = XCTestExpectation(description: "Error shown")

        // When
        viewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.loadUsers()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Search Tests

    func testFilteredUsersWithEmptySearch() {
        // Given
        let users = [
            MockHelpers.createMockUser(id: "1", displayName: "Alice"),
            MockHelpers.createMockUser(id: "2", displayName: "Bob")
        ]
        mockUserService.mockUsers = users
        viewModel.users = users

        // When
        viewModel.searchQuery = ""

        // Then
        XCTAssertEqual(viewModel.filteredUsers.count, 2)
    }

    func testFilteredUsersWithSearchQuery() {
        // Given
        let alice = MockHelpers.createMockUser(id: "1", displayName: "Alice")
        let bob = MockHelpers.createMockUser(id: "2", displayName: "Bob")
        let charlie = MockHelpers.createMockUser(id: "3", displayName: "Charlie")
        mockUserService.mockUsers = [alice, bob, charlie]
        viewModel.users = [alice, bob, charlie]

        // When
        viewModel.searchQuery = "ali"
        mockUserService.searchQuery = "ali"

        // Then
        XCTAssertEqual(viewModel.filteredUsers.count, 1)
        XCTAssertEqual(viewModel.filteredUsers.first?.displayName, "Alice")
    }

    func testFilteredUsersUpdatesWithSearchQuery() {
        // Given
        let users = [
            MockHelpers.createMockUser(id: "1", displayName: "Alice"),
            MockHelpers.createMockUser(id: "2", displayName: "Bob"),
            MockHelpers.createMockUser(id: "3", displayName: "Charlie")
        ]
        mockUserService.mockUsers = users
        viewModel.users = users

        // When
        viewModel.searchQuery = "B"
        mockUserService.searchQuery = "B"

        // Then
        XCTAssertEqual(viewModel.filteredUsers.count, 1)
        XCTAssertEqual(viewModel.filteredUsers.first?.displayName, "Bob")
    }

    // MARK: - Refresh Tests

    func testRefreshUpdatesUsers() async {
        // Given
        let initialUsers = [
            MockHelpers.createMockUser(id: "1", displayName: "Alice")
        ]
        mockUserService.mockUsers = initialUsers
        viewModel.users = initialUsers

        let newUsers = [
            MockHelpers.createMockUser(id: "1", displayName: "Alice"),
            MockHelpers.createMockUser(id: "2", displayName: "Bob")
        ]

        let expectation = XCTestExpectation(description: "Users refreshed")

        viewModel.$users
            .dropFirst()
            .sink { users in
                if users.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        mockUserService.mockUsers = newUsers
        await viewModel.refresh()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.users.count, 2)
    }

    // MARK: - Online Status Tests

    func testIsUserOnline() {
        // Given
        let onlineUser = MockHelpers.createMockUser(id: "1", displayName: "Alice", isOnline: true)
        let offlineUser = MockHelpers.createMockUser(id: "2", displayName: "Bob", isOnline: false)
        mockUserService.mockUsers = [onlineUser, offlineUser]
        viewModel.users = [onlineUser, offlineUser]

        // When
        let aliceOnline = viewModel.isUserOnline("1")
        let bobOnline = viewModel.isUserOnline("2")

        // Then
        XCTAssertTrue(aliceOnline)
        XCTAssertFalse(bobOnline)
    }

    func testGetUserLastSeen() {
        // Given
        let lastSeen = Date()
        let user = MockHelpers.createMockUser(id: "1", displayName: "Alice", lastSeen: lastSeen)
        mockUserService.mockUsers = [user]
        viewModel.users = [user]

        // When
        let retrievedLastSeen = viewModel.getUserLastSeen("1")

        // Then
        XCTAssertNotNil(retrievedLastSeen)
        XCTAssertEqual(retrievedLastSeen?.timeIntervalSince1970, lastSeen.timeIntervalSince1970, accuracy: 1)
    }

    func testGetLastSeenString() {
        // Given
        let lastSeen = Date()
        let user = MockHelpers.createMockUser(id: "1", displayName: "Alice", lastSeen: lastSeen)
        mockUserService.mockUsers = [user]
        viewModel.users = [user]

        // When
        let lastSeenString = viewModel.getLastSeenString(for: "1")

        // Then
        XCTAssertFalse(lastSeenString.isEmpty)
    }

    func testGetLastSeenStringForNonexistentUser() {
        // Given
        viewModel.users = []

        // When
        let lastSeenString = viewModel.getLastSeenString(for: "nonexistent")

        // Then
        XCTAssertEqual(lastSeenString, "Last seen recently")
    }

    // MARK: - Error Handling Tests

    func testDismissError() {
        // Given
        viewModel.showError = true
        viewModel.errorMessage = "Test error"

        // When
        viewModel.dismissError()

        // Then
        XCTAssertFalse(viewModel.showError)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testErrorMessageFromService() async {
        // Given
        mockUserService.shouldThrowError = true
        mockUserService.mockErrorMessage = "Test error from service"

        let expectation = XCTestExpectation(description: "Error propagated")

        viewModel.$errorMessage
            .compactMap { $0 }
            .sink { errorMessage in
                if errorMessage == "Test error from service" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.loadUsers()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.errorMessage, "Test error from service")
    }

    // MARK: - Start/Stop Listening Tests

    func testStartListening() {
        // When
        viewModel.startListening()

        // Then
        XCTAssertTrue(mockUserService.isListening)
    }

    func testStopListening() {
        // Given
        viewModel.startListening()

        // When
        viewModel.stopListening()

        // Then
        XCTAssertFalse(mockUserService.isListening)
    }
}

// MARK: - Mock User Service

@MainActor
class MockUserService: UserService {

    var mockUsers: [User] = []
    var shouldThrowError = false
    var mockErrorMessage: String?
    var isListening = false
    var searchQuery: String = ""

    override func fetchAllUsers() async throws {
        if shouldThrowError {
            self.errorMessage = mockErrorMessage ?? "Mock error"
            throw UserServiceError.fetchFailed
        }

        self.allUsers = mockUsers
    }

    override func searchUsers(query: String) -> [User] {
        guard !query.isEmpty else {
            return mockUsers
        }

        let lowercasedQuery = query.lowercased()
        return mockUsers.filter { user in
            user.displayName.lowercased().contains(lowercasedQuery)
        }
    }

    override func startListening() {
        isListening = true
        self.allUsers = mockUsers
    }

    override func stopListening() {
        isListening = false
    }

    override func isUserOnline(_ userId: String) -> Bool {
        return mockUsers.first(where: { $0.id == userId })?.isOnline ?? false
    }

    override func getUserLastSeen(_ userId: String) -> Date? {
        return mockUsers.first(where: { $0.id == userId })?.lastSeen
    }
}
