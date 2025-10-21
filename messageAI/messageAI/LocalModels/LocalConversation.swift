//
//  LocalConversation.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import SwiftData

/// Local SwiftData model for offline conversation persistence
@Model
class LocalConversation {
    @Attribute(.unique) var id: String
    var participantIds: [String]
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var type: String
    var groupName: String?

    init(id: String, participantIds: [String], lastMessage: String?,
         lastMessageTimestamp: Date?, type: String, groupName: String?) {
        self.id = id
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.type = type
        self.groupName = groupName
    }
}
