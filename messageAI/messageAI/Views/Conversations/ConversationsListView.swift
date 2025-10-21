//
//  ConversationsListView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

/// List view displaying all conversations
/// Will be fully implemented in PR #11
struct ConversationsListView: View {
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                UIStyleGuide.Colors.background
                    .edgesIgnoringSafeArea(.all)

                // Empty state placeholder
                VStack(spacing: UIStyleGuide.Spacing.lg) {
                    Spacer()

                    // Icon
                    ZStack {
                        Circle()
                            .fill(UIStyleGuide.Colors.cardBackground)
                            .frame(width: 120, height: 120)

                        Image(systemName: "message.fill")
                            .font(.system(size: 50))
                            .foregroundColor(UIStyleGuide.Colors.textTertiary)
                    }

                    // Title
                    Text("No Conversations Yet")
                        .font(UIStyleGuide.Typography.title2)
                        .foregroundColor(UIStyleGuide.Colors.textPrimary)

                    // Subtitle
                    Text("Start a conversation by selecting\na user from the Users tab")
                        .font(UIStyleGuide.Typography.bodySmall)
                        .foregroundColor(UIStyleGuide.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Spacer()

                    // Coming soon badge
                    HStack(spacing: UIStyleGuide.Spacing.sm) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 14))
                        Text("Coming in PR #11")
                            .font(UIStyleGuide.Typography.caption)
                    }
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)
                    .padding(.horizontal, UIStyleGuide.Spacing.md)
                    .padding(.vertical, UIStyleGuide.Spacing.sm)
                    .background(UIStyleGuide.Colors.cardBackground)
                    .cornerRadius(UIStyleGuide.CornerRadius.pill)
                    .padding(.bottom, UIStyleGuide.Spacing.xl)
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search conversations")
        }
    }
}

#Preview {
    ConversationsListView()
        .environmentObject(AuthService())
}

