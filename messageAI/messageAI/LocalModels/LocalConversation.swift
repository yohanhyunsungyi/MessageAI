//
//  LocalConversation.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import SwiftData

/// Local SwiftData model for offline conversation persistence
/// All arrays/dictionaries stored as JSON strings to avoid SwiftData issues
@Model
class LocalConversation {
    @Attribute(.unique) var id: String
    var participantIdsJSON: String    // [String] stored as JSON
    var participantNamesJSON: String  // [String: String] stored as JSON
    var participantPhotosJSON: String // [String: String?] stored as JSON
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var lastMessageSenderId: String?
    var type: String
    var groupName: String?
    var createdAt: Date
    var createdBy: String

    init(
        id: String,
        participantIdsJSON: String,
        participantNamesJSON: String,
        participantPhotosJSON: String,
        lastMessage: String?,
        lastMessageTimestamp: Date?,
        lastMessageSenderId: String?,
        type: String,
        groupName: String?,
        createdAt: Date,
        createdBy: String
    ) {
        self.id = id
        self.participantIdsJSON = participantIdsJSON
        self.participantNamesJSON = participantNamesJSON
        self.participantPhotosJSON = participantPhotosJSON
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderId = lastMessageSenderId
        self.type = type
        self.groupName = groupName
        self.createdAt = createdAt
        self.createdBy = createdBy
    }
    
    /// Convert to Conversation model
    func toConversation() -> Conversation? {
        guard let typeEnum = ConversationType(rawValue: type) else {
            print("❌ Failed to parse conversation type: \(type)")
            return nil
        }
        
        // Decode JSON strings with proper error handling
        guard let participantIds = try? JSONDecoder().decode([String].self, from: Data(participantIdsJSON.utf8)) else {
            print("❌ Failed to decode participantIds")
            return nil
        }
        
        guard let participantNames = try? JSONDecoder().decode([String: String].self, from: Data(participantNamesJSON.utf8)) else {
            print("❌ Failed to decode participantNames")
            return nil
        }
        
        // Safely decode participantPhotos with nullable values
        var participantPhotos: [String: String?] = [:]
        if let data = participantPhotosJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String?].self, from: data) {
            participantPhotos = decoded
        } else {
            // Fallback: create empty photo dict with nil values for each participant
            print("⚠️ Failed to decode participantPhotos, using fallback")
            participantPhotos = Dictionary(uniqueKeysWithValues: participantIds.map { ($0, nil) })
        }
        
        return Conversation(
            id: id,
            participantIds: participantIds,
            participantNames: participantNames,
            participantPhotos: participantPhotos,
            lastMessage: lastMessage,
            lastMessageTimestamp: lastMessageTimestamp,
            lastMessageSenderId: lastMessageSenderId,
            type: typeEnum,
            groupName: groupName,
            createdAt: createdAt,
            createdBy: createdBy
        )
    }
    
    /// Create from Conversation model
    static func from(_ conversation: Conversation) -> LocalConversation? {
        print("🔄 Converting Conversation to LocalConversation...")
        
        // Encode ALL arrays/dictionaries as JSON (avoids SwiftData array issues!)
        do {
            let idsJSON = try JSONEncoder().encode(conversation.participantIds)
            let namesJSON = try JSONEncoder().encode(conversation.participantNames)
            let photosJSON = try JSONEncoder().encode(conversation.participantPhotos)
            
            guard let idsString = String(data: idsJSON, encoding: .utf8),
                  let namesString = String(data: namesJSON, encoding: .utf8),
                  let photosString = String(data: photosJSON, encoding: .utf8) else {
                print("❌ Failed to convert JSON to String")
                return nil
            }
            
            print("✅ Encoded participantIds: \(idsString)")
            print("✅ Encoded participantNames: \(namesString)")
            print("✅ Encoded participantPhotos: \(photosString)")
            
            let local = LocalConversation(
                id: conversation.id,
                participantIdsJSON: idsString,
                participantNamesJSON: namesString,
                participantPhotosJSON: photosString,
                lastMessage: conversation.lastMessage,
                lastMessageTimestamp: conversation.lastMessageTimestamp,
                lastMessageSenderId: conversation.lastMessageSenderId,
                type: conversation.type.rawValue,
                groupName: conversation.groupName,
                createdAt: conversation.createdAt,
                createdBy: conversation.createdBy
            )
            
            print("✅ Created LocalConversation successfully")
            return local
        } catch {
            print("❌ Error encoding conversation: \(error)")
            return nil
        }
    }
}
