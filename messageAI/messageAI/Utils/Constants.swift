//
//  Constants.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation

/// App-wide constants
enum Constants {

    // MARK: - Firebase Collections
    enum Collections {
        static let users = "users"
        static let conversations = "conversations"
        static let messages = "messages"
        static let typing = "typing"
    }

    // MARK: - Message Status
    enum MessageStatus {
        static let sending = "sending"
        static let sent = "sent"
        static let delivered = "delivered"
        static let read = "read"
        static let failed = "failed"
    }

    // MARK: - Conversation Types
    enum ConversationType {
        static let oneOnOne = "oneOnOne"
        static let group = "group"
    }

    // MARK: - User Defaults Keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let fcmToken = "fcmToken"
    }

    // MARK: - Notification Names
    enum Notifications {
        static let userDidSignIn = "userDidSignIn"
        static let userDidSignOut = "userDidSignOut"
        static let newMessageReceived = "newMessageReceived"
        static let conversationUpdated = "conversationUpdated"
        static let openConversation = "openConversation"
    }

    // MARK: - Timeouts
    enum Timeouts {
        static let typingIndicatorDuration: TimeInterval = 3.0
        static let messageRetryInterval: TimeInterval = 5.0
        static let presenceUpdateInterval: TimeInterval = 60.0
    }

    // MARK: - Limits
    enum Limits {
        static let maxMessageLength = 2000
        static let maxGroupParticipants = 50
        static let messagesPerPage = 50
    }
}
