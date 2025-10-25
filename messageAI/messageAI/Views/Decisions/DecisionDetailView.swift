//
//  DecisionDetailView.swift
//  messageAI
//
//  Detail view for a single decision
//

import SwiftUI

struct DecisionDetailView: View {
    let decision: Decision
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Summary Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Decision")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(decision.summary)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Divider()

                    // Context Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(decision.context)
                            .font(.body)
                            .foregroundColor(.primary)
                    }

                    Divider()

                    // Participants Section
                    if !decision.participants.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Participants")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(decision.participants, id: \.self) { participant in
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.blue)
                                        Text(participant)
                                            .font(.body)
                                    }
                                }
                            }
                        }

                        Divider()
                    }

                    // Tags Section
                    if !decision.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            HStack(spacing: 8) {
                                ForEach(decision.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                        }

                        Divider()
                    }

                    // Metadata Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        // Timestamp
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text(decision.formattedDate)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Source conversation
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .foregroundColor(.secondary)
                            Text(decision.conversationName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Created by
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.secondary)
                            Text("Extracted by AI")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Decision Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Preview
#Preview {
    DecisionDetailView(
        decision: Decision(
            summary: "Use PostgreSQL for analytics database",
            context: "After evaluating MongoDB and PostgreSQL, we decided PostgreSQL is better for our analytics workload due to strong SQL support and better aggregation performance.",
            participants: ["Alice", "Bob", "Charlie"],
            tags: ["technical", "architecture", "database"],
            conversationId: "conv123",
            conversationName: "#engineering-team",
            timestamp: Date(),
            createdBy: "ai"
        )
    )
}
