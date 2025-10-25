//
//  MessagePriority.swift
//  messageAI
//
//  Created by Claude Code on 10/24/25.
//

import Foundation

/// Message priority classification
enum MessagePriority: String, Codable {
    case critical
    case high
    case normal

    /// Display emoji for UI
    var emoji: String {
        switch self {
        case .critical:
            return "🔴"
        case .high:
            return "🟡"
        case .normal:
            return ""
        }
    }

    /// Sort priority (higher number = more urgent)
    var sortValue: Int {
        switch self {
        case .critical:
            return 3
        case .high:
            return 2
        case .normal:
            return 1
        }
    }
}
