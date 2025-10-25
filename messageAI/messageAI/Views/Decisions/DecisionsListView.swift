//
//  DecisionsListView.swift
//  messageAI
//
//  List view for all decisions with chronological grouping
//

import SwiftUI
import FirebaseFirestore

struct DecisionsListView: View {
    private let firebaseManager = FirebaseManager.shared
    @State private var decisions: [Decision] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var listener: ListenerRegistration?
    @State private var selectedDecision: Decision?

    // Group decisions by date
    var groupedDecisions: [(String, [Decision])] {
        let calendar = Calendar.current
        let now = Date()

        var groups: [String: [Decision]] = [:]

        for decision in decisions {
            let groupKey: String
            if calendar.isDateInToday(decision.timestamp) {
                groupKey = "Today"
            } else if calendar.isDateInYesterday(decision.timestamp) {
                groupKey = "Yesterday"
            } else if calendar.isDate(decision.timestamp, equalTo: now, toGranularity: .weekOfYear) {
                groupKey = "This Week"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy"
                groupKey = formatter.string(from: decision.timestamp)
            }

            groups[groupKey, default: []].append(decision)
        }

        // Sort groups chronologically
        let sortedGroups = groups.sorted { (group1, group2) in
            // Get first decision from each group to compare timestamps
            guard let date1 = group1.value.first?.timestamp,
                  let date2 = group2.value.first?.timestamp else {
                return false
            }
            return date1 > date2 // Most recent first
        }

        return sortedGroups
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading && decisions.isEmpty {
                    ProgressView("Loading decisions...")
                } else if decisions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No decisions tracked")
                            .font(.headline)
                        Text("Decisions will appear here when extracted from conversations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(groupedDecisions, id: \.0) { group in
                            Section(header: Text(group.0)) {
                                ForEach(group.1) { decision in
                                    Button {
                                        selectedDecision = decision
                                    } label: {
                                        DecisionRowView(decision: decision)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Decisions")
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .sheet(item: $selectedDecision) { decision in
                DecisionDetailView(decision: decision)
            }
            .onAppear {
                startListening()
            }
            .onDisappear {
                listener?.remove()
            }
        }
    }

    // MARK: - Firestore Listeners

    private func startListening() {
        isLoading = true

        // Listen to all decisions in real-time
        listener = firebaseManager.firestore
            .collection("decisions")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                isLoading = false

                if let error = error {
                    print("❌ [DecisionsListView] Error listening to decisions: \(error)")
                    errorMessage = "Failed to load decisions: \(error.localizedDescription)"
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ [DecisionsListView] No decisions found")
                    decisions = []
                    return
                }

                decisions = documents.compactMap { doc in
                    Decision(document: doc.data())
                }

                print("🎯 [DecisionsListView] Loaded \(decisions.count) decisions")
            }
    }
}

// MARK: - Decision Row View

struct DecisionRowView: View {
    let decision: Decision

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Summary
            Text(decision.summary)
                .font(.headline)
                .foregroundColor(.primary)

            // Tags
            if !decision.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(decision.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }

            // Participants
            if !decision.participants.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(decision.participants.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            // Source conversation
            HStack(spacing: 4) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(decision.conversationName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// Preview
#Preview {
    DecisionsListView()
}
