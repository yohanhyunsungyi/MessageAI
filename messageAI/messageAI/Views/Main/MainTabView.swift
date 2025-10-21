//
//  MainTabView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

/// Main tab view container with three tabs: Conversations, Users, and Profile
struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Conversations Tab
            ConversationsListView()
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

            // Profile Tab
            ProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 2 ? "person.circle.fill" : "person.circle")
                            .font(.system(size: UIStyleGuide.IconSize.medium))
                        Text("Profile")
                            .font(UIStyleGuide.Typography.caption)
                    }
                }
                .tag(2)
        }
        .accentColor(UIStyleGuide.Colors.tabBarSelected)
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
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
}
