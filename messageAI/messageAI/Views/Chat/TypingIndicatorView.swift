//
//  TypingIndicatorView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

struct TypingIndicatorView: View {
    let typingUserNames: [String]

    @State private var animationPhase = 0

    private var displayText: String {
        let count = typingUserNames.count

        if count == 0 {
            return ""
        } else if count == 1 {
            return "\(typingUserNames[0]) is typing"
        } else if count == 2 {
            return "\(typingUserNames[0]) and \(typingUserNames[1]) are typing"
        } else if count == 3 {
            return "3 people are typing"
        } else if count == 4 {
            return "4 people are typing"
        } else {
            return "\(count) people are typing"
        }
    }

    var body: some View {
        HStack(spacing: UIStyleGuide.Spacing.sm) {
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(UIStyleGuide.Colors.textTertiary.opacity(0.3))
                    .frame(width: 32, height: 32)

                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)
            }

            // Typing text and dots
            HStack(spacing: UIStyleGuide.Spacing.xs) {
                Text(displayText)
                    .font(UIStyleGuide.Typography.bodySmall)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)

                typingDots
            }
            .padding(.horizontal, UIStyleGuide.Spacing.md)
            .padding(.vertical, UIStyleGuide.Spacing.sm)
            .background(Color.white)
            .cornerRadius(UIStyleGuide.CornerRadius.large)
            .lightShadow()

            Spacer()
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Typing Dots Animation

    private var typingDots: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(UIStyleGuide.Colors.textSecondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .opacity(animationPhase == index ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: false),
                        value: animationPhase
                    )
            }
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Preview

#Preview("Single User") {
    VStack {
        Spacer()
        TypingIndicatorView(typingUserNames: ["John Doe"])
            .padding()
    }
    .background(UIStyleGuide.Colors.cardBackground)
}

#Preview("Two Users") {
    VStack {
        Spacer()
        TypingIndicatorView(typingUserNames: ["John Doe", "Jane Smith"])
            .padding()
    }
    .background(UIStyleGuide.Colors.cardBackground)
}

#Preview("Multiple Users") {
    VStack {
        Spacer()
        TypingIndicatorView(typingUserNames: ["John Doe", "Jane Smith", "Bob Johnson"])
            .padding()
    }
    .background(UIStyleGuide.Colors.cardBackground)
}
