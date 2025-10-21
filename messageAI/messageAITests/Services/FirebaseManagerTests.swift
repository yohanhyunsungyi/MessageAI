//
//  FirebaseManagerTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
@testable import messageAI

final class FirebaseManagerTests: XCTestCase {

    var firebaseManager: FirebaseManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        firebaseManager = FirebaseManager.shared
    }

    override func tearDownWithError() throws {
        firebaseManager = nil
        try super.tearDownWithError()
    }

    // MARK: - Singleton Tests

    func testSingletonInstance() {
        // Given & When
        let instance1 = FirebaseManager.shared
        let instance2 = FirebaseManager.shared

        // Then
        XCTAssertTrue(instance1 === instance2, "FirebaseManager should be a singleton")
    }

    // MARK: - Initialization Tests

    func testAuthIsInitialized() {
        // When
        let auth = firebaseManager.auth

        // Then
        XCTAssertNotNil(auth, "Auth should be initialized")
    }

    func testFirestoreIsInitialized() {
        // When
        let firestore = firebaseManager.firestore

        // Then
        XCTAssertNotNil(firestore, "Firestore should be initialized")
    }

    func testFirestoreOfflinePersistenceEnabled() {
        // When
        let settings = firebaseManager.firestore.settings

        // Then
        XCTAssertTrue(settings.isPersistenceEnabled, "Offline persistence should be enabled")
    }

    func testFirestoreCacheSizeUnlimited() {
        // When
        let settings = firebaseManager.firestore.settings

        // Then
        XCTAssertEqual(settings.cacheSizeBytes, FirestoreCacheSizeUnlimited,
                       "Cache size should be set to unlimited")
    }

    // MARK: - Current User Tests

    func testCurrentUserIdWhenNotAuthenticated() {
        // Given
        // User not authenticated

        // When
        let userId = firebaseManager.currentUserId

        // Then
        XCTAssertNil(userId, "Current user ID should be nil when not authenticated")
    }

    func testIsAuthenticatedWhenNoUser() {
        // Given
        // User not authenticated

        // When
        let isAuthenticated = firebaseManager.isAuthenticated

        // Then
        XCTAssertFalse(isAuthenticated, "Should return false when no user is authenticated")
    }

    // MARK: - Performance Tests

    func testFirebaseManagerPerformance() {
        measure {
            _ = FirebaseManager.shared
        }
    }
}
