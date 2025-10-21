//
//  AuthViewModel.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import Combine

/// ViewModel for authentication UI
/// Manages UI state and coordinates with AuthService
@MainActor
class AuthViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Dependencies

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Check if email is valid format
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Check if password is valid (minimum 6 characters)
    var isPasswordValid: Bool {
        return password.count >= 6
    }

    /// Check if passwords match
    var passwordsMatch: Bool {
        return password == confirmPassword && !confirmPassword.isEmpty
    }

    /// Check if sign in form is valid
    var canSignIn: Bool {
        return !email.isEmpty && !password.isEmpty && isEmailValid
    }

    /// Check if sign up form is valid
    var canSignUp: Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               isEmailValid &&
               isPasswordValid &&
               passwordsMatch
    }

    /// Check if onboarding form is valid
    var canCompleteOnboarding: Bool {
        return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Initialization

    init(authService: AuthService? = nil) {
        self.authService = authService ?? AuthService()

        // Subscribe to auth service state
        self.authService.$isLoading
            .assign(to: &$isLoading)

        self.authService.$errorMessage
            .sink { [weak self] message in
                if let message = message {
                    self?.showErrorMessage(message)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Authentication Actions

    /// Sign up with email and password
    func signUp() async {
        guard canSignUp else {
            showErrorMessage("Please fill in all fields correctly")
            return
        }

        do {
            try await authService.signUp(email: email, password: password)
            clearForm()
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }

    /// Sign in with email and password
    func signIn() async {
        guard canSignIn else {
            showErrorMessage("Please enter valid email and password")
            return
        }

        do {
            try await authService.signIn(email: email, password: password)
            clearForm()
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }

    /// Sign in with Google
    func signInWithGoogle() async {
        do {
            try await authService.signInWithGoogle()
        } catch {
            // Don't show error if user cancelled
            if case AuthError.googleSignInCancelled = error {
                return
            }
            showErrorMessage(error.localizedDescription)
        }
    }

    /// Sign out current user
    func signOut() {
        do {
            try authService.signOut()
            clearForm()
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }

    /// Complete onboarding with display name
    func completeOnboarding(photoURL: String? = nil) async {
        guard canCompleteOnboarding else {
            showErrorMessage("Please enter a display name")
            return
        }

        do {
            try await authService.completeOnboarding(
                displayName: displayName,
                photoURL: photoURL
            )
            clearForm()
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }

    /// Update user profile
    func updateProfile(displayName: String?, photoURL: String?) async {
        do {
            try await authService.updateProfile(
                displayName: displayName,
                photoURL: photoURL
            )
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }

    // MARK: - Helper Methods

    /// Show error message to user
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    /// Clear form fields
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
        showError = false
    }

    /// Get password validation message
    func passwordValidationMessage() -> String? {
        guard !password.isEmpty else { return nil }

        if password.count < 6 {
            return "Password must be at least 6 characters"
        }

        return nil
    }

    /// Get confirm password validation message
    func confirmPasswordValidationMessage() -> String? {
        guard !confirmPassword.isEmpty else { return nil }

        if !passwordsMatch {
            return "Passwords do not match"
        }

        return nil
    }
}



