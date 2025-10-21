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
                    } else {
                        MainTabView()
                            .environmentObject(authService)
                    }
                } else {
                    AuthView()
                        .environmentObject(authService)
                }
            }
            .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
