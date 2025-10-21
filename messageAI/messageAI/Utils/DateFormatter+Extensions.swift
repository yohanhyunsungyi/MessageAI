//
//  DateFormatter+Extensions.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation

extension DateFormatter {

    /// Shared formatter for message timestamps (e.g., "3:45 PM")
    static let messageTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    /// Shared formatter for message dates (e.g., "Oct 21, 2025")
    static let messageDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Shared formatter for full timestamp (e.g., "Oct 21, 2025 at 3:45 PM")
    static let fullTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Shared formatter for last seen (e.g., "Last seen Oct 21 at 3:45 PM")
    static let lastSeen: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Relative Date Formatting
extension Date {

    /// Get conversation timestamp string
    /// Returns "Today", "Yesterday", or formatted date
    var conversationTimestamp: String {
        if isToday {
            return timeString
        } else if isYesterday {
            return "Yesterday"
        } else if isInCurrentWeek {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day of week
            return formatter.string(from: self)
        } else {
            return DateFormatter.messageDate.string(from: self)
        }
    }

    /// Get chat section header string
    /// Returns "Today", "Yesterday", or formatted date
    var chatSectionHeader: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else {
            return DateFormatter.messageDate.string(from: self)
        }
    }

    /// Get last seen string
    /// Returns "Last seen [time]" or "Last seen [date]"
    var lastSeenString: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: self, to: now)

        if let minutes = components.minute, minutes < 1 {
            return "Last seen just now"
        } else if let minutes = components.minute, let hours = components.hour, hours < 1 {
            return "Last seen \(minutes)m ago"
        } else if let hours = components.hour, let days = components.day, days < 1 {
            return "Last seen \(hours)h ago"
        } else if isToday {
            return "Last seen today at \(timeString)"
        } else if isYesterday {
            return "Last seen yesterday at \(timeString)"
        } else {
            return "Last seen \(DateFormatter.lastSeen.string(from: self))"
        }
    }
}
