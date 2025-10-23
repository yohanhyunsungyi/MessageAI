//
//  CreateGroupView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var usersViewModel: UsersViewModel
    @StateObject private var conversationService: ConversationService

    @State private var groupName = ""
    @State private var selectedUserIds: Set<String> = []
    @State private var searchText = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let currentUserId: String
    private let onGroupCreated: ((String) -> Void)?

    init(
        usersViewModel: UsersViewModel,
        conversationService: ConversationService,
        onGroupCreated: ((String) -> Void)? = nil
    ) {
        _usersViewModel = StateObject(wrappedValue: usersViewModel)
        _conversationService = StateObject(wrappedValue: conversationService)
        self.currentUserId = FirebaseManager.shared.currentUserId ?? ""
        self.onGroupCreated = onGroupCreated
    }

    var body: some View {
        ZStack {
            UIStyleGuide.Colors.cardBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Group name input section
                groupNameSection

                Divider()
                    .padding(.vertical, UIStyleGuide.Spacing.md)

                // Selected users section
                if !selectedUserIds.isEmpty {
                    selectedUsersSection
                }

                // Users list
                usersListSection

                Spacer()

                // Create button
                createButton
            }
            .padding(.horizontal, UIStyleGuide.Spacing.lg)

            // Loading overlay
            if isCreating {
                loadingOverlay
            }
        }
        .navigationTitle("New Group")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await loadUsers()
        }
    }

    // MARK: - Group Name Section

    private var groupNameSection: some View {
        VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.sm) {
            Text("Group Name")
                .font(UIStyleGuide.Typography.bodyBold)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)

            TextField("Enter group name", text: $groupName)
                .font(UIStyleGuide.Typography.body)
                .padding(UIStyleGuide.Spacing.md)
                .background(Color.white)
                .cornerRadius(UIStyleGuide.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: UIStyleGuide.CornerRadius.medium)
                        .stroke(UIStyleGuide.Colors.border, lineWidth: 1)
                )
        }
        .padding(.top, UIStyleGuide.Spacing.lg)
    }

    // MARK: - Selected Users Section

    private var selectedUsersSection: some View {
        VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.sm) {
            HStack {
                Text("Selected")
                    .font(UIStyleGuide.Typography.bodyBold)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)

                Text("\(selectedUserIds.count + 1) members")
                    .font(UIStyleGuide.Typography.bodySmall)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIStyleGuide.Spacing.sm) {
                    // Current user chip
                    SelectedUserChip(name: "You", isRemovable: false, onRemove: nil)

                    // Selected users chips
                    ForEach(Array(selectedUserIds), id: \.self) { userId in
                        if let user = usersViewModel.users.first(where: { $0.id == userId }) {
                            SelectedUserChip(name: user.displayName, isRemovable: true) {
                                selectedUserIds.remove(userId)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, UIStyleGuide.Spacing.sm)
    }

    // MARK: - Users List Section

    private var usersListSection: some View {
        VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.sm) {
            Text("Add Members")
                .font(UIStyleGuide.Typography.bodyBold)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)
                .padding(.top, UIStyleGuide.Spacing.md)

            // Search bar
            searchBar

            // Users list
            if usersViewModel.isLoading {
                loadingUsersView
            } else if filteredUsers.isEmpty {
                emptyUsersView
            } else {
                usersList
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(UIStyleGuide.Colors.textSecondary)

            TextField("Search users", text: $searchText)
                .font(UIStyleGuide.Typography.body)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(UIStyleGuide.Colors.textSecondary)
                }
            }
        }
        .padding(UIStyleGuide.Spacing.sm)
        .background(Color.white)
        .cornerRadius(UIStyleGuide.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: UIStyleGuide.CornerRadius.medium)
                .stroke(UIStyleGuide.Colors.border, lineWidth: 1)
        )
    }

    private var usersList: some View {
        ScrollView {
            LazyVStack(spacing: UIStyleGuide.Spacing.xs) {
                ForEach(filteredUsers) { user in
                    UserSelectionRow(
                        user: user,
                        isSelected: selectedUserIds.contains(user.id),
                        onToggle: { toggleUserSelection(user: user) }
                    )
                }
            }
            .padding(.top, UIStyleGuide.Spacing.sm)
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            Task {
                await createGroup()
            }
        } label: {
            HStack {
                Text("Create Group")
                    .font(UIStyleGuide.Typography.bodyBold)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)

                if canCreateGroup {
                    Text("(\(selectedUserIds.count + 1))")
                        .font(UIStyleGuide.Typography.bodySmall)
                        .foregroundColor(UIStyleGuide.Colors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(UIStyleGuide.Spacing.md)
            .background(canCreateGroup ? UIStyleGuide.Colors.primary : UIStyleGuide.Colors.border)
            .cornerRadius(UIStyleGuide.CornerRadius.large)
        }
        .disabled(!canCreateGroup)
        .padding(.vertical, UIStyleGuide.Spacing.md)
    }

    // MARK: - Empty & Loading States

    private var loadingUsersView: some View {
        VStack(spacing: UIStyleGuide.Spacing.md) {
            ProgressView()
            Text("Loading users...")
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(UIStyleGuide.Spacing.xl)
    }

    private var emptyUsersView: some View {
        VStack(spacing: UIStyleGuide.Spacing.md) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(UIStyleGuide.Colors.textTertiary)

            Text(searchText.isEmpty ? "No users found" : "No results")
                .font(UIStyleGuide.Typography.body)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)

            if !searchText.isEmpty {
                Text("Try a different search")
                    .font(UIStyleGuide.Typography.bodySmall)
                    .foregroundColor(UIStyleGuide.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(UIStyleGuide.Spacing.xl)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: UIStyleGuide.Spacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Creating group...")
                    .font(UIStyleGuide.Typography.body)
                    .foregroundColor(.white)
            }
            .padding(UIStyleGuide.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: UIStyleGuide.CornerRadius.large)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }

    // MARK: - Computed Properties

    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return usersViewModel.users
        } else {
            return usersViewModel.users.filter { user in
                user.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var canCreateGroup: Bool {
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        return !trimmedName.isEmpty && selectedUserIds.count >= 1 && !isCreating
    }

    // MARK: - Actions

    private func toggleUserSelection(user: User) {
        if selectedUserIds.contains(user.id) {
            selectedUserIds.remove(user.id)
        } else {
            selectedUserIds.insert(user.id)
        }
    }

    private func loadUsers() async {
        await usersViewModel.loadUsers()
    }

    private func createGroup() async {
        guard canCreateGroup else { return }

        isCreating = true
        errorMessage = nil

        do {
            // Include current user in participants
            var participantIds = Array(selectedUserIds)
            participantIds.append(currentUserId)

            let conversationId = try await conversationService.createGroupConversation(
                participantIds: participantIds,
                groupName: groupName.trimmingCharacters(in: .whitespaces)
            )

            print("✅ Group created: \(conversationId)")

            isCreating = false

            // Call the callback before dismissing
            onGroupCreated?(conversationId)

            // Dismiss the sheet
            dismiss()

        } catch {
            isCreating = false
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to create group: \(error)")
        }
    }
}

// MARK: - Selected User Chip

struct SelectedUserChip: View {
    let name: String
    let isRemovable: Bool
    let onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: UIStyleGuide.Spacing.xs) {
            Text(name)
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)

            if isRemovable, let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(UIStyleGuide.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, UIStyleGuide.Spacing.sm)
        .padding(.vertical, UIStyleGuide.Spacing.xs)
        .background(UIStyleGuide.Colors.primary.opacity(0.2))
        .cornerRadius(UIStyleGuide.CornerRadius.small)
    }
}

// MARK: - User Selection Row

struct UserSelectionRow: View {
    let user: User
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: UIStyleGuide.Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(getAvatarColor(for: user.id))
                        .frame(width: 44, height: 44)

                    Text(getInitials(from: user.displayName))
                        .font(UIStyleGuide.Typography.bodyBold)
                        .foregroundColor(.white)
                }

                // User info
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(UIStyleGuide.Typography.body)
                        .foregroundColor(UIStyleGuide.Colors.textPrimary)

                    if user.isOnline {
                        Text("Online")
                            .font(UIStyleGuide.Typography.caption)
                            .foregroundColor(UIStyleGuide.Colors.success)
                    } else {
                        Text(user.lastSeen.lastSeenString)
                            .font(UIStyleGuide.Typography.caption)
                            .foregroundColor(UIStyleGuide.Colors.textSecondary)
                    }
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? UIStyleGuide.Colors.primary : UIStyleGuide.Colors.border,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(UIStyleGuide.Colors.primary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(UIStyleGuide.Colors.textPrimary)
                    }
                }
            }
            .padding(UIStyleGuide.Spacing.sm)
            .background(Color.white)
            .cornerRadius(UIStyleGuide.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let firstInitial = components[0].prefix(1)
            let lastInitial = components[1].prefix(1)
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }
        return "?"
    }

    private func getAvatarColor(for userId: String) -> Color {
        let colors: [Color] = [
            Color(hex: "5EC792"),
            Color(hex: "6B9BD1"),
            Color(hex: "E57373"),
            Color(hex: "FFB74D"),
            Color(hex: "BA68C8"),
            Color(hex: "4DB6AC")
        ]

        let hash = abs(userId.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CreateGroupView(
            usersViewModel: UsersViewModel(userService: UserService()),
            conversationService: ConversationService(localStorageService: LocalStorageService())
        )
    }
}
