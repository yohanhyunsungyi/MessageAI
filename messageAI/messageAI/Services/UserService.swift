//
//  UserService.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

/// Service responsible for loading and observing app users.
/// Exposes Combine-friendly published state consumed by `UsersViewModel`.
@MainActor
class UserService: ObservableObject {

    // MARK: - Published State

    @Published private(set) var allUsers: [User] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // Presence helpers used by the users list for quick lookup
    @Published private(set) var userPresence: [String: Bool] = [:]
    @Published private(set) var lastSeenDates: [String: Date] = [:]

    // MARK: - Dependencies

    private let firestore: Firestore
    private let auth: Auth
    private var usersListener: ListenerRegistration?

    // MARK: - Initialization

    init(
        firestore: Firestore = FirebaseManager.shared.firestore,
        auth: Auth = FirebaseManager.shared.auth
    ) {
        self.firestore = firestore
        self.auth = auth
    }

    deinit {
        usersListener?.remove()
        usersListener = nil
    }

    // MARK: - Public API

    /// Fetch all users once (excludes the current user).
    func fetchAllUsers() async throws -> [User] {
        guard let currentUserId = auth.currentUser?.uid else {
            throw UserServiceError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await firestore.collection("users").getDocuments()

            let users = snapshot.documents.compactMap { self.decodeUser(from: $0) }
            .filter { $0.id != currentUserId }

            updateState(with: users)
            return users
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Start real-time updates for the users collection.
    func startListening() {
        guard usersListener == nil else { return }
        guard let currentUserId = auth.currentUser?.uid else { return }

        usersListener = firestore.collection("users")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error = error {
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                    print("⚠️ Users listener error: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let users = documents.compactMap { self.decodeUser(from: $0) }
                .filter { $0.id != currentUserId }

                Task { @MainActor in
                    self.updateState(with: users)
                }
            }
    }

    /// Stop listening for user changes.
    func stopListening() {
        usersListener?.remove()
        usersListener = nil
    }

    /// Simple local search (case insensitive) against cached results.
    func searchUsers(query: String) -> [User] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return allUsers }

        let lowercased = trimmedQuery.lowercased()
        return allUsers.filter { user in
            user.displayName.lowercased().contains(lowercased) ||
            (user.phoneNumber?.lowercased().contains(lowercased) ?? false)
        }
    }

    /// Convenience accessor for online status.
    func isUserOnline(_ userId: String) -> Bool {
        userPresence[userId] ?? false
    }

    /// Convenience accessor for last seen timestamp.
    func getUserLastSeen(_ userId: String) -> Date? {
        lastSeenDates[userId]
    }

    /// Reset last error (used by UI to clear alerts).
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Helpers

    private func updateState(with users: [User]) {
        allUsers = users

        var presence: [String: Bool] = [:]
        var lastSeen: [String: Date] = [:]

        for user in users {
            presence[user.id] = user.isOnline
            lastSeen[user.id] = user.lastSeen
        }

        userPresence = presence
        lastSeenDates = lastSeen
    }

    private func decodeUser(from document: DocumentSnapshot) -> User? {
        guard let data = document.data() else { return nil }

        let id = document.documentID
        let email = data["email"] as? String ?? ""
        let displayName = data["displayName"] as? String ?? "Unknown"
        let photoURL = data["photoURL"] as? String
        let phoneNumber = data["phoneNumber"] as? String
        let isOnline = data["isOnline"] as? Bool ?? false

        let lastSeen: Date
        if let timestamp = data["lastSeen"] as? Timestamp {
            lastSeen = timestamp.dateValue()
        } else if let date = data["lastSeen"] as? Date {
            lastSeen = date
        } else {
            lastSeen = Date.distantPast
        }

        let fcmToken = data["fcmToken"] as? String

        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let date = data["createdAt"] as? Date {
            createdAt = date
        } else {
            createdAt = Date()
        }

        return User(
            id: id,
            email: email,
            displayName: displayName,
            photoURL: photoURL,
            phoneNumber: phoneNumber,
            isOnline: isOnline,
            lastSeen: lastSeen,
            fcmToken: fcmToken,
            createdAt: createdAt
        )
    }
}

// MARK: - Error Types

enum UserServiceError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to view other users."
        }
    }
}
