//
//  MainTabView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI
import SwiftData

/// Main tab view container with three tabs: Conversations, Users, and Profile
struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var conversationsViewModel: ConversationsViewModel?
    @State private var hasSetupMonitoring = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Conversations Tab
            ConversationsListView(conversationsViewModel: conversationsViewModel)
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "message.fill" : "message")
                            .font(.system(size: UIStyleGuide.IconSize.medium))
                        Text("Chats")
                            .font(UIStyleGuide.Typography.caption)
                    }
                }
                .tag(0)

            // Users Tab
            UsersListView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 1 ? "person.2.fill" : "person.2")
                            .font(.system(size: UIStyleGuide.IconSize.medium))
                        Text("Users")
                            .font(UIStyleGuide.Typography.caption)
                    }
                }
                .tag(1)

            // Action Items Tab
            ActionItemsListView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 2 ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: UIStyleGuide.IconSize.medium))
                        Text("Tasks")
                            .font(UIStyleGuide.Typography.caption)
                    }
                }
                .tag(2)

            // Decisions Tab
            DecisionsListView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 3 ? "lightbulb.fill" : "lightbulb")
                            .font(.system(size: UIStyleGuide.IconSize.medium))
                        Text("Decisions")
                            .font(UIStyleGuide.Typography.caption)
                    }
                }
                .tag(3)

            // Profile Tab
            ProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                            .font(.system(size: UIStyleGuide.IconSize.medium))
                        Text("Profile")
                            .font(UIStyleGuide.Typography.caption)
                    }
                }
                .tag(4)
        }
        .accentColor(UIStyleGuide.Colors.tabBarSelected)
        .task {
            if !hasSetupMonitoring {
                await setupGlobalMonitoring()
                hasSetupMonitoring = true
            }
        }
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(UIStyleGuide.Colors.tabBarBackground)

            // Remove top border line
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()

            // Apply appearance
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    // MARK: - Global Monitoring Setup

    /// Setup global conversation monitoring that persists across tab switches
    private func setupGlobalMonitoring() async {
        print("🔔 Setting up global conversation monitoring...")

        // Initialize services with proper ModelContext
        let localStorageService = LocalStorageService(modelContext: modelContext)
        let conversationService = ConversationService(
            localStorageService: localStorageService,
            notificationService: notificationService
        )
        let viewModel = ConversationsViewModel(
            conversationService: conversationService,
            authService: authService,
            notificationService: notificationService
        )

        // Update state
        conversationsViewModel = viewModel

        // Load conversations and start listening
        await viewModel.loadConversations()
        viewModel.startListening()

        print("✅ Global conversation monitoring active")
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
}
