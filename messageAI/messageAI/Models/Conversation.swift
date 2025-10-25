//
//  Conversation.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation

/// Conversation model representing a chat conversation (one-on-one or group)
struct Conversation: Codable, Identifiable {
    let id: String
    var participantIds: [String]                    // User IDs
    var participantNames: [String: String]          // userId: displayName
    var participantPhotos: [String: String?]        // userId: photoURL
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var lastMessageSenderId: String?
    var lastMessagePriority: MessagePriority?       // Priority of last message
    var type: ConversationType                      // .oneOnOne or .group
    var groupName: String?                          // Only for groups
    var createdAt: Date
    var createdBy: String
}
