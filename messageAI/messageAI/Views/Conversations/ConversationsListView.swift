//
//  ConversationsListView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI
import SwiftData

/// List view displaying all conversations
struct ConversationsListView: View {

    // MARK: - Environment

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var hasSetup = false
    @State private var conversationService: ConversationService?
    @State private var usersViewModel: UsersViewModel?
    @State private var showError = false
    @State private var showCreateGroup = false
    @State private var navigationPath = NavigationPath()
    @State private var pendingNavigationConversationId: String?
    @State private var showSmartSearch = false

    // MARK: - Injected ViewModel (from MainTabView for global monitoring)

    @ObservedObject private var conversationsViewModel: ConversationsViewModel

    // MARK: - Initialization

    init(conversationsViewModel: ConversationsViewModel) {
        self._conversationsViewModel = ObservedObject(wrappedValue: conversationsViewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            mainContent
                .navigationTitle("Messages")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showSmartSearch = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14, weight: .medium))
                                Text("AI Search")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(UIStyleGuide.Colors.primary)
                            .clipShape(Capsule())
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showCreateGroup = true
                        } label: {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(UIStyleGuide.Colors.primary)
                                .clipShape(Capsule())
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .buttonBorderShape(.capsule)
                    }
                }
                .sheet(isPresented: $showSmartSearch) {
                    SmartSearchView()
                }
                .refreshable {
                    await conversationsViewModel.refresh()
                }
                .navigationDestination(for: String.self) { conversationId in
                    ChatView(
                        conversationId: conversationId,
                        localStorageService: LocalStorageService(modelContext: modelContext),
                        sharedMessageService: conversationsViewModel.getSharedMessageService()
                    )
                }
                .sheet(isPresented: $showCreateGroup) {
                    NavigationStack {
                        if let usersVM = usersViewModel,
                           let conversationSvc = conversationService {
                            CreateGroupView(
                                usersViewModel: usersVM,
                                conversationService: conversationSvc,
                                onGroupCreated: { conversationId in
                                    pendingNavigationConversationId = conversationId
                                }
                            )
                        }
                    }
                }
                .onChange(of: showCreateGroup) { oldValue, newValue in
                    // Navigate to chat when sheet is dismissed and we have a pending conversation
                    if !newValue, let conversationId = pendingNavigationConversationId {
                        navigationPath.append(conversationId)
                        pendingNavigationConversationId = nil
                    }
                }
                .alert("Error", isPresented: $showError) {
                    Button("OK") {
                        conversationsViewModel.clearError()
                    }
                } message: {
                    if let error = conversationsViewModel.errorMessage {
                        Text(error)
                    }
                }
                .task {
                    if !hasSetup {
                        setupViewModel()
                        hasSetup = true
                    }
                }
                .onChange(of: conversationsViewModel.errorMessage) { _, newValue in
                    showError = newValue != nil
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: NSNotification.Name(Constants.Notifications.openConversation)
                )) { notification in
                    if let conversationId = notification.userInfo?["conversationId"] as? String {
                        print("📱 Received notification tap - navigating to: \(conversationId)")
                        navigationPath.append(conversationId)
                    }
                }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            UIStyleGuide.Colors.background
                .ignoresSafeArea()

            contentView(viewModel: conversationsViewModel)
        }
    }

    private func contentView(viewModel: ConversationsViewModel) -> some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                loadingView
            } else if viewModel.filteredConversations.isEmpty {
                emptyStateView(viewModel: viewModel)
            } else {
                conversationsListView(viewModel: viewModel)
            }
        }
    }

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { conversationsViewModel.searchText },
            set: { conversationsViewModel.searchText = $0 }
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: UIStyleGuide.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading conversations...")
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
        }
    }

    // MARK: - Empty State View

    private func emptyStateView(viewModel: ConversationsViewModel) -> some View {
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
            Text(viewModel.searchText.isEmpty ? "No Conversations Yet" : "No Results Found")
                .font(UIStyleGuide.Typography.title2)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)

            // Subtitle
            Text(viewModel.searchText.isEmpty
                 ? "Start a conversation by selecting\na user from the Users tab"
                 : "Try adjusting your search")
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()
        }
        .padding(UIStyleGuide.Spacing.md)
    }

    // MARK: - Conversations List View

    private func conversationsListView(viewModel: ConversationsViewModel) -> some View {
        List {
            // AI Assistant - Special row always at top
            aiAssistantRow

            // Regular conversations
            ForEach(viewModel.filteredConversations, id: \.id) { conversation in
                NavigationLink(value: conversation.id) {
                    ConversationRowView(
                        conversation: conversation,
                        displayName: viewModel.getConversationName(conversation),
                        subtitle: viewModel.getConversationSubtitle(conversation),
                        photoURL: viewModel.getConversationPhotoURL(conversation),
                        unreadCount: 0 // TODO: Calculate actual unread count from MessageService
                    )
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .background(UIStyleGuide.Colors.background)
    }

    // MARK: - AI Assistant Row

    private var aiAssistantRow: some View {
        NavigationLink {
            AIAssistantChatView()
        } label: {
            HStack(spacing: UIStyleGuide.Spacing.md) {
                // AI Icon - Lucid logo style (black circle with white lightning)
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 56, height: 56)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Assistant")
                        .font(UIStyleGuide.Typography.bodyBold)
                        .foregroundColor(UIStyleGuide.Colors.textPrimary)

                    Text("Ask me anything about your conversations")
                        .font(UIStyleGuide.Typography.caption)
                        .foregroundColor(UIStyleGuide.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(UIStyleGuide.Spacing.md)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(UIStyleGuide.Colors.primary)
    }

    // MARK: - Helper Methods

    private func setupViewModel() {
        // Always use injected ViewModel from MainTabView (required for global monitoring)
        // Create conversation service for group creation
        let localStorageService = LocalStorageService(modelContext: modelContext)
        let service = ConversationService(
            localStorageService: localStorageService,
            notificationService: notificationService
        )
        conversationService = service

        // Initialize UsersViewModel for group creation
        let userService = UserService()
        usersViewModel = UsersViewModel(userService: userService)

        print("📱 Using injected ConversationsViewModel with global monitoring")
    }
}

// MARK: - Preview

#Preview {
    let authService = AuthService()
    let notificationService = NotificationService()
    let localStorageService = LocalStorageService()
    let conversationService = ConversationService(
        localStorageService: localStorageService,
        notificationService: notificationService
    )
    let viewModel = ConversationsViewModel(
        conversationService: conversationService,
        authService: authService,
        notificationService: notificationService
    )

    return ConversationsListView(conversationsViewModel: viewModel)
        .environmentObject(authService)
        .environmentObject(notificationService)
        .modelContainer(for: [LocalMessage.self, LocalConversation.self])
}
