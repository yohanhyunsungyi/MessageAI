//
//  FirebaseTestHelper.swift
//  messageAITests
//
//  Created by MessageAI on 10/20/25.
//

import XCTest
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Helper class for Firebase integration tests using Firebase Emulators
class FirebaseTestHelper {
    
    static let shared = FirebaseTestHelper()
    
    private var isConfigured = false
    
    private init() {}
    
    /// Configure Firebase to use emulators for testing
    func configureForTesting() {
        guard !isConfigured else { return }
        
        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Connect to Auth Emulator
        Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
        
        // Connect to Firestore Emulator
        let settings = Firestore.firestore().settings
        settings.host = "127.0.0.1:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        isConfigured = true
        
        print("✅ Firebase configured for testing with emulators")
    }
    
    /// Clear all Firestore data in emulator
    func clearFirestoreData() async throws {
        let db = Firestore.firestore()
        
        // Clear users collection
        try await deleteCollection(db.collection("users"))
        
        // Clear conversations collection
        try await deleteCollection(db.collection("conversations"))
        
        print("🗑️ Firestore data cleared")
    }
    
    /// Delete all documents in a collection
    private func deleteCollection(_ collection: CollectionReference) async throws {
        let snapshot = try await collection.getDocuments()
        
        for document in snapshot.documents {
            // Delete subcollections first
            let subcollections = ["messages", "typing"]
            for subcollectionName in subcollections {
                let subcollection = document.reference.collection(subcollectionName)
                try await deleteCollection(subcollection)
            }
            
            // Delete the document
            try await document.reference.delete()
        }
    }
    
    /// Sign out current user
    func signOut() throws {
        if Auth.auth().currentUser != nil {
            try Auth.auth().signOut()
            print("👤 User signed out")
        }
    }
    
    /// Create a test user with email and password
    func createTestUser(email: String, password: String) async throws -> AuthDataResult {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        print("✅ Test user created: \(email)")
        return authResult
    }
    
    /// Sign in with test credentials
    func signInTestUser(email: String, password: String) async throws -> AuthDataResult {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        print("✅ Test user signed in: \(email)")
        return authResult
    }
    
    /// Delete current test user
    func deleteCurrentUser() async throws {
        guard let user = Auth.auth().currentUser else {
            print("⚠️ No current user to delete")
            return
        }
        
        try await user.delete()
        print("🗑️ Test user deleted")
    }
    
    /// Clean up after tests
    func cleanup() async throws {
        try signOut()
        try await clearFirestoreData()
        print("🧹 Test cleanup complete")
    }
}

/// Base test case for Firebase integration tests
class FirebaseIntegrationTestCase: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        FirebaseTestHelper.shared.configureForTesting()
    }
    
    override func tearDown() async throws {
        try await FirebaseTestHelper.shared.cleanup()
        try await super.tearDown()
    }
}

