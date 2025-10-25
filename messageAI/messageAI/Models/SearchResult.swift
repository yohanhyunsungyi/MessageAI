//
//  SearchResult.swift
//  messageAI
//
//  Search result model for smart semantic search
//

import Foundation

/// Result from semantic search across messages
/// Contains message data and relevance score
struct SearchResult: Codable, Identifiable {
    let id: String                   // messageId
    let conversationId: String
    let senderId: String
    let senderName: String
    let text: String                 // Message content
    let timestamp: Date
    let score: Double                // Relevance score (0.0-1.0)

    /// Initialize from Cloud Function response
    init(
        id: String,
        conversationId: String,
        senderId: String,
        senderName: String,
        text: String,
        timestamp: Date,
        score: Double
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
        self.score = score
    }

    /// Initialize from dictionary (Cloud Function response)
    init?(from dict: [String: Any]) {
        guard let messageId = dict["messageId"] as? String,
              let conversationId = dict["conversationId"] as? String,
              let senderId = dict["senderId"] as? String,
              let senderName = dict["senderName"] as? String,
              let text = dict["text"] as? String,
              let score = dict["score"] as? Double else {
            return nil
        }

        // Parse timestamp
        var timestamp = Date()
        if let timestampValue = dict["timestamp"] as? [String: Any],
           let seconds = timestampValue["_seconds"] as? Double {
            timestamp = Date(timeIntervalSince1970: seconds)
        } else if let timestampDouble = dict["timestamp"] as? Double {
            timestamp = Date(timeIntervalSince1970: timestampDouble)
        }

        self.id = messageId
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
        self.score = score
    }

    /// Format relevance score as percentage
    var relevancePercentage: String {
        return String(format: "%.0f%%", score * 100)
    }

    /// Preview text (truncated if too long)
    var previewText: String {
        if text.count <= 150 {
            return text
        }
        let endIndex = text.index(text.startIndex, offsetBy: 150)
        return String(text[..<endIndex]) + "..."
    }
}
