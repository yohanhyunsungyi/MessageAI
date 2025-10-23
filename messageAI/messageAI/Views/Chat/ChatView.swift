//
//  ChatView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI
import Combine

struct ChatView: View {
    @EnvironmentObject private var notificationService: NotificationService
    @State private var scrollProxy: ScrollViewProxy?
    @State private var hasInitialized = false
    @StateObject private var viewModelWrapper = ChatViewModelWrapper()

    let conversationId: String
    let localStorageService: LocalStorageService?
    let sharedMessageService: MessageService?

    init(
        conversationId: String,
        localStorageService: LocalStorageService? = nil,
        sharedMessageService: MessageService? = nil
    ) {
        self.conversationId = conversationId
        self.localStorageService = localStorageService
        self.sharedMessageService = sharedMessageService
    }

    private var viewModel: ChatViewModel? {
        viewModelWrapper.viewModel
    }

    var body: some View {
        ZStack {
            UIStyleGuide.Colors.cardBackground
                .ignoresSafeArea()

            if let viewModel = viewModel {
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
                    if let vm = viewModelWrapper.viewModel {
                        MessageInputView(
                            text: Binding(
                                get: { vm.messageText },
                                set: { newValue in
                                    vm.messageText = newValue
                                }
                            ),
                            canSend: vm.canSendMessage,
                            onSend: {
                                Task {
                                    await vm.sendMessage()
                                }
                            },
                            onTextChanged: {
                                vm.onMessageTextChanged()
                            }
                        )
                        .background(Color.white)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(viewModel?.navigationTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel?.navigationTitle ?? "")
                    .font(UIStyleGuide.Typography.bodyBold)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)
            }
        }
        .task {
            if !hasInitialized {
                setupViewModel()
                hasInitialized = true
            }
            if let vm = viewModel {
                await vm.onAppear()
            }
        }
        .onDisappear {
            viewModel?.onDisappear()
        }
        .alert("Error", isPresented: .constant(viewModel?.errorMessage != nil)) {
            Button("OK") {
                viewModelWrapper.viewModel?.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel?.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func setupViewModel() {
        let vm = ChatViewModel(
            conversationId: conversationId,
            messageService: sharedMessageService,
            localStorageService: localStorageService,
            notificationService: notificationService
        )
        viewModelWrapper.setViewModel(vm)
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel?.errorMessage != nil {
                        errorStateView
                    } else if viewModel?.isLoading == true && viewModel?.messages.isEmpty == true {
                        loadingView
                    } else if viewModel?.messages.isEmpty == true {
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
            .onChange(of: viewModel?.messages.count ?? 0) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private var messagesContent: some View {
        ForEach(Array((viewModel?.messages ?? []).enumerated()), id: \.element.id) { index, message in
            VStack(alignment: .leading, spacing: 0) {
                // Show date divider if needed
                if shouldShowDateDivider(at: index) {
                    dateDivider(for: message.timestamp)
                }

                // Message bubble
                MessageBubbleView(
                    message: message,
                    isFromCurrentUser: viewModel?.isMessageFromCurrentUser(message) ?? false,
                    position: getMessagePosition(at: index),
                    showSenderName: viewModel?.shouldShowSenderName(for: message, at: index) ?? false,
                    conversation: viewModel?.conversation
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

            if let errorMessage = viewModel?.errorMessage {
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
        guard index > 0, let messages = viewModel?.messages, messages.count > index else { return true }

        let currentMessage = messages[index]
        let previousMessage = messages[index - 1]

        return !Calendar.current.isDate(
            currentMessage.timestamp,
            inSameDayAs: previousMessage.timestamp
        )
    }

    private func getMessagePosition(at index: Int) -> MessagePositionInSequence {
        guard let viewModel = viewModel, let messages = viewModel.messages as? [Message], messages.count > index else {
            return .single
        }

        let currentMessage = messages[index]
        let isFromCurrentUser = viewModel.isMessageFromCurrentUser(currentMessage)

        let prevMessage = (index > 0) ? messages[index - 1] : nil
        let nextMessage = (index < messages.count - 1) ? messages[index + 1] : nil

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
        guard let lastMessage = viewModel?.messages.last else { return }

        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }

    private func getTypingUserNames() -> [String] {
        guard let conversation = viewModel?.conversation else { return [] }

        return viewModel?.typingUsers.compactMap { userId in
            conversation.participantNames[userId]
        } ?? []
    }
}

// MARK: - Wrapper

@MainActor
class ChatViewModelWrapper: ObservableObject {
    @Published var viewModel: ChatViewModel? {
        didSet {
            // Cancel previous subscription
            cancellable?.cancel()

            // Forward objectWillChange from viewModel to wrapper
            // This makes the view re-render when viewModel's @Published properties change
            cancellable = viewModel?.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }

    private var cancellable: AnyCancellable?

    init() {
        self.viewModel = nil
    }

    func setViewModel(_ viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatView(conversationId: "preview-conversation-id")
            .environmentObject(NotificationService())
    }
}
