//
//  NotificationServiceTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
@testable import messageAI

@MainActor
final class NotificationServiceTests: XCTestCase {
    
    var sut: NotificationService!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = NotificationService()
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Permission Tests
    
    func testCheckPermissionStatus() async throws {
        // Given: NotificationService is initialized
        
        // When: Check permission status
        let status = await sut.checkPermissionStatus()
        
        // Then: Status should be one of the valid authorization statuses
        XCTAssertTrue([
            .notDetermined,
            .denied,
            .authorized,
            .provisional,
            .ephemeral
        ].contains(where: { $0.rawValue == status.rawValue }),
            "Status should be a valid authorization status")
    }
    
    func testPermissionGrantedProperty() {
        // Given: NotificationService is initialized
        
        // Then: permissionGranted should initially be false
        XCTAssertFalse(sut.permissionGranted)
    }
    
    // MARK: - FCM Token Tests
    
    func testFCMTokenInitiallyNil() {
        // Given: NotificationService is initialized
        
        // Then: FCM token should be nil initially
        XCTAssertNil(sut.fcmToken)
    }
    
    func testFCMTokenCanBeSet() {
        // Given: NotificationService is initialized
        let testToken = "test-fcm-token-12345"
        
        // When: FCM token is set
        sut.fcmToken = testToken
        
        // Then: Token should be stored
        XCTAssertEqual(sut.fcmToken, testToken)
    }
    
    // MARK: - Badge Management Tests
    
    func testClearBadge() {
        // Given: NotificationService is initialized
        
        // When: Clear badge is called
        sut.clearBadge()
        
        // Then: App badge should be 0
        XCTAssertEqual(UIApplication.shared.applicationIconBadgeNumber, 0)
    }
    
    func testUpdateBadge() {
        // Given: NotificationService is initialized
        let badgeCount = 5
        
        // When: Update badge with count
        sut.updateBadge(count: badgeCount)
        
        // Then: App badge should match count
        XCTAssertEqual(UIApplication.shared.applicationIconBadgeNumber, badgeCount)
        
        // Cleanup
        sut.clearBadge()
    }
    
    // MARK: - Error Message Tests
    
    func testErrorMessageInitiallyNil() {
        // Given: NotificationService is initialized
        
        // Then: Error message should be nil initially
        XCTAssertNil(sut.errorMessage)
    }
    
    func testErrorMessageCanBeSet() {
        // Given: NotificationService is initialized
        let errorText = "Test error message"
        
        // When: Error message is set
        sut.errorMessage = errorText
        
        // Then: Error message should be stored
        XCTAssertEqual(sut.errorMessage, errorText)
    }
    
    // MARK: - Notification Error Tests
    
    func testNotificationErrorDescriptions() {
        // Test all error cases have descriptions
        let errors: [NotificationError] = [
            .permissionDenied,
            .permissionRequestFailed,
            .tokenRegistrationFailed,
            .tokenUnregistrationFailed,
            .notificationDisplayFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testPermissionDeniedErrorMessage() {
        // Given: Permission denied error
        let error = NotificationError.permissionDenied
        
        // Then: Error description should be appropriate
        XCTAssertEqual(error.errorDescription, "Notification permissions were denied")
    }
    
    func testTokenRegistrationFailedErrorMessage() {
        // Given: Token registration failed error
        let error = NotificationError.tokenRegistrationFailed
        
        // Then: Error description should be appropriate
        XCTAssertEqual(error.errorDescription, "Failed to register notification token")
    }
    
    // MARK: - Notification Content Tests
    
    func testShowForegroundNotification() async {
        // Given: NotificationService is initialized
        let senderName = "Test User"
        let message = "Hello, this is a test message"
        let conversationId = "test-conversation-123"
        
        // When: Show foreground notification
        await sut.showForegroundNotification(
            from: senderName,
            message: message,
            conversationId: conversationId
        )
        
        // Then: No error should occur (notification should be created)
        // Note: Actual notification display is hard to test without UI testing
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Notification Tap Handling Tests
    
    func testHandleNotificationTap() {
        // Given: NotificationService is initialized
        let conversationId = "test-conversation-456"
        var notificationReceived = false
        
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(Constants.Notifications.openConversation),
            object: nil,
            queue: .main
        ) { notification in
            if let receivedId = notification.userInfo?["conversationId"] as? String {
                XCTAssertEqual(receivedId, conversationId)
                notificationReceived = true
            }
        }
        
        // When: Handle notification tap
        sut.handleNotificationTap(conversationId: conversationId)
        
        // Then: Notification should be posted
        // Small delay to allow notification to be processed
        let expectation = XCTestExpectation(description: "Notification received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(notificationReceived)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Performance Tests
    
    func testBadgeUpdatePerformance() {
        measure {
            for count in 0..<100 {
                sut.updateBadge(count: count)
            }
        }
        
        // Cleanup
        sut.clearBadge()
    }
    
    func testNotificationTapHandlingPerformance() {
        measure {
            for index in 0..<100 {
                sut.handleNotificationTap(conversationId: "conversation-\(index)")
            }
        }
    }
}

