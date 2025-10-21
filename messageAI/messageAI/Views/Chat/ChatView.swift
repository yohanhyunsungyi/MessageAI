//
//  ChatView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject private var notificationService: NotificationService
    @State private var scrollProxy: ScrollViewProxy?

    init(conversationId: String, localStorageService: LocalStorageService? = nil, notificationService: NotificationService? = nil) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversationId: conversationId, localStorageService: localStorageService, notificationService: notificationService))
    }

    var body: some View {
        ZStack {
            UIStyleGuide.Colors.cardBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages List
                messagesList

                // Typing Indicator
                if !viewModel.typingUsers.isEmpty {
                    TypingIndicatorView(
                        typingUserNames: getTypingUserNames()
                    )
                    .padding(.horizontal, UIStyleGuide.Spacing.md)
                    .padding(.top, UIStyleGuide.Spacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Message Input
                MessageInputView(
                    text: $viewModel.messageText,
                    canSend: viewModel.canSendMessage,
                    onSend: {
                        Task {
                            await viewModel.sendMessage()
                        }
                    },
                    onTextChanged: {
                        viewModel.onMessageTextChanged()
                    }
                )
                .background(Color.white)
            }
        }
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.navigationTitle)
                        .font(UIStyleGuide.Typography.bodyBold)
                        .foregroundColor(UIStyleGuide.Colors.textPrimary)

                    if let subtitle = viewModel.navigationSubtitle {
                        Text(subtitle)
                            .font(UIStyleGuide.Typography.caption)
                            .foregroundColor(UIStyleGuide.Colors.textSecondary)
                    }
                }
            }
        }
        .task { await viewModel.onAppear() }
        .onDisappear {
            viewModel.onDisappear()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.errorMessage != nil {
                        errorStateView
                    } else if viewModel.isLoading && viewModel.messages.isEmpty {
                        loadingView
                    } else if viewModel.messages.isEmpty {
                        emptyStateView
                    } else {
                        messagesContent
                    }
                }
                .padding(.horizontal, UIStyleGuide.Spacing.md)
                .padding(.vertical, UIStyleGuide.Spacing.md)
            }
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private var messagesContent: some View {
        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
            VStack(alignment: .leading, spacing: 0) {
                // Show date divider if needed
                if shouldShowDateDivider(at: index) {
                    dateDivider(for: message.timestamp)
                }

                // Message bubble
                MessageBubbleView(
                    message: message,
                    isFromCurrentUser: viewModel.isMessageFromCurrentUser(message),
                    position: getMessagePosition(at: index),
                    showSenderName: viewModel.shouldShowSenderName(for: message, at: index),
                    conversation: viewModel.conversation
                )
                .id(message.id)
                .padding(.top, topPaddingForMessage(at: index))
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: UIStyleGuide.Spacing.md) {
            Spacer()

            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(UIStyleGuide.Colors.textTertiary)

            Text("No messages yet")
                .font(UIStyleGuide.Typography.title3)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)

            Text("Start the conversation by sending a message")
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(UIStyleGuide.Spacing.xl)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading messages...")
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
                .padding(.top, UIStyleGuide.Spacing.sm)
            Spacer()
        }
    }

    // MARK: - Error State View

    private var errorStateView: some View {
        VStack(spacing: UIStyleGuide.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(UIStyleGuide.Colors.cardBackground)
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            }

            Text("Unable to load chat")
                .font(UIStyleGuide.Typography.title3)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(UIStyleGuide.Typography.bodySmall)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(UIStyleGuide.Spacing.md)
    }

    // MARK: - Date Divider

    private func dateDivider(for date: Date) -> some View {
        Text(date.chatSectionHeader)
            .font(UIStyleGuide.Typography.caption)
            .foregroundColor(UIStyleGuide.Colors.textSecondary)
            .padding(.horizontal, UIStyleGuide.Spacing.md)
            .padding(.vertical, UIStyleGuide.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.8))
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, UIStyleGuide.Spacing.md)
    }

    // MARK: - Helper Methods

    private func shouldShowDateDivider(at index: Int) -> Bool {
        guard index > 0 else { return true }

        let currentMessage = viewModel.messages[index]
        let previousMessage = viewModel.messages[index - 1]

        return !Calendar.current.isDate(
            currentMessage.timestamp,
            inSameDayAs: previousMessage.timestamp
        )
    }

    private func getMessagePosition(at index: Int) -> MessagePositionInSequence {
        let currentMessage = viewModel.messages[index]
        let isFromCurrentUser = viewModel.isMessageFromCurrentUser(currentMessage)

        let prevMessage = (index > 0) ? viewModel.messages[index - 1] : nil
        let nextMessage = (index < viewModel.messages.count - 1) ? viewModel.messages[index + 1] : nil

        let isPrevSameSender = (prevMessage?.senderId == currentMessage.senderId) && !shouldShowDateDivider(at: index)
        let isNextSameSender = (nextMessage?.senderId == currentMessage.senderId) && (nextMessage != nil ? !shouldShowDateDivider(at: index + 1) : false)

        if isPrevSameSender && isNextSameSender {
            return .middle
        } else if isPrevSameSender {
            return .last
        } else if isNextSameSender {
            return .first
        } else {
            return .single
        }
    }
    
    private func topPaddingForMessage(at index: Int) -> CGFloat {
        let position = getMessagePosition(at: index)
        switch position {
        case .single, .first:
            return UIStyleGuide.Spacing.sm
        case .middle, .last:
            return 2 // Compact spacing for grouped messages
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = viewModel.messages.last else { return }

        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }

    private func getTypingUserNames() -> [String] {
        guard let conversation = viewModel.conversation else { return [] }

        return viewModel.typingUsers.compactMap { userId in
            conversation.participantNames[userId]
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatView(conversationId: "preview-conversation-id")
    }
}
