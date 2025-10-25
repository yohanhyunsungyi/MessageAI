//
//  SummaryView.swift
//  messageAI
//
//  Display AI-generated conversation summary
//

import SwiftUI

struct SummaryView: View {
    let summary: Summary
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                            Text("Thread Summary")
                                .font(.headline)
                        }

                        Text("\(summary.messageCount) messages • \(summary.participants.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Key Points
                    if !summary.keyPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Points")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            ForEach(summary.keyPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.blue)
                                    Text(point)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    // Full Summary
                    if !summary.keyPoints.isEmpty {
                        Divider()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Summary")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(summary.summary)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Time Range
                    if let timeRange = summary.timeRange {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time Period")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("\(formattedDate(timeRange.start)) - \(formattedDate(timeRange.end))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Preview
#Preview {
    SummaryView(summary: Summary(
        conversationId: "test",
        summary: "The team discussed the new feature implementation and decided to use PostgreSQL. John will update the API documentation by Friday. There's a blocker on the security review that needs attention.",
        keyPoints: [
            "Decided to use PostgreSQL for analytics",
            "API redesign blocked on security review",
            "John to update docs by Friday"
        ],
        messageCount: 150,
        timeRange: Summary.TimeRange(
            start: Date().addingTimeInterval(-3600 * 24 * 3),
            end: Date()
        ),
        participants: ["Alice", "Bob", "Charlie"]
    ))
}
