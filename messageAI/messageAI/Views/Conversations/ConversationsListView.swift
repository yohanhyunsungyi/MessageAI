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
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var hasSetup = false
    @State private var conversationService: ConversationService?
    @StateObject private var vmWrapper = ConversationsViewModelWrapper()
    @State private var showError = false
    
    private var conversationsViewModel: ConversationsViewModel? {
        vmWrapper.vm
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                UIStyleGuide.Colors.background
                    .ignoresSafeArea()

                if let vm = conversationsViewModel {
                    let _ = print("🎨 Rendering: \(vm.filteredConversations.count) filtered conversations")
                    
                    if vm.isLoading && vm.conversations.isEmpty {
                        loadingView
                    } else if vm.filteredConversations.isEmpty {
                        emptyStateView(viewModel: vm)
                    } else {
                        conversationsListView(viewModel: vm)
                    }
                } else {
                    let _ = print("🎨 ConversationsListView: ViewModel is nil")
                    loadingView
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: Binding(
                    get: { conversationsViewModel?.searchText ?? "" },
                    set: { conversationsViewModel?.searchText = $0 }
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search conversations"
            )
            .refreshable {
                await conversationsViewModel?.refresh()
            }
            .navigationDestination(for: String.self) { conversationId in
                ChatView(
                    conversationId: conversationId,
                    localStorageService: LocalStorageService(modelContext: modelContext)
                )
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
            .onDisappear {
                conversationsViewModel?.stopListening()
            }
            .onChange(of: conversationsViewModel?.errorMessage) { _, newValue in
                showError = newValue != nil
            }
            .onChange(of: conversationsViewModel?.conversations.count ?? 0) { oldValue, newValue in
                print("🔄 Conversations count changed: \(oldValue) → \(newValue)")
            }
        }
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
        let _ = print("📋 Rendering list with \(viewModel.filteredConversations.count) items")
        
        return List(viewModel.filteredConversations, id: \.id) { conversation in
            NavigationLink(value: conversation.id) {
                ConversationRowView(
                    conversation: conversation,
                    displayName: viewModel.getConversationName(conversation),
                    subtitle: viewModel.getConversationSubtitle(conversation),
                    photoURL: viewModel.getConversationPhotoURL(conversation)
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
        let service = ConversationService(localStorageService: localStorageService)
        let vm = ConversationsViewModel(
            conversationService: service,
            authService: authService
        )

        // Update state
        conversationService = service
        vmWrapper.vm = vm

        // Load data
        Task {
            await vm.loadConversations()
            vm.startListening()
        }
    }
}

// MARK: - Wrapper

@MainActor
class ConversationsViewModelWrapper: ObservableObject {
    @Published var vm: ConversationsViewModel? {
        didSet {
            // Forward ViewModel's objectWillChange to this wrapper
            cancellable = vm?.objectWillChange.sink { [weak self] _ in
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
