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
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
