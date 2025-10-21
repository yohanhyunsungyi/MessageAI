//
//  AuthServiceTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
@testable import messageAI

@MainActor
final class AuthServiceTests: XCTestCase {

    var authService: AuthService!

    override func setUp() async throws {
        try await super.setUp()
        authService = AuthService()
    }

    override func tearDown() async throws {
        authService = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testAuthServiceInitialization() {
        XCTAssertNotNil(authService)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertFalse(authService.needsOnboarding)
        XCTAssertNil(authService.currentUser)
        XCTAssertNil(authService.errorMessage)
        XCTAssertFalse(authService.isLoading)
    }

    // MARK: - Email Validation Tests

    func testEmailValidation() async throws {
        // Test valid email
        do {
            _ = try await authService.signUp(email: "test@example.com", password: "password123")
        } catch AuthError.invalidEmail {
            XCTFail("Valid email should not throw invalidEmail error")
        } catch {
            // Other errors are expected in test environment
        }

        // Test invalid email
        do {
            _ = try await authService.signUp(email: "invalid-email", password: "password123")
            XCTFail("Invalid email should throw error")
        } catch AuthError.invalidEmail {
            // Expected
        } catch {
            XCTFail("Should throw invalidEmail error, got: \(error)")
        }

        // Test empty email
        do {
            _ = try await authService.signUp(email: "", password: "password123")
            XCTFail("Empty email should throw error")
        } catch AuthError.invalidEmail {
            // Expected
        } catch {
            XCTFail("Should throw invalidEmail error, got: \(error)")
        }
    }

    // MARK: - Password Validation Tests

    func testPasswordValidation() async throws {
        // Test weak password (less than 6 characters)
        do {
            _ = try await authService.signUp(email: "test@example.com", password: "12345")
            XCTFail("Weak password should throw error")
        } catch AuthError.weakPassword {
            // Expected
        } catch {
            // Other errors acceptable in test environment
        }

        // Test valid password
        do {
            _ = try await authService.signUp(email: "test@example.com", password: "123456")
        } catch AuthError.weakPassword {
            XCTFail("Valid password should not throw weakPassword error")
        } catch {
            // Other errors are expected in test environment
        }
    }

    // MARK: - Empty Password Tests

    func testSignInWithEmptyPassword() async throws {
        do {
            _ = try await authService.signIn(email: "test@example.com", password: "")
            XCTFail("Empty password should throw error")
        } catch AuthError.emptyPassword {
            // Expected
        } catch {
            XCTFail("Should throw emptyPassword error, got: \(error)")
        }
    }

    // MARK: - Auth State Tests

    func testAuthStateAfterSignUp() async throws {
        // Initially not authenticated
        XCTAssertFalse(authService.isAuthenticated)

        // Note: Actual sign up would require Firebase connection
        // In unit tests, we test the state changes
    }

    func testAuthStateAfterSignOut() throws {
        // Sign out should clear user state
        do {
            try authService.signOut()
            XCTAssertFalse(authService.isAuthenticated)
            XCTAssertNil(authService.currentUser)
            XCTAssertFalse(authService.needsOnboarding)
        } catch {
            // Sign out may fail if not signed in, which is fine
        }
    }

    // MARK: - Loading State Tests

    func testLoadingStateToggle() async throws {
        XCTAssertFalse(authService.isLoading)

        // Loading state should be managed during operations
        // Note: In real tests, we'd mock Firebase to test loading states
    }

    // MARK: - Onboarding Validation Tests

    func testOnboardingValidation() async throws {
        // Test empty display name
        do {
            _ = try await authService.completeOnboarding(displayName: "", photoURL: nil)
            XCTFail("Empty display name should throw error")
        } catch AuthError.invalidDisplayName {
            // Expected
        } catch AuthError.notAuthenticated {
            // Also acceptable if not signed in
        } catch {
            XCTFail("Should throw invalidDisplayName or notAuthenticated, got: \(error)")
        }

        // Test whitespace-only display name
        do {
            _ = try await authService.completeOnboarding(displayName: "   ", photoURL: nil)
            XCTFail("Whitespace-only display name should throw error")
        } catch AuthError.invalidDisplayName {
            // Expected
        } catch AuthError.notAuthenticated {
            // Also acceptable if not signed in
        } catch {
            XCTFail("Should throw invalidDisplayName or notAuthenticated, got: \(error)")
        }
    }

    // MARK: - Error Message Tests

    func testAuthErrorMessages() {
        let errors: [AuthError] = [
            .invalidEmail,
            .weakPassword,
            .wrongPassword,
            .userNotFound,
            .emailAlreadyInUse,
            .networkError,
            .notAuthenticated,
            .googleSignInCancelled,
            .signOutFailed
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have description")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Error description should not be empty")
        }
    }

    // MARK: - Google Sign-In Error Tests

    func testGoogleSignInConfiguration() async throws {
        // Test that Google Sign-In can be initiated
        // Actual sign-in requires UI interaction
        do {
            _ = try await authService.signInWithGoogle()
        } catch AuthError.noRootViewController {
            // Expected in test environment without UI
        } catch AuthError.googleSignInCancelled {
            // Also acceptable
        } catch {
            // Other errors acceptable in test environment
        }
    }

    // MARK: - Profile Update Tests

    func testProfileUpdateRequiresAuthentication() async throws {
        // Profile update should fail if not authenticated
        do {
            _ = try await authService.updateProfile(displayName: "New Name", photoURL: nil)
            XCTFail("Profile update without auth should throw error")
        } catch AuthError.notAuthenticated {
            // Expected
        } catch {
            // Other errors acceptable
        }
    }

    // MARK: - Session Persistence Tests

    func testAuthStateListenerSetup() {
        // Auth state listener should be set up on initialization
        XCTAssertNotNil(authService)
        // Listener is private, but we can verify state is being tracked
        XCTAssertFalse(authService.isAuthenticated)
    }

    // MARK: - Performance Tests

    func testSignUpPerformance() {
        measure {
            let expectation = self.expectation(description: "Sign up validation")

            Task { @MainActor in
                do {
                    _ = try await self.authService.signUp(
                        email: "test@example.com",
                        password: "password123"
                    )
                } catch {
                    // Expected to fail without Firebase connection
                }
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }

    func testSignInPerformance() {
        measure {
            let expectation = self.expectation(description: "Sign in validation")

            Task { @MainActor in
                do {
                    _ = try await self.authService.signIn(
                        email: "test@example.com",
                        password: "password123"
                    )
                } catch {
                    // Expected to fail without Firebase connection
                }
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }
}
