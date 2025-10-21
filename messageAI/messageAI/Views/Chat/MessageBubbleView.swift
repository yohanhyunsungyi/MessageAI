//
//  MessageBubbleView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

enum MessagePositionInSequence {
    case single
    case first
    case middle
    case last
}

struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    let position: MessagePositionInSequence
    let showSenderName: Bool
    let conversation: Conversation?

    @State private var showTimestamp = false

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            // Sender name (only for group chats and received messages)
            if showSenderName && !isFromCurrentUser && (position == .first || position == .single) {
                Text(message.senderName)
                    .font(UIStyleGuide.Typography.caption)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)
                    .padding(.leading, 40) // Align with bubble (avatar width + spacing)
                    .padding(.bottom, 2)
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                if !isFromCurrentUser {
                    // Avatar for received messages
                    avatarView
                }

                VStack(alignment: alignment, spacing: 4) {
                    // Message bubble
                    messageBubble
                        .clipShape(BubbleShape(isFromCurrentUser: isFromCurrentUser, position: position))

                    // Timestamp and status
                    if showTimestamp {
                        HStack(spacing: 4) {
                            Text(DateFormatter.messageTime.string(from: message.timestamp))
                                .font(UIStyleGuide.Typography.caption)
                                .foregroundColor(UIStyleGuide.Colors.textTertiary)

                            if isFromCurrentUser {
                                statusIcon
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isFromCurrentUser ? .trailing : .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment.toFrameAlignment())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showTimestamp.toggle()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var alignment: HorizontalAlignment {
        isFromCurrentUser ? .trailing : .leading
    }

    // MARK: - Message Bubble

    private var messageBubble: some View {
        Text(message.text)
            .font(UIStyleGuide.Typography.body)
            .foregroundColor(UIStyleGuide.Colors.textPrimary)
            .padding(.horizontal, UIStyleGuide.Spacing.md)
            .padding(.vertical, UIStyleGuide.Spacing.sm + 2)
            .background(bubbleBackground)
    }

    private var bubbleBackground: some View {
        Group {
            if isFromCurrentUser {
                // Sent messages - lime yellow
                UIStyleGuide.Colors.primary
            } else {
                // Received messages - white with shadow
                Color.white
                    .shadow(
                        color: UIStyleGuide.Shadow.light.color,
                        radius: UIStyleGuide.Shadow.light.radius,
                        x: UIStyleGuide.Shadow.light.x,
                        y: UIStyleGuide.Shadow.light.y
                    )
            }
        }
    }

    // MARK: - Sender Avatar

    @ViewBuilder
    private var avatarView: some View {
        // Show avatar only for the last message in a sequence
        if position == .last || position == .single {
            senderAvatar
        } else {
            // Keep the space to align bubbles correctly
            Spacer().frame(width: 32, height: 32)
        }
    }

    private var senderAvatar: some View {
        ZStack {
            Circle()
                .fill(getAvatarColor())
                .frame(width: 32, height: 32)

            // Display initials (image loading can be added in future)
            Text(getInitials())
                .font(UIStyleGuide.Typography.caption)
                .foregroundColor(.white)
        }
    }

    // MARK: - Status Icon

    private var statusIcon: some View {
        Group {
            switch message.status {
            case .sending:
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(UIStyleGuide.Colors.textTertiary)

            case .sent:
                Image(systemName: "checkmark")
                    .font(.system(size: 10))
                    .foregroundColor(UIStyleGuide.Colors.textTertiary)

            case .delivered:
                HStack(spacing: -2) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 10))
                .foregroundColor(UIStyleGuide.Colors.textTertiary)

            case .read:
                HStack(spacing: -2) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 10))
                .foregroundColor(UIStyleGuide.Colors.primary)

            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(UIStyleGuide.Colors.error)
            }
        }
    }

    // MARK: - Helper Methods

    private func getInitials() -> String {
        let components = message.senderName.components(separatedBy: " ")
        if components.count >= 2 {
            let firstInitial = components[0].prefix(1)
            let lastInitial = components[1].prefix(1)
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }
        return "?"
    }

    private func getAvatarColor() -> Color {
        // Generate consistent color based on sender ID
        let colors: [Color] = [
            Color(hex: "5EC792"),
            Color(hex: "6B9BD1"),
            Color(hex: "E57373"),
            Color(hex: "FFB74D"),
            Color(hex: "BA68C8"),
            Color(hex: "4DB6AC")
        ]

        let hash = abs(message.senderId.hashValue)
        return colors[hash % colors.count]
    }
}

// Custom Shape for message bubble corners
struct BubbleShape: Shape {
    var isFromCurrentUser: Bool
    var position: MessagePositionInSequence
    
    func path(in rect: CGRect) -> Path {
        let cornerRadius = UIStyleGuide.CornerRadius.large
        
        var corners: UIRectCorner = []
        
        switch position {
        case .single:
            corners = .allCorners
        case .first:
            corners.insert(.topLeft)
            corners.insert(.topRight)
            if isFromCurrentUser {
                corners.insert(.bottomLeft)
            } else {
                corners.insert(.bottomRight)
            }
        case .middle:
            if isFromCurrentUser {
                corners.insert(.topLeft)
                corners.insert(.bottomLeft)
            } else {
                corners.insert(.topRight)
                corners.insert(.bottomRight)
            }
        case .last:
            corners.insert(.bottomLeft)
            corners.insert(.bottomRight)
            if isFromCurrentUser {
                corners.insert(.topLeft)
            } else {
                corners.insert(.topRight)
            }
        }
        
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        
        return Path(path.cgPath)
    }
}

extension HorizontalAlignment {
    func toFrameAlignment() -> Alignment {
        switch self {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        default:
            return .center
        }
    }
}

// MARK: - Preview

#Preview("Sent Message") {
    VStack(spacing: 16) {
        MessageBubbleView(
            message: Message(
                id: "1",
                senderId: "current-user",
                senderName: "John Doe",
                senderPhotoURL: nil,
                text: "Hello! How are you doing today?",
                timestamp: Date(),
                status: .read,
                readBy: [:],
                deliveredTo: [:],
                localId: nil
            ),
            isFromCurrentUser: true,
            position: .single,
            showSenderName: false,
            conversation: nil
        )

        MessageBubbleView(
            message: Message(
                id: "2",
                senderId: "current-user",
                senderName: "John Doe",
                senderPhotoURL: nil,
                text: "This is a sent message",
                timestamp: Date(),
                status: .delivered,
                readBy: [:],
                deliveredTo: [:],
                localId: nil
            ),
            isFromCurrentUser: true,
            position: .single,
            showSenderName: false,
            conversation: nil
        )
    }
    .padding()
    .background(UIStyleGuide.Colors.cardBackground)
}

#Preview("Received Message") {
    VStack(alignment: .leading, spacing: 2) {
        MessageBubbleView(
            message: Message(
                id: "3",
                senderId: "other-user",
                senderName: "Jane Smith",
                senderPhotoURL: nil,
                text: "I'm doing great, thanks! How about you?",
                timestamp: Date(),
                status: .delivered,
                readBy: [:],
                deliveredTo: [:],
                localId: nil
            ),
            isFromCurrentUser: false,
            position: .first,
            showSenderName: true,
            conversation: nil
        )

        MessageBubbleView(
            message: Message(
                id: "5",
                senderId: "other-user",
                senderName: "Jane Smith",
                senderPhotoURL: nil,
                text: "This is a middle message.",
                timestamp: Date(),
                status: .delivered,
                readBy: [:],
                deliveredTo: [:],
                localId: nil
            ),
            isFromCurrentUser: false,
            position: .middle,
            showSenderName: false,
            conversation: nil
        )

        MessageBubbleView(
            message: Message(
                id: "4",
                senderId: "other-user",
                senderName: "Jane Smith",
                senderPhotoURL: nil,
                text: "This is a received message with a longer text to show wrapping behavior in the chat bubble",
                timestamp: Date(),
                status: .delivered,
                readBy: [:],
                deliveredTo: [:],
                localId: nil
            ),
            isFromCurrentUser: false,
            position: .last,
            showSenderName: false,
            conversation: nil
        )
    }
    .padding()
    .background(UIStyleGuide.Colors.cardBackground)
}
