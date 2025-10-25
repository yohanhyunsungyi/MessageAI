//
//  ActionItemRowView.swift
//  messageAI
//
//  Individual action item row display
//

import SwiftUI
import FirebaseFirestore

struct ActionItemRowView: View {
    let actionItem: ActionItem
    let onToggleComplete: (ActionItem) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button {
                onToggleComplete(actionItem)
            } label: {
                Image(systemName: actionItem.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(actionItem.status == .completed ? .green : .gray)
                    .font(.system(size: 24))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                // Description
                Text(actionItem.description)
                    .font(.body)
                    .strikethrough(actionItem.status == .completed)
                    .foregroundColor(actionItem.status == .completed ? .secondary : .primary)

                // Metadata row
                HStack(spacing: 12) {
                    // Priority indicator
                    HStack(spacing: 4) {
                        Text(actionItem.priority.emoji)
                        Text(actionItem.priority.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Assignee
                    if actionItem.assignee != "unassigned" {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                            Text(actionItem.assignee)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    // Deadline
                    if actionItem.deadline != "none" {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(actionItem.deadline)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                // Source conversation
                Text("From: \(actionItem.conversationName)")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}

// Preview
#Preview {
    VStack(spacing: 0) {
        ActionItemRowView(
            actionItem: ActionItem(
                description: "Review PR #234 and provide feedback",
                assignee: "Alice",
                deadline: "Today",
                priority: .high,
                conversationId: "test",
                conversationName: "#engineering-team"
            ),
            onToggleComplete: { _ in }
        )
        .padding()

        Divider()

        ActionItemRowView(
            actionItem: ActionItem(
                description: "Update documentation for new API endpoints",
                assignee: "Bob",
                deadline: "This week",
                priority: .medium,
                conversationId: "test",
                conversationName: "DM with Bob"
            ),
            onToggleComplete: { _ in }
        )
        .padding()

        Divider()

        ActionItemRowView(
            actionItem: ActionItem(
                description: "Research GraphQL alternatives",
                assignee: "unassigned",
                deadline: "none",
                priority: .low,
                conversationId: "test",
                conversationName: "#backend-team",
                status: .completed
            ),
            onToggleComplete: { _ in }
        )
        .padding()
    }
}
