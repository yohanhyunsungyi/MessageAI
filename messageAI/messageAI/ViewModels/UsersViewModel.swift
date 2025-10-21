//
//  UsersViewModel.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import Combine

/// ViewModel for managing users list state
@MainActor
class UsersViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var users: [User] = []
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Private Properties

    private let userService: UserService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Filtered users based on search query
    var filteredUsers: [User] {
        if searchQuery.isEmpty {
            return users
        } else {
            return userService.searchUsers(query: searchQuery)
        }
    }

    // MARK: - Initialization

    init(userService: UserService? = nil) {
        self.userService = userService ?? UserService()

        // Observe users from service
        self.userService.$allUsers
            .receive(on: DispatchQueue.main)
            .assign(to: &$users)

        // Observe loading state
        self.userService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        // Observe errors
        self.userService.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.errorMessage = errorMessage
                    self?.showError = true
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - User Actions

    /// Load all users
    func loadUsers() {
        Task {
            do {
                try await userService.fetchAllUsers()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Start real-time listening for users
    func startListening() {
        userService.startListening()
    }

    /// Stop real-time listening
    func stopListening() {
        userService.stopListening()
    }

    /// Refresh users list
    func refresh() async {
        do {
            try await userService.fetchAllUsers()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Helper Methods

    /// Check if user is online
    func isUserOnline(_ userId: String) -> Bool {
        return userService.isUserOnline(userId)
    }

    /// Get user's last seen date
    func getUserLastSeen(_ userId: String) -> Date? {
        return userService.getUserLastSeen(userId)
    }

    /// Get last seen string for display
    func getLastSeenString(for userId: String) -> String {
        guard let lastSeen = getUserLastSeen(userId) else {
            return "Last seen recently"
        }

        return lastSeen.lastSeenString
    }

    /// Dismiss error
    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
