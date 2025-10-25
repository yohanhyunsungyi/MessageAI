//
//  AIAssistantChatView.swift
//  messageAI
//
//  AI Assistant chat interface
//  Natural language command UI for AI features
//

import SwiftUI

struct AIAssistantChatView: View {
    @StateObject private var service = AIAssistantService()
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?

    // Suggested prompts for first-time users
    private let suggestedPrompts = [
        "What are my tasks?",
        "Search for deployment",
        "Summarize recent conversations"
    ]

    var body: some View {
        ZStack {
            UIStyleGuide.Colors.cardBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages List
                messagesList

                // Suggested Prompts (show when no user messages)
                if !hasUserMessages {
                    suggestedPromptsView
                        .padding(.horizontal, UIStyleGuide.Spacing.md)
                        .padding(.bottom, UIStyleGuide.Spacing.sm)
                }

                // Message Input
                messageInput
                    .background(Color.white)
            }
        }
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 4) {
                    Text("⚡")
                        .font(.system(size: 20))
                    Text("AI Assistant")
                        .font(UIStyleGuide.Typography.bodyBold)
                        .foregroundColor(UIStyleGuide.Colors.textPrimary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        service.clearHistory()
                    } label: {
                        Label("Clear History", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color.black)
                }
            }
        }
        .alert("Error", isPresented: .constant(service.errorMessage != nil)) {
            Button("OK") {
                service.errorMessage = nil
            }
        } message: {
            if let errorMessage = service.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: UIStyleGuide.Spacing.md) {
                    ForEach(service.messages) { message in
                        messageRow(message)
                            .id(message.id)
                    }

                    // Loading indicator
                    if service.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Thinking...")
                                .font(UIStyleGuide.Typography.caption)
                                .foregroundColor(UIStyleGuide.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, UIStyleGuide.Spacing.md)
                    }
                }
                .padding(.horizontal, UIStyleGuide.Spacing.md)
                .padding(.vertical, UIStyleGuide.Spacing.md)
            }
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: service.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    // MARK: - Message Row

    private func messageRow(_ message: AIAssistantMessage) -> some View {
        HStack(alignment: .top, spacing: UIStyleGuide.Spacing.sm) {
            if message.isFromUser {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                // Message bubble
                Text(message.text)
                    .font(UIStyleGuide.Typography.body)
                    .foregroundColor(message.isFromUser ? .white : UIStyleGuide.Colors.textPrimary)
                    .padding(.horizontal, UIStyleGuide.Spacing.md)
                    .padding(.vertical, UIStyleGuide.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isFromUser ?
                                  Color.blue :
                                  Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                message.isFromUser ? Color.clear : UIStyleGuide.Colors.border,
                                lineWidth: 1
                            )
                    )

                // Timestamp
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(UIStyleGuide.Typography.caption)
                    .foregroundColor(UIStyleGuide.Colors.textTertiary)
                    .padding(.horizontal, 4)
            }

            if !message.isFromUser {
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Suggested Prompts

    private var suggestedPromptsView: some View {
        VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.sm) {
            Text("Try asking:")
                .font(UIStyleGuide.Typography.caption)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)

            ForEach(suggestedPrompts, id: \.self) { prompt in
                Button {
                    messageText = prompt
                } label: {
                    HStack {
                        Text(prompt)
                            .font(UIStyleGuide.Typography.bodySmall)
                            .foregroundColor(Color.blue)
                        Spacer()
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(Color.blue)
                    }
                    .padding(.horizontal, UIStyleGuide.Spacing.md)
                    .padding(.vertical, UIStyleGuide.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }

    // MARK: - Message Input

    private var messageInput: some View {
        HStack(spacing: UIStyleGuide.Spacing.sm) {
            // Text field
            TextField("Ask me anything...", text: $messageText, axis: .vertical)
                .font(UIStyleGuide.Typography.body)
                .lineLimit(1...5)
                .padding(.horizontal, UIStyleGuide.Spacing.md)
                .padding(.vertical, UIStyleGuide.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(UIStyleGuide.Colors.cardBackground)
                )

            // Send button
            Button {
                sendMessage()
            } label: {
                Image(systemName: canSend ? "arrow.up.circle.fill" : "arrow.up.circle")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? Color.blue : UIStyleGuide.Colors.textTertiary)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, UIStyleGuide.Spacing.md)
        .padding(.vertical, UIStyleGuide.Spacing.sm)
    }

    // MARK: - Helper Methods

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !service.isLoading
    }

    private var hasUserMessages: Bool {
        service.messages.contains { $0.isFromUser }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""

        Task {
            await service.sendMessage(text)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = service.messages.last else { return }

        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AIAssistantChatView()
    }
}
