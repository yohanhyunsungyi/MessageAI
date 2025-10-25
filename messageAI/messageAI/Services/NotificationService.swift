//
//  NotificationService.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications
import UIKit
import Combine

/// Service for managing push notifications
/// Handles FCM registration, permission requests, and foreground notifications
@MainActor
final class NotificationService: NSObject, ObservableObject {

    // MARK: - ObservableObject

    let objectWillChange = ObservableObjectPublisher()

    // MARK: - Published Properties

    @Published var fcmToken: String?
    @Published var permissionGranted = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let firestore = FirebaseManager.shared.firestore
    private var notificationCenter: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    // MARK: - Initialization

    override init() {
        super.init()
        setupNotificationDelegate()
    }

    // MARK: - Setup

    /// Setup notification center delegate
    private func setupNotificationDelegate() {
        notificationCenter.delegate = self
        Messaging.messaging().delegate = self
        setupNotificationCategories()
    }

    /// Setup notification categories and actions
    private func setupNotificationCategories() {
        // Define quick reply action
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type a message..."
        )

        // Define mark as read action
        let markReadAction = UNNotificationAction(
            identifier: "MARK_READ_ACTION",
            title: "Mark as Read",
            options: []
        )

        // Create message category
        let messageCategory = UNNotificationCategory(
            identifier: "MESSAGE_CATEGORY",
            actions: [replyAction, markReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Register categories
        notificationCenter.setNotificationCategories([messageCategory])

        print("✅ Notification categories configured")
    }

    // MARK: - Permission Request

    /// Request notification permissions from the user
    func requestPermissions() async throws {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            self.permissionGranted = granted

            if granted {
                print("✅ Notification permissions granted")
                // Register for remote notifications
                UIApplication.shared.registerForRemoteNotifications()
            } else {
                print("❌ Notification permissions denied")
                throw NotificationError.permissionDenied
            }
        } catch {
            print("❌ Failed to request permissions: \(error)")
            throw NotificationError.permissionRequestFailed
        }
    }

    /// Check current notification authorization status
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - FCM Token Management

    /// Register FCM token and save to user document
    func registerToken(userId: String) async throws {
        guard let token = fcmToken else {
            // Token might not be available immediately, will be called when ready
            print("⏳ FCM token not available yet")
            return
        }

        do {
            try await saveTokenToFirestore(userId: userId, token: token)
            print("✅ FCM token registered: \(token)")
        } catch {
            print("❌ Failed to register token: \(error)")
            throw NotificationError.tokenRegistrationFailed
        }
    }

    /// Save FCM token to user document in Firestore
    private func saveTokenToFirestore(userId: String, token: String) async throws {
        try await firestore
            .collection(Constants.Collections.users)
            .document(userId)
            .updateData([
                "fcmToken": token
            ])
    }

    /// Remove FCM token from user document (on sign out)
    func unregisterToken(userId: String) async throws {
        do {
            try await firestore
                .collection(Constants.Collections.users)
                .document(userId)
                .updateData([
                    "fcmToken": ""
                ])

            self.fcmToken = nil
            print("✅ FCM token unregistered")
        } catch {
            print("❌ Failed to unregister token: \(error)")
            throw NotificationError.tokenUnregistrationFailed
        }
    }

    // MARK: - Foreground Notifications

    /// Show a foreground notification when app is active
    func showForegroundNotification(
        from senderName: String,
        message: String,
        conversationId: String,
        senderImageURL: String? = nil
    ) async {
        print("🔔 [NotificationService] showForegroundNotification called")
        print("   - Sender: \(senderName)")
        print("   - Message: \(message)")
        print("   - Conversation: \(conversationId)")

        let content = UNMutableNotificationContent()
        content.title = senderName
        content.body = message
        content.sound = .default
        content.badge = 1

        // Add conversation ID to userInfo for tap handling
        content.userInfo = [
            "conversationId": conversationId,
            "type": "new_message"
        ]

        // Add notification category for message actions
        content.categoryIdentifier = "MESSAGE_CATEGORY"

        // Add sender image as attachment if available
        if let imageURLString = senderImageURL,
           let imageURL = URL(string: imageURLString) {
            await addImageAttachment(to: content, from: imageURL)
        }

        // Create trigger (immediate)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            print("   → Sending notification request to UNUserNotificationCenter...")
            try await notificationCenter.add(request)
            print("✅ [NotificationService] Notification successfully added: \(senderName)")
        } catch {
            print("❌ [NotificationService] Failed to show notification: \(error)")
            print("   Error details: \(error.localizedDescription)")
        }
    }

    /// Add image attachment to notification content
    private func addImageAttachment(to content: UNMutableNotificationContent, from url: URL) async {
        do {
            // Download image data
            let (data, _) = try await URLSession.shared.data(from: url)

            // Save to temporary file
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let fileName = "\(UUID().uuidString).png"
            let fileURL = temporaryDirectory.appendingPathComponent(fileName)

            try data.write(to: fileURL)

            // Create attachment
            let attachment = try UNNotificationAttachment(
                identifier: "sender-image",
                url: fileURL,
                options: [UNNotificationAttachmentOptionsTypeHintKey: "public.png"]
            )

            content.attachments = [attachment]

            print("✅ Added image attachment to notification")
        } catch {
            print("⚠️ Failed to add image attachment: \(error)")
            // Continue without image - notification still works
        }
    }

    // MARK: - Notification Handling

    /// Handle notification tap and navigate to conversation
    func handleNotificationTap(conversationId: String) {
        print("📱 Notification tapped for conversation: \(conversationId)")

        // Post notification for navigation
        NotificationCenter.default.post(
            name: NSNotification.Name(Constants.Notifications.openConversation),
            object: nil,
            userInfo: ["conversationId": conversationId]
        )
    }

    // MARK: - Badge Management

    /// Clear app badge count
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    /// Update app badge count
    func updateBadge(count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    /// Called when notification is received in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        print("🔔 Notification received in foreground: \(userInfo)")

        // Log analytics event to FCM
        Messaging.messaging().appDidReceiveMessage(userInfo)

        // Show banner, play sound, and update badge in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when user taps on notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        print("📱 Notification tapped with userInfo: \(userInfo)")

        // Extract conversation ID
        if let conversationId = userInfo["conversationId"] as? String {
            Task { @MainActor in
                await self.handleNotificationTap(conversationId: conversationId)
            }
        }

        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {

    /// Called when FCM token is refreshed
    nonisolated func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        print("📱 FCM token received: \(fcmToken ?? "nil")")

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.fcmToken = fcmToken

            // Try to register token if user is authenticated
            if let userId = FirebaseManager.shared.currentUserId,
               let token = fcmToken {
                do {
                    try await self.saveTokenToFirestore(userId: userId, token: token)
                    print("✅ FCM token auto-registered")
                } catch {
                    print("⚠️ Failed to auto-register token: \(error)")
                }
            }
        }
    }
}

// MARK: - Error Types

enum NotificationError: LocalizedError {
    case permissionDenied
    case permissionRequestFailed
    case tokenRegistrationFailed
    case tokenUnregistrationFailed
    case notificationDisplayFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permissions were denied"
        case .permissionRequestFailed:
            return "Failed to request notification permissions"
        case .tokenRegistrationFailed:
            return "Failed to register notification token"
        case .tokenUnregistrationFailed:
            return "Failed to unregister notification token"
        case .notificationDisplayFailed:
            return "Failed to display notification"
        }
    }
}
