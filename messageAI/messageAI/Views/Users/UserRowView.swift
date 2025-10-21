//
//  UserRowView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

struct UserRowView: View {
    let user: User

    var body: some View {
        HStack(spacing: UIStyleGuide.Spacing.md) {
            // Profile image
            ZStack(alignment: .bottomTrailing) {
                if let photoURL = user.photoURL, !photoURL.isEmpty,
                   let imageData = Data(base64Encoded: photoURL),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(UIStyleGuide.Colors.primary.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(user.displayName.prefix(1).uppercased())
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(UIStyleGuide.Colors.textPrimary)
                        )
                }

                // Online indicator
                Circle()
                    .fill(user.isOnline ? UIStyleGuide.Colors.online : UIStyleGuide.Colors.offline)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }

            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(UIStyleGuide.Typography.bodyBold)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)

                Text(user.isOnline ? "Online" : formatLastSeen(user.lastSeen))
                    .font(UIStyleGuide.Typography.caption)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(UIStyleGuide.Colors.textTertiary)
        }
        .padding(UIStyleGuide.Spacing.md)
        .background(Color.white)
        .cornerRadius(UIStyleGuide.CornerRadius.medium)
    }

    // MARK: - Helpers

    private func formatLastSeen(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let minutes = components.minute, minutes < 60 {
            if minutes < 1 {
                return "Last seen just now"
            } else if minutes == 1 {
                return "Last seen 1m ago"
            } else {
                return "Last seen \(minutes)m ago"
            }
        } else if let hours = components.hour, hours < 24 {
            return hours == 1 ? "Last seen 1h ago" : "Last seen \(hours)h ago"
        } else if let days = components.day {
            if days == 0 {
                return "Last seen today"
            } else if days == 1 {
                return "Last seen yesterday"
            } else if days < 7 {
                return "Last seen \(days) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return "Last seen \(formatter.string(from: date))"
            }
        }

        return "Offline"
    }
}

#Preview {
    VStack(spacing: UIStyleGuide.Spacing.md) {
        UserRowView(user: User(
            id: "1",
            displayName: "John Doe",
            photoURL: nil,
            phoneNumber: nil,
            isOnline: true,
            lastSeen: Date(),
            fcmToken: nil,
            createdAt: Date()
        ))

        UserRowView(user: User(
            id: "2",
            displayName: "Jane Smith",
            photoURL: nil,
            phoneNumber: nil,
            isOnline: false,
            lastSeen: Date().addingTimeInterval(-3600),
            fcmToken: nil,
            createdAt: Date()
        ))
    }
    .padding()
    .background(UIStyleGuide.Colors.cardBackground)
}

