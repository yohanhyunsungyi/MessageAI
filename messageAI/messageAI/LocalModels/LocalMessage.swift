//
//  LocalMessage.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import SwiftData

/// Local SwiftData model for offline message persistence
@Model
class LocalMessage {
    @Attribute(.unique) var id: String
    var conversationId: String
    var senderId: String
    var senderName: String
    var text: String
    var timestamp: Date
    var status: String
    var isPending: Bool
    var localId: String?

    init(id: String, conversationId: String, senderId: String,
         senderName: String, text: String, timestamp: Date,
         status: String, isPending: Bool, localId: String?) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
        self.status = status
        self.isPending = isPending
        self.localId = localId
    }
}
