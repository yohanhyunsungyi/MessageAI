//
//  FirebaseManager.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Singleton manager for Firebase services
/// Provides centralized access to Auth and Firestore with proper configuration
class FirebaseManager {
    static let shared = FirebaseManager()

    let auth: Auth
    let firestore: Firestore

    private init() {
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()

        // Enable offline persistence for better performance and offline support
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
        firestore.settings = settings
    }

    /// Current authenticated user ID
    var currentUserId: String? {
        return auth.currentUser?.uid
    }

    /// Check if user is authenticated
    var isAuthenticated: Bool {
        return auth.currentUser != nil
    }
}
