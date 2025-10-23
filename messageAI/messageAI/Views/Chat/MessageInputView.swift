//
//  MessageInputView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let canSend: Bool
    let onSend: () -> Void
    let onTextChanged: () -> Void

    @FocusState private var isInputFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: UIStyleGuide.Spacing.sm) {
            // Text input field
            inputField

            // Send button
            sendButton
        }
        .padding(.horizontal, UIStyleGuide.Spacing.md)
        .padding(.vertical, UIStyleGuide.Spacing.sm)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(UIStyleGuide.Colors.border),
            alignment: .top
        )
    }

    // MARK: - Input Field

    private var inputField: some View {
        HStack(spacing: UIStyleGuide.Spacing.sm) {
            TextField("Type a message...", text: $text, axis: .vertical)
                .font(UIStyleGuide.Typography.body)
                .lineLimit(1...6)
                .focused($isInputFocused)
                .padding(.horizontal, UIStyleGuide.Spacing.md)
                .padding(.vertical, UIStyleGuide.Spacing.sm)
                .background(UIStyleGuide.Colors.cardBackground)
                .cornerRadius(UIStyleGuide.CornerRadius.large)
                .onChange(of: text) { _, _ in
                    onTextChanged()
                }
        }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button(action: {
            if canSend {
                onSend()
                isInputFocused = true  // Keep focus on input after sending
            }
        }, label: {
            ZStack {
                Circle()
                    .fill(canSend ? UIStyleGuide.Colors.primary : UIStyleGuide.Colors.cardBackground)
                    .frame(width: 40, height: 40)

                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(canSend ? UIStyleGuide.Colors.textPrimary : UIStyleGuide.Colors.textTertiary)
            }
        })
        .disabled(!canSend)
        .animation(.easeInOut(duration: 0.2), value: canSend)
    }
}

// MARK: - Preview

#Preview("Empty Input") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            canSend: false,
            onSend: {},
            onTextChanged: {}
        )
    }
}

#Preview("With Text") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant("Hello, this is a test message"),
            canSend: true,
            onSend: {},
            onTextChanged: {}
        )
    }
}

#Preview("Multi-line") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(
                "This is a longer message that spans multiple lines " +
                "to demonstrate the text wrapping behavior of the input field"
            ),
            canSend: true,
            onSend: {},
            onTextChanged: {}
        )
    }
}
