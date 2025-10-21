//
//  AuthIntegrationTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
import FirebaseAuth
import FirebaseFirestore
@testable import messageAI

/// Integration tests for AuthService with Firebase Emulator
/// Run Firebase Emulator before running these tests: firebase emulators:start
@MainActor
final class AuthIntegrationTests: FirebaseIntegrationTestCase {

    var authService: AuthService!

    override func setUp() async throws {
        try await super.setUp()
        authService = AuthService()

        // Sign out any existing user
        if FirebaseManager.shared.isAuthenticated {
            try FirebaseManager.shared.auth.signOut()
        }
    }

    override func tearDown() async throws {
        // Clean up: sign out and delete test user if exists
        if let currentUser = FirebaseManager.shared.auth.currentUser {
            try? await deleteUserAccount(currentUser)
        }

        authService = nil
        try await super.tearDown()
    }

    // MARK: - Sign Up Tests

    func testSignUpWithEmailAndPassword() async throws {
        let testEmail = "signup_test_\(UUID().uuidString)@example.com"
        let testPassword = "testPassword123"

        // Sign up
        try await authService.signUp(email: testEmail, password: testPassword)

        // Verify user is authenticated
        await waitForState(timeout: 2.0) {
            self.authService.isAuthenticated
        }

        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertTrue(authService.needsOnboarding) // New user needs onboarding

        // Verify user exists in Firebase Auth
        XCTAssertNotNil(FirebaseManager.shared.auth.currentUser)
        XCTAssertEqual(FirebaseManager.shared.auth.currentUser?.email, testEmail)
    }

    func testSignUpWithExistingEmail() async throws {
        let testEmail = "duplicate_test_\(UUID().uuidString)@example.com"
        let testPassword = "testPassword123"

        // First sign up
        try await authService.signUp(email: testEmail, password: testPassword)

        // Wait for auth state
        await waitForState(timeout: 2.0) {
            self.authService.isAuthenticated
        }

        // Sign out
        try authService.signOut()

        // Try to sign up again with same email
        do {
            try await authService.signUp(email: testEmail, password: testPassword)
            XCTFail("Should throw emailAlreadyInUse error")
        } catch AuthError.emailAlreadyInUse {
            // Expected
        } catch {
            XCTFail("Expected emailAlreadyInUse, got: \(error)")
        }
    }

    func testSignUpWithInvalidEmail() async throws {
        do {
            try await authService.signUp(email: "invalid-email", password: "testPassword123")
            XCTFail("Should throw invalidEmail error")
        } catch AuthError.invalidEmail {
            // Expected
        } catch {
            XCTFail("Expected invalidEmail, got: \(error)")
        }
    }

    func testSignUpWithWeakPassword() async throws {
        let testEmail = "weakpass_test_\(UUID().uuidString)@example.com"

        do {
            try await authService.signUp(email: testEmail, password: "123")
            XCTFail("Should throw weakPassword error")
        } catch AuthError.weakPassword {
            // Expected
        } catch {
            XCTFail("Expected weakPassword, got: \(error)")
        }
    }

    // MARK: - Sign In Tests

    func testSignInWithEmailAndPassword() async throws {
        let testEmail = "signin_test_\(UUID().uuidString)@example.com"
        let testPassword = "testPassword123"

        // First create account
        try await authService.signUp(email: testEmail, password: testPassword)
        await waitForState(timeout: 2.0) { self.authService.isAuthenticated }

        // Complete onboarding
        try await authService.completeOnboarding(displayName: "Test User", photoURL: nil)
        await waitForState(timeout: 2.0) { !self.authService.needsOnboarding }

        // Sign out
        try authService.signOut()
        await waitForState(timeout: 2.0) { !self.authService.isAuthenticated }

        // Sign in
        try await authService.signIn(email: testEmail, password: testPassword)
        await waitForState(timeout: 2.0) { self.authService.isAuthenticated }

        // Verify user is authenticated
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertFalse(authService.needsOnboarding) // User completed onboarding
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.displayName, "Test User")
    }

    func testSignInWithWrongPassword() async throws {
        let testEmail = "wrongpass_test_\(UUID().uuidString)@example.com"
        let testPassword = "correctPassword123"

        // Create account
        try await authService.signUp(email: testEmail, password: testPassword)
        await waitForState(timeout: 2.0) { self.authService.isAuthenticated }

        // Sign out
        try authService.signOut()
        await waitForState(timeout: 2.0) { !self.authService.isAuthenticated }

        // Try to sign in with wrong password
        do {
            try await authService.signIn(email: testEmail, password: "wrongPassword")
            XCTFail("Should throw wrongPassword error")
        } catch AuthError.wrongPassword {
            // Expected
        } catch {
            XCTFail("Expected wrongPassword, got: \(error)")
        }
    }

    func testSignInWithNonExistentUser() async throws {
        let testEmail = "nonexistent_\(UUID().uuidString)@example.com"

        do {
            try await authService.signIn(email: testEmail, password: "password123")
            XCTFail("Should throw userNotFound error")
        } catch AuthError.userNotFound {
            // Expected
        } catch {
            XCTFail("Expected userNotFound, got: \(error)")
        }
    }

    // MARK: - Sign Out Tests

    func testSignOut() async throws {
        let testEmail = "signout_test_\(UUID().uuidString)@example.com"
        let testPassword = "testPassword123"

        // Sign up
        try await authService.signUp(email: testEmail, password: testPassword)
        await waitForState(timeout: 2.0) { self.authService.isAuthenticated }

        XCTAssertTrue(authService.isAuthenticated)

        // Sign out
        try authService.signOut()

        // Wait for state to update
        await waitForState(timeout: 2.0) { !self.authService.isAuthenticated }

        // Verify state is cleared
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(authService.needsOnboarding)
    }

    // MARK: - Onboarding Tests

    func testCompleteOnboarding() async throws {
        let testEmail = "onboarding_test_\(UUID().uuidString)@example.com"
        let testPassword = "testPassword123"
        let displayName = "Test User"

        // Sign up
        try await authService.signUp(email: testEmail, password: testPassword)
        await waitForState(timeout: 2.0) { self.authService.isAuthenticated }

        XCTAssertTrue(authService.needsOnboarding)

        // Complete onboarding
        try await authService.completeOnboarding(displayName: displayName, photoURL: nil)

        // Wait for state to update
        await waitForState(timeout: 2.0) { !self.authService.needsOnboarding }

        // Verify onboarding completed
        XCTAssertFalse(authService.needsOnboarding)
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.displayName, displayName)

        // Verify user document exists in Firestore
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            XCTFail("Current user should exist")
            return
        }

        let userExists = try await authService.checkUserExists(uid: uid)
        XCTAssertTrue(userExists)
    }

    func testOnboardingWithEmptyDisplayName() async throws {
        let testEmail = "empty_name_test_\(UUID().uuidString)@example.com"
        let testPassword = "testPassword123"

        // Sign up
        try await authService.signUp(email: testEmail, password: testPassword)
        await waitForState(timeout: 2.0) { self.authService.isAuthenticated }

        // Try to complete onboarding with empty name
        do {
            try await authService.completeOnboarding(displayName: "", photoURL: nil)
            XCTFail("Should throw invalidDisplayName error")
        } catch AuthError.invalidDisplayName {
            // Expected
        } catch {
            XCTFail("Expected invalidDisplayName, got: \(error)")
        }
    }

    // MARK: - User Exists Tests

    func testCheckUserExists() async throws {
        let testEmail = "checkuser_test_\(UUID().uuidString)@example.com"
        let testPassword = "testPassword123"

        // Sign up
        try await authService.signUp(email: testEmail, password: testPassword)
        await waitForState(timeout: 2.0) { self.authService.isAuthenticated }

        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            XCTFail("Current user should exist")
            return
        }

        // User shouldn't exist in Firestore yet (no onboarding)
        var exists = try await authService.checkUserExists(uid: uid)
        XCTAssertFalse(exists)

        // Complete onboarding
        try await authService.completeOnboarding(displayName: "Test User", photoURL: nil)
        await waitForState(timeout: 2.0) { !self.authService.needsOnboarding }

        // User should now exist in Firestore
        exists = try await authService.checkUserExists(uid: uid)
        XCTAssertTrue(exists)
    }

    // MARK: - Session Persistence Tests

    func testSessionPersistence() async throws {
        let testEmail = "session_test_\(UUID().uuidString)@example.com"
        let testPassword = "testPassword123"

        // Sign up and complete onboarding
        try await authService.signUp(email: testEmail, password: testPassword)
        await waitForState(timeout: 2.0) { self.authService.isAuthenticated }

        try await authService.completeOnboarding(displayName: "Test User", photoURL: nil)
        await waitForState(timeout: 2.0) { !self.authService.needsOnboarding }

        let uid = FirebaseManager.shared.auth.currentUser?.uid
        XCTAssertNotNil(uid)

        // Create new auth service instance (simulating app restart)
        let newAuthService = AuthService()

        // Wait for session to be restored
        await waitForState(timeout: 3.0) { newAuthService.isAuthenticated }

        // Session should be restored
        XCTAssertTrue(newAuthService.isAuthenticated)
        XCTAssertNotNil(newAuthService.currentUser)
        XCTAssertEqual(newAuthService.currentUser?.id, uid)
    }

    // MARK: - Profile Update Tests

    func testUpdateProfile() async throws {
        let testEmail = "profile_test_\(UUID().uuidString)@example.com"
        let testPassword = "testPassword123"

        // Sign up and complete onboarding
        try await authService.signUp(email: testEmail, password: testPassword)
        await waitForState(timeout: 2.0) { self.authService.isAuthenticated }

        try await authService.completeOnboarding(displayName: "Original Name", photoURL: nil)
        await waitForState(timeout: 2.0) { !self.authService.needsOnboarding }

        // Update profile
        let newDisplayName = "Updated Name"
        try await authService.updateProfile(displayName: newDisplayName, photoURL: nil)

        // Wait for update to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Verify update
        XCTAssertEqual(authService.currentUser?.displayName, newDisplayName)
    }

    // MARK: - Performance Tests

    func testSignUpPerformance() async throws {
        measure {
            let expectation = self.expectation(description: "Sign up performance")

            Task { @MainActor in
                let testEmail = "perf_signup_\(UUID().uuidString)@example.com"

                do {
                    try await self.authService.signUp(email: testEmail, password: "testPassword123")
                    try? self.authService.signOut()
                } catch {
                    // Ignore errors in performance test
                }

                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testSignInPerformance() async throws {
        // Create test account first
        let testEmail = "perf_signin_\(UUID().uuidString)@example.com"
        let testPassword = "testPassword123"

        try await authService.signUp(email: testEmail, password: testPassword)
        await waitForState(timeout: 2.0) { self.authService.isAuthenticated }

        try await authService.completeOnboarding(displayName: "Perf Test", photoURL: nil)
        try authService.signOut()
        await waitForState(timeout: 2.0) { !self.authService.isAuthenticated }

        measure {
            let expectation = self.expectation(description: "Sign in performance")

            Task { @MainActor in
                do {
                    try await self.authService.signIn(email: testEmail, password: testPassword)
                    try? self.authService.signOut()
                } catch {
                    // Ignore errors in performance test
                }

                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 5.0)
        }
    }

    // MARK: - Helper Methods

    /// Wait for a condition to become true
    private func waitForState(timeout: TimeInterval, condition: @escaping () -> Bool) async {
        let endTime = Date().addingTimeInterval(timeout)

        while Date() < endTime {
            if condition() {
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }

    /// Delete user account (cleanup)
    private func deleteUserAccount(_ user: FirebaseAuth.User) async throws {
        // Delete Firestore document
        try? await FirebaseManager.shared.firestore
            .collection(Constants.Collections.users)
            .document(user.uid)
            .delete()

        // Delete auth account
        try? await user.delete()
    }
}
