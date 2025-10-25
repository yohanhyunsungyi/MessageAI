//
//  User.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation

/// User model representing a registered user in the app
struct User: Codable, Identifiable {
    let id: String              // Firebase Auth UID
    var email: String
    var displayName: String
    var photoURL: String?
    var phoneNumber: String?
    var isOnline: Bool
    var lastSeen: Date
    var fcmToken: String?
    var createdAt: Date
    var timezone: String?       // User's timezone identifier (e.g., "America/Los_Angeles")
}
