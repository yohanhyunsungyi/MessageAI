//
//  AuthViewModelTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
import Combine
@testable import messageAI

@MainActor
final class AuthViewModelTests: XCTestCase {

    var viewModel: AuthViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = AuthViewModel()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        viewModel = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.email.isEmpty)
        XCTAssertTrue(viewModel.password.isEmpty)
        XCTAssertTrue(viewModel.confirmPassword.isEmpty)
        XCTAssertTrue(viewModel.displayName.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    // MARK: - Email Validation Tests

    func testEmailValidation() {
        // Invalid emails
        viewModel.email = ""
        XCTAssertFalse(viewModel.isEmailValid)

        viewModel.email = "invalid"
        XCTAssertFalse(viewModel.isEmailValid)

        viewModel.email = "invalid@"
        XCTAssertFalse(viewModel.isEmailValid)

        viewModel.email = "@invalid.com"
        XCTAssertFalse(viewModel.isEmailValid)

        viewModel.email = "invalid@.com"
        XCTAssertFalse(viewModel.isEmailValid)

        // Valid emails
        viewModel.email = "test@example.com"
        XCTAssertTrue(viewModel.isEmailValid)

        viewModel.email = "user.name@domain.co.uk"
        XCTAssertTrue(viewModel.isEmailValid)

        viewModel.email = "user+tag@example.com"
        XCTAssertTrue(viewModel.isEmailValid)
    }

    // MARK: - Password Validation Tests

    func testPasswordValidation() {
        // Invalid passwords (less than 6 characters)
        viewModel.password = ""
        XCTAssertFalse(viewModel.isPasswordValid)

        viewModel.password = "12345"
        XCTAssertFalse(viewModel.isPasswordValid)

        viewModel.password = "abc"
        XCTAssertFalse(viewModel.isPasswordValid)

        // Valid passwords (6 or more characters)
        viewModel.password = "123456"
        XCTAssertTrue(viewModel.isPasswordValid)

        viewModel.password = "password123"
        XCTAssertTrue(viewModel.isPasswordValid)

        viewModel.password = "verylongpassword"
        XCTAssertTrue(viewModel.isPasswordValid)
    }

    // MARK: - Password Match Tests

    func testPasswordsMatch() {
        // Passwords don't match
        viewModel.password = "password123"
        viewModel.confirmPassword = "different"
        XCTAssertFalse(viewModel.passwordsMatch)

        // Empty confirm password
        viewModel.password = "password123"
        viewModel.confirmPassword = ""
        XCTAssertFalse(viewModel.passwordsMatch)

        // Passwords match
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        XCTAssertTrue(viewModel.passwordsMatch)
    }

    // MARK: - Sign In Form Validation Tests

    func testCanSignIn() {
        // Empty fields
        viewModel.email = ""
        viewModel.password = ""
        XCTAssertFalse(viewModel.canSignIn)

        // Invalid email
        viewModel.email = "invalid"
        viewModel.password = "password123"
        XCTAssertFalse(viewModel.canSignIn)

        // Empty password
        viewModel.email = "test@example.com"
        viewModel.password = ""
        XCTAssertFalse(viewModel.canSignIn)

        // Valid form
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        XCTAssertTrue(viewModel.canSignIn)
    }

    // MARK: - Sign Up Form Validation Tests

    func testCanSignUp() {
        // Empty fields
        viewModel.email = ""
        viewModel.password = ""
        viewModel.confirmPassword = ""
        XCTAssertFalse(viewModel.canSignUp)

        // Invalid email
        viewModel.email = "invalid"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        XCTAssertFalse(viewModel.canSignUp)

        // Weak password
        viewModel.email = "test@example.com"
        viewModel.password = "123"
        viewModel.confirmPassword = "123"
        XCTAssertFalse(viewModel.canSignUp)

        // Passwords don't match
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "different"
        XCTAssertFalse(viewModel.canSignUp)

        // Valid form
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        XCTAssertTrue(viewModel.canSignUp)
    }

    // MARK: - Onboarding Form Validation Tests

    func testCanCompleteOnboarding() {
        // Empty display name
        viewModel.displayName = ""
        XCTAssertFalse(viewModel.canCompleteOnboarding)

        // Whitespace only
        viewModel.displayName = "   "
        XCTAssertFalse(viewModel.canCompleteOnboarding)

        // Valid display name
        viewModel.displayName = "Test User"
        XCTAssertTrue(viewModel.canCompleteOnboarding)

        // Display name with leading/trailing spaces
        viewModel.displayName = "  Test User  "
        XCTAssertTrue(viewModel.canCompleteOnboarding)
    }

    // MARK: - Password Validation Messages Tests

    func testPasswordValidationMessage() {
        // Empty password
        viewModel.password = ""
        XCTAssertNil(viewModel.passwordValidationMessage())

        // Weak password
        viewModel.password = "123"
        let weakMessage = viewModel.passwordValidationMessage()
        XCTAssertNotNil(weakMessage)
        XCTAssertTrue(weakMessage!.contains("6 characters"))

        // Valid password
        viewModel.password = "password123"
        XCTAssertNil(viewModel.passwordValidationMessage())
    }

    func testConfirmPasswordValidationMessage() {
        // Empty confirm password
        viewModel.confirmPassword = ""
        XCTAssertNil(viewModel.confirmPasswordValidationMessage())

        // Passwords don't match
        viewModel.password = "password123"
        viewModel.confirmPassword = "different"
        let mismatchMessage = viewModel.confirmPasswordValidationMessage()
        XCTAssertNotNil(mismatchMessage)
        XCTAssertTrue(mismatchMessage!.contains("do not match"))

        // Passwords match
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        XCTAssertNil(viewModel.confirmPasswordValidationMessage())
    }

    // MARK: - Clear Form Tests

    func testClearForm() {
        // Set all fields
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        viewModel.displayName = "Test User"

        // Clear form
        viewModel.clearForm()

        // Verify all fields are cleared
        XCTAssertTrue(viewModel.email.isEmpty)
        XCTAssertTrue(viewModel.password.isEmpty)
        XCTAssertTrue(viewModel.confirmPassword.isEmpty)
        XCTAssertTrue(viewModel.displayName.isEmpty)
    }

    // MARK: - Error Handling Tests

    func testClearError() {
        // Set error
        viewModel.errorMessage = "Test error"
        viewModel.showError = true

        // Clear error
        viewModel.clearError()

        // Verify error is cleared
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    func testErrorMessageDisplay() {
        let expectation = XCTestExpectation(description: "Error message published")

        viewModel.$showError
            .dropFirst() // Skip initial value
            .sink { showError in
                XCTAssertTrue(showError)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Trigger error in sign in with invalid form
        Task {
            await viewModel.signIn()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Sign Up Action Tests

    func testSignUpWithInvalidForm() async {
        // Set invalid form
        viewModel.email = "invalid"
        viewModel.password = "123"
        viewModel.confirmPassword = "456"

        // Try to sign up
        await viewModel.signUp()

        // Should show error
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Sign In Action Tests

    func testSignInWithInvalidForm() async {
        // Set invalid form
        viewModel.email = "invalid"
        viewModel.password = ""

        // Try to sign in
        await viewModel.signIn()

        // Should show error
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Onboarding Action Tests

    func testCompleteOnboardingWithInvalidForm() async {
        // Set invalid form
        viewModel.displayName = ""

        // Try to complete onboarding
        await viewModel.completeOnboarding()

        // Should show error
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Loading State Tests

    func testLoadingStateBinding() {
        let expectation = XCTestExpectation(description: "Loading state changes")
        expectation.expectedFulfillmentCount = 2 // Will change twice: false -> true -> false

        var changeCount = 0

        viewModel.$isLoading
            .dropFirst() // Skip initial value
            .sink { _ in
                changeCount += 1
                if changeCount == 2 {
                    expectation.fulfill()
                } else if changeCount == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Trigger action that changes loading state
        Task {
            // Invalid form will return quickly
            await viewModel.signIn()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Sign Out Tests

    func testSignOut() {
        // Sign out should call auth service
        // Note: This will fail if not actually signed in, but won't crash
        viewModel.signOut()

        // Verify form is cleared
        XCTAssertTrue(viewModel.email.isEmpty)
        XCTAssertTrue(viewModel.password.isEmpty)
        XCTAssertTrue(viewModel.confirmPassword.isEmpty)
    }

    // MARK: - Performance Tests

    func testFormValidationPerformance() {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"

        measure {
            _ = viewModel.canSignUp
            _ = viewModel.canSignIn
            _ = viewModel.isEmailValid
            _ = viewModel.isPasswordValid
            _ = viewModel.passwordsMatch
        }
    }

    func testClearFormPerformance() {
        measure {
            viewModel.email = "test@example.com"
            viewModel.password = "password123"
            viewModel.confirmPassword = "password123"
            viewModel.displayName = "Test User"
            viewModel.clearForm()
        }
    }
}
