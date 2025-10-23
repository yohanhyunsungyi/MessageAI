//
//  ConversationsListView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI
import SwiftData
import Combine

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
    @StateObject private var vmWrapper = ConversationsViewModelWrapper()
    @State private var showError = false
    @State private var showCreateGroup = false
    @State private var navigationPath = NavigationPath()
    @State private var pendingNavigationConversationId: String?

    private var conversationsViewModel: ConversationsViewModel? {
        vmWrapper.viewModel
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            mainContent
                .navigationTitle("Messages")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
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
                .searchable(
                    text: searchTextBinding,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search conversations"
                )
                .refreshable {
                    await conversationsViewModel?.refresh()
                }
                .navigationDestination(for: String.self) { conversationId in
                    ChatView(
                        conversationId: conversationId,
                        localStorageService: LocalStorageService(modelContext: modelContext),
                        sharedMessageService: conversationsViewModel?.getSharedMessageService()
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
                        conversationsViewModel?.clearError()
                    }
                } message: {
                    if let error = conversationsViewModel?.errorMessage {
                        Text(error)
                    }
                }
                .task {
                    if !hasSetup {
                        setupViewModel()
                        hasSetup = true
                    }
                }
                .onAppear {
                    // Restart listener when view appears (handles tab switches)
                    conversationsViewModel?.startListening()
                }
                .onDisappear {
                    conversationsViewModel?.stopListening()
                }
                .onChange(of: conversationsViewModel?.errorMessage) { _, newValue in
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

            if let viewModel = conversationsViewModel {
                contentView(viewModel: viewModel)
            } else {
                loadingView
            }
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
            get: { conversationsViewModel?.searchText ?? "" },
            set: { conversationsViewModel?.searchText = $0 }
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
        List(viewModel.filteredConversations, id: \.id) { conversation in
            NavigationLink(value: conversation.id) {
                ConversationRowView(
                    conversation: conversation,
                    displayName: viewModel.getConversationName(conversation),
                    subtitle: viewModel.getConversationSubtitle(conversation),
                    photoURL: viewModel.getConversationPhotoURL(conversation),
                    unreadCount: 0 // TODO: Calculate actual unread count from MessageService
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .background(UIStyleGuide.Colors.background)
    }

    // MARK: - Helper Methods

    private func setupViewModel() {
        // Initialize services with proper ModelContext
        let localStorageService = LocalStorageService(modelContext: modelContext)
        let service = ConversationService(
            localStorageService: localStorageService,
            notificationService: notificationService
        )
        let viewModel = ConversationsViewModel(
            conversationService: service,
            authService: authService,
            notificationService: notificationService
        )

        // Initialize UsersViewModel for group creation
        let userService = UserService()
        let usersVM = UsersViewModel(userService: userService)

        // Update state
        conversationService = service
        usersViewModel = usersVM
        vmWrapper.viewModel = viewModel

        // Load data
        Task {
            await viewModel.loadConversations()
            viewModel.startListening()
        }
    }
}

// MARK: - Wrapper

@MainActor
class ConversationsViewModelWrapper: ObservableObject {
    @Published var viewModel: ConversationsViewModel? {
        didSet {
            // Forward ViewModel's objectWillChange to this wrapper
            cancellable = viewModel?.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }

    private var cancellable: AnyCancellable?
}

// MARK: - Preview

#Preview {
    ConversationsListView()
        .environmentObject(AuthService())
        .modelContainer(for: [LocalMessage.self, LocalConversation.self])
}
