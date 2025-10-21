//
//  ConversationRowView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

/// Row view displaying a single conversation in the list
struct ConversationRowView: View {

    // MARK: - Properties

    let conversation: Conversation
    let displayName: String
    let subtitle: String
    let photoURL: String?
    let unreadCount: Int

    // MARK: - Body

    var body: some View {
        HStack(spacing: UIStyleGuide.Spacing.md) {
            // Avatar
            avatarView

            // Content
            VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.xs) {
                // Name and timestamp
                HStack {
                    // Name
                    Text(displayName)
                        .font(UIStyleGuide.Typography.bodyBold)
                        .foregroundColor(UIStyleGuide.Colors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    // Timestamp
                    if let timestamp = conversation.lastMessageTimestamp {
                        Text(formatTimestamp(timestamp))
                            .font(UIStyleGuide.Typography.caption)
                            .foregroundColor(UIStyleGuide.Colors.textTertiary)
                    }
                }

                // Last message and unread badge
                HStack(spacing: UIStyleGuide.Spacing.sm) {
                    // Last message
                    Text(subtitle)
                        .font(UIStyleGuide.Typography.bodySmall)
                        .foregroundColor(UIStyleGuide.Colors.textSecondary)
                        .lineLimit(2)

                    Spacer()

                    // Unread badge
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(UIStyleGuide.Typography.captionBold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(UIStyleGuide.Colors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, UIStyleGuide.Spacing.sm)
        .padding(.horizontal, UIStyleGuide.Spacing.md)
        .background(Color.white)
        .contentShape(Rectangle())
    }

    // MARK: - Avatar View

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            if conversation.type == .group {
                // Group avatar (multiple circles)
                groupAvatarView
            } else {
                // Single user avatar
                singleAvatarView
            }
        }
    }

    private var singleAvatarView: some View {
        Circle()
            .fill(UIStyleGuide.Colors.cardBackground)
            .frame(width: 56, height: 56)
            .overlay(
                Group {
                    if let photoURL = photoURL, !photoURL.isEmpty {
                        // Photo placeholder (will load image later)
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(UIStyleGuide.Colors.textTertiary)
                    } else {
                        // Initial
                        Text(displayName.prefix(1).uppercased())
                            .font(UIStyleGuide.Typography.title2)
                            .foregroundColor(UIStyleGuide.Colors.textPrimary)
                    }
                }
            )
    }

    private var groupAvatarView: some View {
        ZStack {
            Circle()
                .fill(UIStyleGuide.Colors.cardBackground)
                .frame(width: 56, height: 56)

            Image(systemName: "person.3.fill")
                .font(.system(size: 24))
                .foregroundColor(UIStyleGuide.Colors.textTertiary)
        }
    }

    // MARK: - Helper Methods

    /// Format timestamp for display
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            // Show time for today
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day,
                  daysAgo < 7 {
            // Show day of week for this week
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            // Show date for older
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        // One-on-one conversation with unread messages
        ConversationRowView(
            conversation: Conversation(
                id: "1",
                participantIds: ["user1", "user2"],
                participantNames: ["user1": "Alice", "user2": "Bob"],
                participantPhotos: [:],
                lastMessage: "Hey! How are you doing?",
                lastMessageTimestamp: Date(),
                lastMessageSenderId: "user1",
                type: .oneOnOne,
                groupName: nil,
                createdAt: Date(),
                createdBy: "user1"
            ),
            displayName: "Alice",
            subtitle: "Hey! How are you doing?",
            photoURL: nil,
            unreadCount: 3
        )

        Divider()

        // Group conversation
        ConversationRowView(
            conversation: Conversation(
                id: "2",
                participantIds: ["user1", "user2", "user3"],
                participantNames: ["user1": "Alice", "user2": "Bob", "user3": "Charlie"],
                participantPhotos: [:],
                lastMessage: "Let's meet tomorrow at 3pm",
                lastMessageTimestamp: Date().addingTimeInterval(-86400),
                lastMessageSenderId: "user2",
                type: .group,
                groupName: "Team Project",
                createdAt: Date(),
                createdBy: "user1"
            ),
            displayName: "Team Project",
            subtitle: "Let's meet tomorrow at 3pm",
            photoURL: nil,
            unreadCount: 0
        )

        Divider()

        // Conversation with no messages
        ConversationRowView(
            conversation: Conversation(
                id: "3",
                participantIds: ["user1", "user4"],
                participantNames: ["user1": "You", "user4": "David"],
                participantPhotos: [:],
                lastMessage: nil,
                lastMessageTimestamp: nil,
                lastMessageSenderId: nil,
                type: .oneOnOne,
                groupName: nil,
                createdAt: Date().addingTimeInterval(-172800),
                createdBy: "user1"
            ),
            displayName: "David",
            subtitle: "No messages yet",
            photoURL: nil,
            unreadCount: 0
        )
    }
    .background(UIStyleGuide.Colors.background)
}
