//
//  AuthService.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import Combine

/// Service for managing user authentication
/// Handles email/password auth, Google Sign-In, and session management
@MainActor
class AuthService: ObservableObject {

    // MARK: - Published Properties

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var needsOnboarding = false
    @Published var errorMessage: String?
    @Published var isLoading = false

    // MARK: - Private Properties

    private let auth: Auth
    private let firestore: Firestore
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Initialization

    init() {
        self.auth = FirebaseManager.shared.auth
        self.firestore = FirebaseManager.shared.firestore

        // Setup auth state listener for session persistence
        setupAuthStateListener()
    }

    deinit {
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Session Persistence

    /// Listen to auth state changes and restore session
    private func setupAuthStateListener() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }

                if let user = user {
                    // User is signed in
                    do {
                        let userExists = try await self.checkUserExists(uid: user.uid)
                        if userExists {
                            // Load user profile from Firestore
                            try await self.loadUserProfile(uid: user.uid)
                            self.isAuthenticated = true
                            self.needsOnboarding = false
                        } else {
                            // New user needs onboarding
                            self.isAuthenticated = true
                            self.needsOnboarding = true
                        }
                    } catch {
                        print("Error loading user profile: \(error.localizedDescription)")
                        self.errorMessage = "Failed to load user profile"
                    }
                } else {
                    // User is signed out
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.needsOnboarding = false
                }
            }
        }
    }

    // MARK: - Email Authentication

    /// Sign up with email and password
    func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Validate input
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard isValidPassword(password) else {
            throw AuthError.weakPassword
        }

        do {
            let authResult = try await auth.createUser(withEmail: email, password: password)

            // New user needs onboarding
            self.needsOnboarding = true
            self.isAuthenticated = true

            print("User signed up successfully: \(authResult.user.uid)")
        } catch let error as NSError {
            throw mapFirebaseAuthError(error)
        }
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Validate input
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard !password.isEmpty else {
            throw AuthError.emptyPassword
        }

        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)

            // Check if user profile exists
            let userExists = try await checkUserExists(uid: authResult.user.uid)

            if userExists {
                // Load existing user profile
                try await loadUserProfile(uid: authResult.user.uid)
                self.needsOnboarding = false
            } else {
                // User needs to complete onboarding
                self.needsOnboarding = true
            }

            self.isAuthenticated = true

            print("User signed in successfully: \(authResult.user.uid)")
        } catch let error as NSError {
            throw mapFirebaseAuthError(error)
        }
    }

    // MARK: - Google Sign-In

    /// Sign in with Google
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // 1. Get client ID from Firebase config
        guard let clientID = auth.app?.options.clientID else {
            throw AuthError.missingClientID
        }

        // 2. Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // 3. Get root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        do {
            // 4. Sign in with Google
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            // 5. Get Google credentials
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingIDToken
            }
            let accessToken = result.user.accessToken.tokenString

            // 6. Create Firebase credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            // 7. Sign in to Firebase
            let authResult = try await auth.signIn(with: credential)

            // 8. Check if user needs onboarding
            let userExists = try await checkUserExists(uid: authResult.user.uid)

            if userExists {
                // Load existing user profile
                try await loadUserProfile(uid: authResult.user.uid)
                self.needsOnboarding = false
            } else {
                // New user needs onboarding
                self.needsOnboarding = true
            }

            self.isAuthenticated = true

            print("User signed in with Google successfully: \(authResult.user.uid)")
        } catch let error as NSError {
            throw mapGoogleSignInError(error)
        }
    }

    // MARK: - Sign Out

    /// Sign out the current user
    func signOut() throws {
        do {
            // Sign out from Firebase
            try auth.signOut()

            // Sign out from Google if signed in with Google
            GIDSignIn.sharedInstance.signOut()

            // Clear state
            self.currentUser = nil
            self.isAuthenticated = false
            self.needsOnboarding = false
            self.errorMessage = nil

            print("User signed out successfully")
        } catch {
            throw AuthError.signOutFailed
        }
    }

    // MARK: - Onboarding

    /// Complete onboarding by creating user profile in Firestore
    func completeOnboarding(displayName: String, photoURL: String?) async throws {
        guard let uid = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Validate display name
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.invalidDisplayName
        }

        // Create user document
        let user = User(
            id: uid,
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            photoURL: photoURL,
            phoneNumber: auth.currentUser?.phoneNumber,
            isOnline: true,
            lastSeen: Date(),
            fcmToken: nil,
            createdAt: Date()
        )

        do {
            // Save to Firestore
            try firestore
                .collection(Constants.Collections.users)
                .document(uid)
                .setData(from: user)

            // Update local state
            self.currentUser = user
            self.needsOnboarding = false

            print("Onboarding completed for user: \(uid)")
        } catch {
            throw AuthError.profileCreationFailed
        }
    }

    // MARK: - Helper Methods

    /// Check if user profile exists in Firestore
    func checkUserExists(uid: String) async throws -> Bool {
        let document = try await firestore
            .collection(Constants.Collections.users)
            .document(uid)
            .getDocument()

        return document.exists
    }

    /// Load user profile from Firestore
    private func loadUserProfile(uid: String) async throws {
        let document = try await firestore
            .collection(Constants.Collections.users)
            .document(uid)
            .getDocument()

        guard let user = try? document.data(as: User.self) else {
            throw AuthError.profileLoadFailed
        }

        self.currentUser = user
    }

    /// Update user profile
    func updateProfile(displayName: String?, photoURL: String?) async throws {
        guard let uid = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        var updates: [String: Any] = [:]

        if let displayName = displayName {
            updates["displayName"] = displayName.trimmingCharacters(in: .whitespaces)
        }

        if let photoURL = photoURL {
            updates["photoURL"] = photoURL
        }

        guard !updates.isEmpty else { return }

        do {
            try await firestore
                .collection(Constants.Collections.users)
                .document(uid)
                .updateData(updates)

            // Reload user profile
            try await loadUserProfile(uid: uid)

            print("Profile updated successfully")
        } catch {
            throw AuthError.profileUpdateFailed
        }
    }

    // MARK: - Validation

    /// Validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Validate password strength
    private func isValidPassword(_ password: String) -> Bool {
        // Minimum 6 characters (Firebase requirement)
        return password.count >= 6
    }

    // MARK: - Error Mapping

    /// Map Firebase Auth errors to custom errors
    private func mapFirebaseAuthError(_ error: NSError) -> AuthError {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return .unknown
        }

        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .wrongPassword:
            return .wrongPassword
        case .userNotFound:
            return .userNotFound
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkError
        case .tooManyRequests:
            return .tooManyRequests
        default:
            return .unknown
        }
    }

    /// Map Google Sign-In errors
    private func mapGoogleSignInError(_ error: NSError) -> AuthError {
        // Check if it's a Firebase error
        if error.domain == "FIRAuthErrorDomain" {
            return mapFirebaseAuthError(error)
        }

        // Google Sign-In specific errors
        switch error.code {
        case -5: // User cancelled
            return .googleSignInCancelled
        default:
            return .googleSignInFailed
        }
    }
}

// MARK: - Error Types

enum AuthError: LocalizedError {
    case invalidEmail
    case emptyPassword
    case weakPassword
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case networkError
    case tooManyRequests
    case notAuthenticated
    case missingClientID
    case noRootViewController
    case missingIDToken
    case googleSignInCancelled
    case googleSignInFailed
    case signOutFailed
    case profileCreationFailed
    case profileLoadFailed
    case profileUpdateFailed
    case invalidDisplayName
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .emptyPassword:
            return "Password cannot be empty"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .wrongPassword:
            return "Incorrect password. Please try again"
        case .userNotFound:
            return "No account found with this email"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .networkError:
            return "Network error. Please check your connection"
        case .tooManyRequests:
            return "Too many attempts. Please try again later"
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .missingClientID:
            return "Google Sign-In configuration error"
        case .noRootViewController:
            return "Unable to present Google Sign-In"
        case .missingIDToken:
            return "Google Sign-In authentication failed"
        case .googleSignInCancelled:
            return "Google Sign-In was cancelled"
        case .googleSignInFailed:
            return "Google Sign-In failed. Please try again"
        case .signOutFailed:
            return "Failed to sign out. Please try again"
        case .profileCreationFailed:
            return "Failed to create user profile"
        case .profileLoadFailed:
            return "Failed to load user profile"
        case .profileUpdateFailed:
            return "Failed to update profile"
        case .invalidDisplayName:
            return "Display name cannot be empty"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
