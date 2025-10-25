//
//  ProactiveSuggestionView.swift
//  messageAI
//
//  View for displaying proactive AI scheduling suggestions
//

import SwiftUI
import FirebaseFirestore

struct ProactiveSuggestionView: View {
    let suggestion: ProactiveSuggestion
    let onAccept: (TimeSlot) -> Void
    let onDismiss: () -> Void

    @State private var selectedTimeSlot: TimeSlot?
    @State private var isAccepting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header

            Divider()
                .background(UIStyleGuide.Colors.border)

            ScrollView {
                VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.lg) {
                    // Purpose
                    purposeSection

                    // Participants
                    participantsSection

                    // Time Slots
                    if let timeSlots = suggestion.suggestedTimeSlots, !timeSlots.isEmpty {
                        timeSlotsSection(timeSlots: timeSlots)
                    } else {
                        loadingTimeSlotsView
                    }

                    // Actions
                    actionsSection
                }
                .padding(UIStyleGuide.Spacing.lg)
            }
        }
        .background(UIStyleGuide.Colors.cardBackground)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: UIStyleGuide.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("🤖 AI Scheduling Assistant")
                        .font(UIStyleGuide.Typography.title3)
                        .foregroundColor(UIStyleGuide.Colors.textPrimary)

                    Text(suggestion.urgency.emoji)
                        .font(.system(size: 14))
                }

                Text("Detected a need to schedule a meeting")
                    .font(UIStyleGuide.Typography.caption)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(UIStyleGuide.Colors.textTertiary)
            }
        }
        .padding(UIStyleGuide.Spacing.lg)
        .background(Color.white)
    }

    // MARK: - Purpose Section

    private var purposeSection: some View {
        VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.sm) {
            Text("Meeting Purpose")
                .font(UIStyleGuide.Typography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)

            Text(suggestion.purpose)
                .font(UIStyleGuide.Typography.body)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)
        }
    }

    // MARK: - Participants Section

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.sm) {
            Text("Participants")
                .font(UIStyleGuide.Typography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)

            Text(suggestion.participantList)
                .font(UIStyleGuide.Typography.body)
                .foregroundColor(UIStyleGuide.Colors.textPrimary)
        }
    }

    // MARK: - Time Slots Section

    private func timeSlotsSection(timeSlots: [TimeSlot]) -> some View {
        VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.md) {
            Text("Suggested Times (across all timezones)")
                .font(UIStyleGuide.Typography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)

            ForEach(timeSlots) { timeSlot in
                timeSlotCard(timeSlot)
            }
        }
    }

    private func timeSlotCard(_ timeSlot: TimeSlot) -> some View {
        let isSelected = selectedTimeSlot?.id == timeSlot.id

        return VStack(alignment: .leading, spacing: UIStyleGuide.Spacing.sm) {
            // Main time display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatTimeSlotMain(timeSlot))
                        .font(UIStyleGuide.Typography.bodyBold)
                        .foregroundColor(isSelected ? .white : UIStyleGuide.Colors.textPrimary)

                    Text("\(timeSlot.duration) minutes")
                        .font(UIStyleGuide.Typography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : UIStyleGuide.Colors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }

            // All timezones
            if timeSlot.timezoneDisplays.count > 1 {
                Divider()
                    .background(isSelected ? Color.white.opacity(0.3) : UIStyleGuide.Colors.border)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(timeSlot.timezoneDisplays.sorted(by: { $0.key < $1.key })), id: \.key) { _, display in
                        Text(display)
                            .font(UIStyleGuide.Typography.bodySmall)
                            .foregroundColor(isSelected ? .white.opacity(0.9) : UIStyleGuide.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(UIStyleGuide.Spacing.md)
        .background(isSelected ? UIStyleGuide.Colors.primary : Color.white)
        .cornerRadius(UIStyleGuide.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: UIStyleGuide.CornerRadius.medium)
                .stroke(isSelected ? Color.clear : UIStyleGuide.Colors.border, lineWidth: 1)
        )
        .onTapGesture {
            selectedTimeSlot = timeSlot
        }
    }

    private var loadingTimeSlotsView: some View {
        VStack(spacing: UIStyleGuide.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Finding the best times for everyone...")
                .font(UIStyleGuide.Typography.bodySmall)
                .foregroundColor(UIStyleGuide.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(UIStyleGuide.Spacing.xl)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: UIStyleGuide.Spacing.md) {
            // Confirm button
            Button {
                if let timeSlot = selectedTimeSlot {
                    isAccepting = true
                    onAccept(timeSlot)
                }
            } label: {
                HStack {
                    if isAccepting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Confirm Meeting")
                            .font(UIStyleGuide.Typography.bodyBold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(UIStyleGuide.Spacing.md)
                .background(selectedTimeSlot != nil ? Color.black : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(UIStyleGuide.CornerRadius.medium)
            }
            .disabled(selectedTimeSlot == nil || isAccepting)

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Text("Not Now")
                    .font(UIStyleGuide.Typography.body)
                    .foregroundColor(UIStyleGuide.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(UIStyleGuide.Spacing.md)
                    .background(Color.white)
                    .cornerRadius(UIStyleGuide.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIStyleGuide.CornerRadius.medium)
                            .stroke(UIStyleGuide.Colors.border, lineWidth: 1)
                    )
            }
            .disabled(isAccepting)
        }
    }

    // MARK: - Helper Methods

    private func formatTimeSlotMain(_ timeSlot: TimeSlot) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timeSlot.startTime)
    }
}

// MARK: - Preview

#Preview {
    ProactiveSuggestionView(
        suggestion: ProactiveSuggestion(
            id: "preview-123",
            type: .scheduling,
            conversationId: "conv-123",
            conversationName: "Engineering Team",
            participantIds: ["user1", "user2", "user3"],
            participantNames: ["user1": "Alice", "user2": "Bob", "user3": "Charlie"],
            purpose: "Discuss API redesign",
            urgency: .thisWeek,
            confidence: 0.85,
            status: .pending,
            createdAt: Timestamp(date: Date()),
            triggeredByMessageId: "msg-123",
            suggestedTimeSlots: [
                TimeSlot(
                    startTime: Date().addingTimeInterval(86400),
                    duration: 60,
                    timezoneDisplays: [
                        "user1": "Tomorrow 2:00 PM PST",
                        "user2": "Tomorrow 5:00 PM EST",
                        "user3": "Tomorrow 10:00 PM GMT"
                    ]
                ),
                TimeSlot(
                    startTime: Date().addingTimeInterval(86400 * 2),
                    duration: 60,
                    timezoneDisplays: [
                        "user1": "Friday 10:00 AM PST",
                        "user2": "Friday 1:00 PM EST",
                        "user3": "Friday 6:00 PM GMT"
                    ]
                )
            ]
        ),
        onAccept: { _ in print("Accepted") },
        onDismiss: { print("Dismissed") }
    )
}
