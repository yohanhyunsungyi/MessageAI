//
//  SmartSearchView.swift
//  messageAI
//
//  Smart semantic search across all messages
//

import SwiftUI

struct SmartSearchView: View {
    @StateObject private var aiService = AIService()
    @State private var searchQuery = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                UIStyleGuide.Colors.cardBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    searchBar

                    // Content
                    if isSearching {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error: error)
                    } else if searchResults.isEmpty && !searchQuery.isEmpty {
                        emptyStateView
                    } else if searchResults.isEmpty {
                        initialStateView
                    } else {
                        resultsListView
                    }
                }
            }
            .navigationTitle("Smart Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: UIStyleGuide.Spacing.sm) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
                .font(.system(size: UIStyleGuide.IconSize.medium))

            // Text field
            TextField("Search messages...", text: $searchQuery)
                .font(UIStyleGuide.Typography.body)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }

            // Clear button
            if !searchQuery.isEmpty {
                Button(action: {
                    searchQuery = ""
                    searchResults = []
                    errorMessage = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(UIStyleGuide.Colors.textSecondary)
                        .font(.system(size: UIStyleGuide.IconSize.medium))
                }
            }

            // Search button
            Button(action: performSearch) {
                Text("Search")
                    .font(UIStyleGuide.Typography.bodyBold)
                    .foregroundColor(searchQuery.isEmpty ? UIStyleGuide.Colors.textTertiary : UIStyleGuide.Colors.textPrimary)
            }
            .disabled(searchQuery.isEmpty || isSearching)
        }
        .padding(UIStyleGuide.Spacing.md)
        .background(Color.white)
        .cornerRadius(UIStyleGuide.CornerRadius.medium)
        .shadow(
            color: UIStyleGuide.Shadow.light.color,
            radius: UIStyleGuide.Shadow.light.radius,
            x: UIStyleGuide.Shadow.light.x,
            y: UIStyleGuide.Shadow.light.y
        )
        .padding(.horizontal, UIStyleGuide.Spacing.md)
        .padding(.vertical, UIStyleGuide.Spacing.sm)
    }

    // MARK: - Content Views

    private var loadingView: some View {
        VStack(spacing: UIStyleGuide.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(error: String) -> some View {
        VStack(spacing: UIStyleGuide.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(UIStyleGuide.Colors.error)

            Text("Search Error")
                .font(UIStyleGuide.Typography.title3)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)

            Text(error)
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, UIStyleGuide.Spacing.xl)

            Button(action: performSearch) {
                Text("Try Again")
                    .font(UIStyleGuide.Typography.button)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)
                    .padding(.horizontal, UIStyleGuide.Spacing.xl)
                    .padding(.vertical, UIStyleGuide.Spacing.sm)
                    .background(UIStyleGuide.Colors.primary)
                    .cornerRadius(UIStyleGuide.CornerRadius.medium)
            }
            .padding(.top, UIStyleGuide.Spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(UIStyleGuide.Spacing.xl)
    }

    private var emptyStateView: some View {
        VStack(spacing: UIStyleGuide.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(UIStyleGuide.Colors.textTertiary)

            Text("No Results")
                .font(UIStyleGuide.Typography.title3)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)

            Text("No messages found for '\(searchQuery)'")
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, UIStyleGuide.Spacing.xl)

            Text("Try different keywords or phrases")
                .font(UIStyleGuide.Typography.caption)
                .foregroundColor(UIStyleGuide.Colors.textTertiary)
                .padding(.top, UIStyleGuide.Spacing.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(UIStyleGuide.Spacing.xl)
    }

    private var initialStateView: some View {
        VStack(spacing: UIStyleGuide.Spacing.lg) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 64))
                .foregroundColor(UIStyleGuide.Colors.secondary)

            Text("Smart Semantic Search")
                .font(UIStyleGuide.Typography.title2)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)

            VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.md) {
                FeatureRow(
                    icon: "brain",
                    title: "AI-Powered",
                    description: "Understands context and meaning, not just keywords"
                )

                FeatureRow(
                    icon: "bolt.fill",
                    title: "Lightning Fast",
                    description: "Search across thousands of messages in under a second"
                )

                FeatureRow(
                    icon: "target",
                    title: "Highly Relevant",
                    description: "Results ranked by semantic similarity"
                )
            }
            .padding(.horizontal, UIStyleGuide.Spacing.xl)

            Text("Try searching for: \"redis caching\", \"API design\", or \"meeting notes\"")
                .font(UIStyleGuide.Typography.caption)
                .foregroundColor(UIStyleGuide.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, UIStyleGuide.Spacing.xl)
                .padding(.top, UIStyleGuide.Spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(UIStyleGuide.Spacing.xl)
    }

    private var resultsListView: some View {
        ScrollView {
            VStack(spacing: UIStyleGuide.Spacing.sm) {
                // Results header
                HStack {
                    Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                        .font(UIStyleGuide.Typography.captionBold)
                        .foregroundColor(UIStyleGuide.Colors.textSecondary)

                    Spacer()

                    // Clear cache button
                    Button(action: {
                        aiService.clearSearchCache()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                            Text("Clear Cache")
                                .font(UIStyleGuide.Typography.caption)
                        }
                        .foregroundColor(UIStyleGuide.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, UIStyleGuide.Spacing.md)
                .padding(.vertical, UIStyleGuide.Spacing.sm)

                // Results list
                ForEach(searchResults) { result in
                    SearchResultRow(result: result)
                        .padding(.horizontal, UIStyleGuide.Spacing.md)
                }
            }
            .padding(.vertical, UIStyleGuide.Spacing.sm)
        }
    }

    // MARK: - Actions

    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        Task {
            isSearching = true
            errorMessage = nil

            do {
                let results = try await aiService.smartSearch(query: searchQuery, topK: 10)
                searchResults = results
                print("🔍 Found \(results.count) results")
            } catch {
                errorMessage = error.localizedDescription
                print("❌ Search error: \(error)")
            }

            isSearching = false
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: UIStyleGuide.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: UIStyleGuide.IconSize.large))
                .foregroundColor(UIStyleGuide.Colors.secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(UIStyleGuide.Typography.bodyBold)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)

                Text(description)
                    .font(UIStyleGuide.Typography.bodySmall)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.sm) {
            // Header: sender and relevance
            HStack {
                Text(result.senderName)
                    .font(UIStyleGuide.Typography.bodyBold)
                    .foregroundColor(UIStyleGuide.Colors.textPrimary)

                Spacer()

                // Relevance badge
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text(result.relevancePercentage)
                        .font(UIStyleGuide.Typography.caption)
                }
                .foregroundColor(relevanceColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(relevanceColor.opacity(0.1))
                .cornerRadius(UIStyleGuide.CornerRadius.small)
            }

            // Message preview
            Text(result.previewText)
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)
                .lineLimit(3)

            // Footer: timestamp
            Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(UIStyleGuide.Typography.caption)
                .foregroundColor(UIStyleGuide.Colors.textTertiary)
        }
        .padding(UIStyleGuide.Spacing.md)
        .background(Color.white)
        .cornerRadius(UIStyleGuide.CornerRadius.medium)
        .shadow(
            color: UIStyleGuide.Shadow.light.color,
            radius: UIStyleGuide.Shadow.light.radius,
            x: UIStyleGuide.Shadow.light.x,
            y: UIStyleGuide.Shadow.light.y
        )
    }

    private var relevanceColor: Color {
        if result.score > 0.8 {
            return UIStyleGuide.Colors.success
        } else if result.score > 0.6 {
            return UIStyleGuide.Colors.primary
        } else {
            return UIStyleGuide.Colors.textSecondary
        }
    }
}

// MARK: - Preview

#Preview {
    SmartSearchView()
}
