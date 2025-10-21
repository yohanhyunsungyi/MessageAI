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
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var conversationService: ConversationService?
    @State private var viewModel: ConversationsViewModel?
    @State private var selectedConversation: Conversation?
    @State private var showingChatView = false
    @State private var showError = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                UIStyleGuide.Colors.background
                    .ignoresSafeArea()
                
                if let viewModel = viewModel {
                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        // Loading state
                        loadingView
                    } else if viewModel.filteredConversations.isEmpty {
                        // Empty state
                        emptyStateView(viewModel: viewModel)
                    } else {
                        // Conversations list
                        conversationsListView(viewModel: viewModel)
                    }
                } else {
                    // Initializing
                    loadingView
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: Binding(
                    get: { viewModel?.searchText ?? "" },
                    set: { viewModel?.searchText = $0 }
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search conversations"
            )
            .refreshable {
                if let viewModel = viewModel {
                    await viewModel.refresh()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    viewModel?.clearError()
                }
            } message: {
                if let error = viewModel?.errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showingChatView) {
                if let conversation = selectedConversation {
                    // ChatView placeholder
                    chatViewPlaceholder(conversation: conversation)
                }
            }
            .onAppear {
                if viewModel == nil {
                    setupViewModel()
                }
            }
            .onDisappear {
                viewModel?.stopListening()
            }
            .onChange(of: viewModel?.errorMessage) { _, newValue in
                showError = newValue != nil
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
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredConversations) { conversation in
                    Button {
                        selectedConversation = conversation
                        showingChatView = true
                    } label: {
                        ConversationRowView(
                            conversation: conversation,
                            displayName: viewModel.getConversationName(conversation),
                            subtitle: viewModel.getConversationSubtitle(conversation),
                            photoURL: viewModel.getConversationPhotoURL(conversation)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Divider
                    if conversation.id != viewModel.filteredConversations.last?.id {
                        Divider()
                            .padding(.leading, 88) // Align with text
                    }
                }
            }
        }
    }

    // MARK: - Chat View Placeholder
    
    private func chatViewPlaceholder(conversation: Conversation) -> some View {
        let conversationName = viewModel?.getConversationName(conversation) ?? "Chat"
        
        return NavigationStack {
            VStack(spacing: UIStyleGuide.Spacing.lg) {
                Spacer()
                
                Image(systemName: "ellipsis.message.fill")
                    .font(.system(size: 60))
                    .foregroundColor(UIStyleGuide.Colors.primary)
                
                Text("Chat View")
                    .font(UIStyleGuide.Typography.title)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)
                
                Text("Coming in PR #13")
                    .font(UIStyleGuide.Typography.body)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)
                
                Text(conversationName)
                    .font(UIStyleGuide.Typography.bodyBold)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)
                    .padding(.top, UIStyleGuide.Spacing.md)
                
                Spacer()
            }
            .navigationTitle(conversationName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingChatView = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(UIStyleGuide.Colors.textPrimary)
                    }
                }
            }
        }
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
        viewModel = vm
        
        // Load data
        Task {
            await vm.loadConversations()
            vm.startListening()
        }
    }
}

// MARK: - Preview

#Preview {
    ConversationsListView()
        .environmentObject(AuthService())
        .modelContainer(for: [LocalMessage.self, LocalConversation.self])
}


