//
//  PresenceService.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// Service for managing user presence (online/offline status)
@MainActor
class PresenceService: ObservableObject {
    // MARK: - Properties

    @Published var onlineUsers: Set<String> = []
    @Published var presenceStates: [String: Bool] = [:] // userId: isOnline

    private let firestore: Firestore
    private var listeners: [String: ListenerRegistration] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(firestore: Firestore = FirebaseManager.shared.firestore) {
        self.firestore = firestore
    }

    deinit {
        // Clean up listeners synchronously on deinit
        for (_, listener) in listeners {
            listener.remove()
        }
    }

    // MARK: - Public Methods

    /// Set user as online
    /// - Parameter userId: User ID to set online
    func setOnline(userId: String) async throws {
        let data: [String: Any] = [
            "isOnline": true,
            "lastSeen": Timestamp(date: Date())
        ]

        do {
            try await firestore
                .collection(Constants.Collections.users)
                .document(userId)
                .updateData(data)

            await MainActor.run {
                onlineUsers.insert(userId)
                presenceStates[userId] = true
            }

            print("✅ PresenceService: User \(userId) set to online")
        } catch {
            print("❌ PresenceService: Failed to set user online: \(error.localizedDescription)")
            throw PresenceError.failedToSetOnline(error)
        }
    }

    /// Set user as offline
    /// - Parameter userId: User ID to set offline
    func setOffline(userId: String) async throws {
        let now = Date()
        let data: [String: Any] = [
            "isOnline": false,
            "lastSeen": Timestamp(date: now)
        ]

        do {
            try await firestore
                .collection(Constants.Collections.users)
                .document(userId)
                .updateData(data)

            await MainActor.run {
                onlineUsers.remove(userId)
                presenceStates[userId] = false
            }

            print("✅ PresenceService: User \(userId) set to offline")
        } catch {
            print("❌ PresenceService: Failed to set user offline: \(error.localizedDescription)")
            throw PresenceError.failedToSetOffline(error)
        }
    }

    /// Start listening to presence changes for a specific user
    /// - Parameter userId: User ID to observe
    func startListening(userId: String) {
        // Don't create duplicate listeners
        guard listeners[userId] == nil else { return }

        let listener = firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ PresenceService: Error listening to user \(userId): \(error.localizedDescription)")
                    return
                }

                guard let data = snapshot?.data(),
                      let isOnline = data["isOnline"] as? Bool else {
                    return
                }

                Task { @MainActor in
                    self.presenceStates[userId] = isOnline

                    if isOnline {
                        self.onlineUsers.insert(userId)
                    } else {
                        self.onlineUsers.remove(userId)
                    }

                    print("📡 PresenceService: User \(userId) is now \(isOnline ? "online" : "offline")")
                }
            }

        listeners[userId] = listener
    }

    /// Start listening to presence changes for multiple users
    /// - Parameter userIds: Array of user IDs to observe
    func startListening(userIds: [String]) {
        for userId in userIds {
            startListening(userId: userId)
        }
    }

    /// Stop listening to presence changes for a specific user
    /// - Parameter userId: User ID to stop observing
    func stopListening(userId: String) {
        listeners[userId]?.remove()
        listeners.removeValue(forKey: userId)
    }

    /// Stop listening to all presence changes
    func stopListeningToAll() {
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }

    /// Check if a user is currently online
    /// - Parameter userId: User ID to check
    /// - Returns: True if user is online, false otherwise
    func isUserOnline(_ userId: String) -> Bool {
        return presenceStates[userId] ?? false
    }

    /// Get last seen date for a user
    /// - Parameter userId: User ID to get last seen for
    /// - Returns: Last seen date or nil if not available
    func getLastSeen(userId: String) async throws -> Date? {
        do {
            let document = try await firestore
                .collection(Constants.Collections.users)
                .document(userId)
                .getDocument()

            guard let data = document.data(),
                  let timestamp = data["lastSeen"] as? Timestamp else {
                return nil
            }

            return timestamp.dateValue()
        } catch {
            print("❌ PresenceService: Failed to get last seen: \(error.localizedDescription)")
            throw PresenceError.failedToGetLastSeen(error)
        }
    }

    /// Batch update presence for app lifecycle
    /// - Parameters:
    ///   - userId: User ID
    ///   - isOnline: Whether user should be online or offline
    func updatePresence(userId: String, isOnline: Bool) async throws {
        if isOnline {
            try await setOnline(userId: userId)
        } else {
            try await setOffline(userId: userId)
        }
    }
}

// MARK: - Error Types

enum PresenceError: LocalizedError {
    case failedToSetOnline(Error)
    case failedToSetOffline(Error)
    case failedToGetLastSeen(Error)

    var errorDescription: String? {
        switch self {
        case .failedToSetOnline(let error):
            return "Failed to set user online: \(error.localizedDescription)"
        case .failedToSetOffline(let error):
            return "Failed to set user offline: \(error.localizedDescription)"
        case .failedToGetLastSeen(let error):
            return "Failed to get last seen: \(error.localizedDescription)"
        }
    }
}
