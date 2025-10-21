//
//  ExtensionsTests.swift
//  messageAITests
//
//  Created by Yohan Yi on 10/21/25.
//

import XCTest
import SwiftUI
@testable import messageAI

final class ExtensionsTests: XCTestCase {

    // MARK: - Date Extension Tests

    func testIsToday() {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        // When & Then
        XCTAssertTrue(today.isToday, "Today should be identified as today")
        XCTAssertFalse(yesterday.isToday, "Yesterday should not be identified as today")
    }

    func testIsYesterday() {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

        // When & Then
        XCTAssertFalse(today.isYesterday, "Today should not be identified as yesterday")
        XCTAssertTrue(yesterday.isYesterday, "Yesterday should be identified as yesterday")
        XCTAssertFalse(twoDaysAgo.isYesterday, "Two days ago should not be identified as yesterday")
    }

    func testIsInCurrentWeek() {
        // Given
        let today = Date()
        let lastWeek = Calendar.current.date(byAdding: .day, value: -8, to: Date())!

        // When & Then
        XCTAssertTrue(today.isInCurrentWeek, "Today should be in current week")
        XCTAssertFalse(lastWeek.isInCurrentWeek, "Last week should not be in current week")
    }

    func testRelativeTimeString() {
        // Given
        let now = Date()

        // When
        let relativeTime = now.relativeTimeString

        // Then
        XCTAssertFalse(relativeTime.isEmpty, "Relative time string should not be empty")
        XCTAssertTrue(relativeTime.contains("now") || relativeTime.contains("ago"),
                      "Relative time should contain 'now' or 'ago'")
    }

    func testTimeString() {
        // Given
        let date = Date()

        // When
        let timeString = date.timeString

        // Then
        XCTAssertFalse(timeString.isEmpty, "Time string should not be empty")
        XCTAssertTrue(timeString.contains(":"), "Time string should contain colon separator")
    }

    func testDateString() {
        // Given
        let date = Date()

        // When
        let dateString = date.dateString

        // Then
        XCTAssertFalse(dateString.isEmpty, "Date string should not be empty")
    }

    // MARK: - String Extension Tests

    func testIsValidEmail() {
        // Given
        let validEmails = [
            "test@example.com",
            "user.name@example.co.uk",
            "user+tag@example.com"
        ]
        let invalidEmails = [
            "invalid",
            "@example.com",
            "user@",
            "user @example.com",
            "user@.com"
        ]

        // When & Then
        for email in validEmails {
            XCTAssertTrue(email.isValidEmail, "\(email) should be valid")
        }
        for email in invalidEmails {
            XCTAssertFalse(email.isValidEmail, "\(email) should be invalid")
        }
    }

    func testTrimmed() {
        // Given
        let stringWithSpaces = "  Hello World  "
        let stringWithNewlines = "\nHello\n"
        let normalString = "Hello"

        // When & Then
        XCTAssertEqual(stringWithSpaces.trimmed, "Hello World")
        XCTAssertEqual(stringWithNewlines.trimmed, "Hello")
        XCTAssertEqual(normalString.trimmed, "Hello")
    }

    func testIsBlank() {
        // Given
        let emptyString = ""
        let whitespaceString = "   "
        let normalString = "Hello"

        // When & Then
        XCTAssertTrue(emptyString.isBlank, "Empty string should be blank")
        XCTAssertTrue(whitespaceString.isBlank, "Whitespace string should be blank")
        XCTAssertFalse(normalString.isBlank, "Normal string should not be blank")
    }

    func testTruncated() {
        // Given
        let longString = "This is a very long string"
        let shortString = "Short"

        // When
        let truncatedLong = longString.truncated(to: 10)
        let truncatedShort = shortString.truncated(to: 10)

        // Then
        XCTAssertEqual(truncatedLong, "This is a ...")
        XCTAssertEqual(truncatedShort, "Short")
    }

    func testTruncatedCustomTrailing() {
        // Given
        let longString = "This is a very long string"

        // When
        let truncated = longString.truncated(to: 10, trailing: "…")

        // Then
        XCTAssertEqual(truncated, "This is a …")
    }

    // MARK: - DateFormatter Extension Tests

    func testConversationTimestamp() {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -3, to: Date())!

        // When
        let todayTimestamp = today.conversationTimestamp
        let yesterdayTimestamp = yesterday.conversationTimestamp
        let lastWeekTimestamp = lastWeek.conversationTimestamp

        // Then
        XCTAssertTrue(todayTimestamp.contains(":"), "Today should show time")
        XCTAssertEqual(yesterdayTimestamp, "Yesterday")
        XCTAssertFalse(lastWeekTimestamp.isEmpty, "Last week should show formatted date")
    }

    func testChatSectionHeader() {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -8, to: Date())!

        // When
        let todayHeader = today.chatSectionHeader
        let yesterdayHeader = yesterday.chatSectionHeader
        let lastWeekHeader = lastWeek.chatSectionHeader

        // Then
        XCTAssertEqual(todayHeader, "Today")
        XCTAssertEqual(yesterdayHeader, "Yesterday")
        XCTAssertFalse(lastWeekHeader.isEmpty, "Last week should show formatted date")
    }

    func testLastSeenString() {
        // Given
        let justNow = Date()
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        // When
        let justNowString = justNow.lastSeenString
        let oneHourAgoString = oneHourAgo.lastSeenString
        let yesterdayString = yesterday.lastSeenString

        // Then
        XCTAssertTrue(justNowString.contains("Last seen"), "Should contain 'Last seen'")
        XCTAssertTrue(oneHourAgoString.contains("1h ago") || oneHourAgoString.contains("Last seen"),
                      "Should show hours ago or last seen")
        XCTAssertTrue(yesterdayString.contains("yesterday") || yesterdayString.contains("Last seen"),
                      "Should contain yesterday or last seen")
    }

    // MARK: - Performance Tests

    func testEmailValidationPerformance() {
        let email = "test@example.com"
        measure {
            _ = email.isValidEmail
        }
    }

    func testDateFormattingPerformance() {
        let date = Date()
        measure {
            _ = date.conversationTimestamp
        }
    }
}
