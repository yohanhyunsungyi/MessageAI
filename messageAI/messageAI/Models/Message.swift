//
//  Message.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation

/// Message model representing a chat message
struct Message: Codable, Identifiable {
    let id: String
    let senderId: String
    let senderName: String
    let senderPhotoURL: String?
    var text: String
    var timestamp: Date
    var status: MessageStatus
    var readBy: [String: Date]          // userId: readTimestamp
    var deliveredTo: [String: Date]     // userId: deliveredTimestamp
    var localId: String?                // For optimistic updates
    var priority: MessagePriority?      // AI-classified priority
    var aiClassified: Bool?             // Whether AI classification completed
}
