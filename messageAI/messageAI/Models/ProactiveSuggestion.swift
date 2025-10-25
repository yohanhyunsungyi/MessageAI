//
//  ProactiveSuggestion.swift
//  messageAI
//
//  Proactive assistant suggestion model for scheduling meetings
//

import Foundation
import FirebaseFirestore

/// Proactive suggestion from AI assistant
struct ProactiveSuggestion: Identifiable, Codable {
    @DocumentID var id: String?
    let type: SuggestionType
    let conversationId: String
    let conversationName: String
    let participantIds: [String]
    let participantNames: [String: String]
    let purpose: String
    let urgency: Urgency
    let confidence: Double
    var status: Status
    let createdAt: Timestamp
    let triggeredByMessageId: String

    // Optional fields for time slot suggestions (populated in Part 2)
    var suggestedTimeSlots: [TimeSlot]?
    var acceptedTimeSlot: TimeSlot?
    var acceptedAt: Timestamp?
    var dismissedAt: Timestamp?

    /// Type of proactive suggestion
    enum SuggestionType: String, Codable {
        case scheduling
    }

    /// Urgency level
    enum Urgency: String, Codable {
        case urgent
        case thisWeek = "this-week"
        case flexible

        var displayText: String {
            switch self {
            case .urgent: return "Urgent"
            case .thisWeek: return "This Week"
            case .flexible: return "Flexible"
            }
        }

        var emoji: String {
            switch self {
            case .urgent: return "🔴"
            case .thisWeek: return "🟡"
            case .flexible: return "🟢"
            }
        }
    }

    /// Status of the suggestion
    enum Status: String, Codable {
        case pending
        case accepted
        case dismissed
    }
}

/// Time slot suggestion for meetings
struct TimeSlot: Codable, Identifiable {
    var id: String { startTime.ISO8601Format() }
    let startTime: Date
    let duration: Int // minutes
    let timezoneDisplays: [String: String] // userId: "2pm PST"

    var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(duration * 60))
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case startTime
        case duration
        case timezoneDisplays
    }

    init(startTime: Date, duration: Int, timezoneDisplays: [String: String]) {
        self.startTime = startTime
        self.duration = duration
        self.timezoneDisplays = timezoneDisplays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle both Timestamp and ISO8601 string formats
        if let timestamp = try? container.decode(Timestamp.self, forKey: .startTime) {
            self.startTime = timestamp.dateValue()
        } else if let iso8601String = try? container.decode(String.self, forKey: .startTime) {
            if let date = ISO8601DateFormatter().date(from: iso8601String) {
                self.startTime = date
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .startTime,
                    in: container,
                    debugDescription: "Invalid date format"
                )
            }
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.startTime,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "startTime not found"
                )
            )
        }

        self.duration = try container.decode(Int.self, forKey: .duration)
        self.timezoneDisplays = try container.decode([String: String].self, forKey: .timezoneDisplays)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startTime.ISO8601Format(), forKey: .startTime)
        try container.encode(duration, forKey: .duration)
        try container.encode(timezoneDisplays, forKey: .timezoneDisplays)
    }
}

// MARK: - Helper Extensions
extension ProactiveSuggestion {
    /// Formatted participant list
    var participantList: String {
        let names = participantNames.values.sorted()
        if names.count <= 3 {
            return names.joined(separator: ", ")
        } else {
            let firstThree = names.prefix(3).joined(separator: ", ")
            return "\(firstThree) +\(names.count - 3) more"
        }
    }

    /// Time since suggestion was created
    var timeSinceCreated: String {
        let date = createdAt.dateValue()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Check if suggestion is still valid (not too old)
    var isStillValid: Bool {
        let date = createdAt.dateValue()
        let hoursSinceCreation = Date().timeIntervalSince(date) / 3600
        return hoursSinceCreation < 48 // Valid for 48 hours
    }
}
