//
//  UsersListView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI
import SwiftData

struct UsersListView: View {

    // MARK: - Environment

    @StateObject private var viewModel = UsersViewModel()
    @EnvironmentObject var authService: AuthService
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedUser: User?
    @State private var selectedConversation: Conversation?
    @State private var showChat = false
    @State private var isCreatingConversation = false
    @State private var showError = false
    @State private var errorMessage: String?

    // MARK: - Services

    @State private var conversationService: ConversationService?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                UIStyleGuide.Colors.background
                    .edgesIgnoringSafeArea(.all)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if viewModel.isLoading && viewModel.filteredUsers.isEmpty {
                            ProgressView()
                                .padding(40)
                        } else if viewModel.filteredUsers.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)

                                Text("No Users Found")
                                    .font(.system(size: 18, weight: .semibold))

                                Button {
                                    Task {
                                        await viewModel.refresh()
                                    }
                                } label: {
                                    Text("Refresh")
                                        .secondaryButtonStyle()
                                        .frame(width: 200)
                                }
                            }
                            .padding(40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredUsers) { user in
                                    Button {
                                        handleUserTap(user: user)
                                    } label: {
                                        UserRowView(user: user)
                                    }
                                    .disabled(isCreatingConversation)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                    }
                }

                // Loading overlay
                if isCreatingConversation {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: UIStyleGuide.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)

                        Text("Starting conversation...")
                            .font(UIStyleGuide.Typography.bodySmall)
                            .foregroundColor(.white)
                    }
                    .padding(UIStyleGuide.Spacing.xl)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(UIStyleGuide.CornerRadius.medium)
                }
            }
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search users")
            .onChange(of: searchText) { _, newValue in
                viewModel.searchQuery = newValue
            }
            .sheet(isPresented: $showChat) {
                if let conversation = selectedConversation {
                    chatViewPlaceholder(conversation: conversation)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .onAppear {
                setupServices()
                viewModel.loadUsers()
                viewModel.startListening()
            }
        }
    }

    // MARK: - Chat View Placeholder

    private func chatViewPlaceholder(conversation: Conversation) -> some View {
        NavigationStack {
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

                if let userName = selectedUser?.displayName {
                    Text(userName)
                        .font(UIStyleGuide.Typography.bodyBold)
                        .foregroundColor(UIStyleGuide.Colors.textPrimary)
                        .padding(.top, UIStyleGuide.Spacing.md)
                }

                Spacer()
            }
            .navigationTitle(selectedUser?.displayName ?? "Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showChat = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(UIStyleGuide.Colors.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func setupServices() {
        let localStorageService = LocalStorageService(modelContext: modelContext)
        conversationService = ConversationService(localStorageService: localStorageService)
    }

    private func handleUserTap(user: User) {
        guard let currentUserId = authService.currentUser?.id else {
            errorMessage = "You must be signed in"
            showError = true
            return
        }

        guard let service = conversationService else {
            errorMessage = "Service not ready"
            showError = true
            return
        }

        selectedUser = user
        isCreatingConversation = true

        Task {
            do {
                // Create or get conversation
                let conversationId = try await service.createOrGetConversation(
                    participantIds: [currentUserId, user.id]
                )

                // Get the full conversation object
                let conversation = try await service.getConversation(id: conversationId)

                await MainActor.run {
                    isCreatingConversation = false
                    selectedConversation = conversation
                    showChat = true
                }
            } catch {
                await MainActor.run {
                    isCreatingConversation = false
                    errorMessage = "Failed to start conversation: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    UsersListView()
        .environmentObject(AuthService())
        .modelContainer(for: [LocalMessage.self, LocalConversation.self])
}

#Preview {
    UsersListView()
        .environmentObject(AuthService())
}

