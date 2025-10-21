//
//  ConversationType.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation

/// Type of conversation: one-on-one or group
enum ConversationType: String, Codable {
    case oneOnOne
    case group
}
