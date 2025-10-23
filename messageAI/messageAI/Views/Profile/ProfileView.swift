//
//  ProfileView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

/// Profile view displaying current user information and settings
struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                UIStyleGuide.Colors.background
                    .edgesIgnoringSafeArea(.all)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: UIStyleGuide.Spacing.xl) {
                        // Profile Header
                        profileHeader

                        // User Info Card
                        userInfoCard

                        // Settings Section
                        settingsSection

                        Spacer(minLength: UIStyleGuide.Spacing.md)

                        // Sign Out Button
                        signOutButton
                    }
                    .padding(.horizontal, UIStyleGuide.Spacing.md)
                    .padding(.top, UIStyleGuide.Spacing.lg)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    try? authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: UIStyleGuide.Spacing.md) {
            // Profile Photo
            ZStack {
                if let photoURL = authService.currentUser?.photoURL,
                   let data = Data(base64Encoded: photoURL),
                   let uiImage = UIImage(data: data) {
                    // Base64 encoded image
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(UIStyleGuide.Colors.primary, lineWidth: 3)
                        )
                } else {
                    // Placeholder with initial
                    Circle()
                        .fill(UIStyleGuide.Colors.primary)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(authService.currentUser?.displayName.prefix(1).uppercased() ?? "?")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(UIStyleGuide.Colors.textPrimary)
                        )
                }

                // Online indicator
                Circle()
                    .fill(UIStyleGuide.Colors.online)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .offset(x: 35, y: 35)
            }

            // Display Name
            Text(authService.currentUser?.displayName ?? "Unknown User")
                .font(UIStyleGuide.Typography.title)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)

            // Status
            Text("Online")
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.online)
        }
        .padding(.vertical, UIStyleGuide.Spacing.lg)
    }

    // MARK: - User Info Card

    private var userInfoCard: some View {
        VStack(spacing: 0) {
            // Email
            InfoRow(
                icon: "envelope.fill",
                title: "Email",
                value: authService.currentUser?.email ?? "Not set"
            )

            Divider()
                .padding(.leading, 50)

            // Member Since
            InfoRow(
                icon: "calendar",
                title: "Member Since",
                value: formatDate(authService.currentUser?.createdAt)
            )
        }
        .padding(UIStyleGuide.Spacing.md)
        .cardStyle()
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: UIStyleGuide.Spacing.sm) {
            // Section Title
            HStack {
                Text("Settings")
                    .font(UIStyleGuide.Typography.title3)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, UIStyleGuide.Spacing.xs)
            .padding(.bottom, UIStyleGuide.Spacing.xs)

            // Settings Card
            VStack(spacing: 0) {
                Button {
                    openAppSettings()
                } label: {
                    SettingRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        subtitle: "Manage notification settings"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(UIStyleGuide.Spacing.md)
            .cardStyle()
        }
    }

    // MARK: - Actions

    private func openAppSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
            }
        }
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button {
            showSignOutAlert = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: UIStyleGuide.IconSize.medium))
                Text("Sign Out")
            }
            .font(UIStyleGuide.Typography.button)
            .foregroundColor(UIStyleGuide.Colors.error)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(UIStyleGuide.CornerRadius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: UIStyleGuide.CornerRadius.pill)
                    .stroke(UIStyleGuide.Colors.error.opacity(0.3), lineWidth: 1.5)
            )
        }
        .padding(.bottom, UIStyleGuide.Spacing.lg)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: UIStyleGuide.Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: UIStyleGuide.IconSize.medium))
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
                .frame(width: 24)

            // Title and Value
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(UIStyleGuide.Typography.caption)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)

                Text(value)
                    .font(UIStyleGuide.Typography.body)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(.vertical, UIStyleGuide.Spacing.sm)
    }
}

// MARK: - Setting Row Component

struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: UIStyleGuide.Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: UIStyleGuide.IconSize.medium))
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
                .frame(width: 24)

            // Title and Subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(UIStyleGuide.Typography.bodyBold)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)

                Text(subtitle)
                    .font(UIStyleGuide.Typography.caption)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(UIStyleGuide.Colors.textTertiary)
        }
        .padding(.vertical, UIStyleGuide.Spacing.sm)
        .contentShape(Rectangle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
}
