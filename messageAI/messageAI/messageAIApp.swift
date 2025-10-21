//
//  messageAIApp.swift
//  messageAI
//
//  Created by Yohan Yi on 10/20/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct messageAIApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var presenceService = PresenceService()
    @StateObject private var notificationService = NotificationService()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocalMessage.self,
            LocalConversation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    if authService.needsOnboarding {
                        OnboardingView()
                            .environmentObject(authService)
                            .environmentObject(notificationService)
                    } else {
                        MainTabView()
                            .environmentObject(authService)
                            .environmentObject(notificationService)
                    }
                } else {
                    AuthView()
                        .environmentObject(authService)
                }
            }
            .preferredColorScheme(.light)
            .task {
                await setupNotifications()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(from: oldPhase, to: newPhase)
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated, !authService.needsOnboarding {
                    registerNotificationToken()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - App Lifecycle Handling

    /// Handle app lifecycle changes for presence updates
    /// - Parameters:
    ///   - oldPhase: Previous scene phase
    ///   - newPhase: New scene phase
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        guard let userId = authService.currentUser?.id else {
            return
        }

        Task {
            do {
                switch newPhase {
                case .active:
                    // App became active (foreground)
                    try await presenceService.setOnline(userId: userId)
                    print("🟢 App became active - User set to online")

                case .inactive:
                    // App became inactive (transitioning)
                    // Don't update presence during transition
                    print("🟡 App became inactive")

                case .background:
                    // App moved to background
                    try await presenceService.setOffline(userId: userId)
                    print("🔴 App moved to background - User set to offline")

                @unknown default:
                    break
                }
            } catch {
                print("❌ Failed to update presence: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Notification Setup

    /// Setup push notifications on app launch
    private func setupNotifications() async {
        do {
            // Check if permissions are already granted
            let status = await notificationService.checkPermissionStatus()

            switch status {
            case .notDetermined:
                // Request permissions for the first time
                try await notificationService.requestPermissions()
                print("✅ Notification permissions requested")
            case .authorized, .provisional, .ephemeral:
                // Permissions already granted
                notificationService.permissionGranted = true
                print("✅ Notification permissions already granted")
            case .denied:
                print("⚠️ Notification permissions denied by user")
            @unknown default:
                break
            }
        } catch {
            print("❌ Failed to setup notifications: \(error.localizedDescription)")
        }
    }

    /// Register FCM token for the current user
    private func registerNotificationToken() {
        guard let userId = authService.currentUser?.id else {
            return
        }

        Task {
            do {
                try await notificationService.registerToken(userId: userId)
                print("✅ FCM token registered for user: \(userId)")
            } catch {
                print("❌ Failed to register FCM token: \(error.localizedDescription)")
            }
        }
    }
}
