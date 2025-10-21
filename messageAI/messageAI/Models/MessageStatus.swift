//
//  MessageStatus.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation

/// Message delivery and read status
enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}
