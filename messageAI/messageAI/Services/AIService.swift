//
//  AIService.swift
//  messageAI
//
//  AI Service wrapper for calling Firebase Cloud Functions
//  Handles all AI feature requests and responses
//

import Foundation
import FirebaseCore
import FirebaseFunctions

/// Service for AI-powered features using Cloud Functions
/// Handles summarization, action items, search, and more
@MainActor
class AIService: ObservableObject {

    // MARK: - Properties

    private let functions = Functions.functions()

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Initialization

    init() {
        // Configure Functions for emulator if needed
        #if DEBUG
        // Uncomment to use emulator during development
        // functions.useEmulator(withHost: "localhost", port: 5001)
        #endif
    }

    // MARK: - Rate Limiting

    /// Check if rate limit is exceeded
    /// Returns true if the call can proceed
    private func checkRateLimit() -> Bool {
        // TODO: Implement client-side rate limiting check
        // Track number of AI calls per minute/day
        return true
    }

    // MARK: - Error Handling

    /// Handle errors from Cloud Functions
    private func handleError(_ error: Error) -> String {
        print("❌ [AIService] Error: \(error.localizedDescription)")

        if let functionsError = error as NSError? {
            switch functionsError.code {
            case FunctionsErrorCode.unavailable.rawValue:
                return "AI service is temporarily unavailable. Please try again."
            case FunctionsErrorCode.unauthenticated.rawValue:
                return "You must be signed in to use AI features."
            case FunctionsErrorCode.resourceExhausted.rawValue:
                return "Rate limit exceeded. Please try again in a few minutes."
            case FunctionsErrorCode.invalidArgument.rawValue:
                return "Invalid request. Please try again."
            case FunctionsErrorCode.deadlineExceeded.rawValue:
                return "Request timed out. The AI is taking too long to respond."
            default:
                return "An error occurred: \(error.localizedDescription)"
            }
        }

        return "An unexpected error occurred. Please try again."
    }

    // MARK: - Placeholder Methods (to be implemented in future PRs)

    /// Summarize a conversation thread
    /// - Parameter conversationId: ID of the conversation to summarize
    /// - Parameter messageLimit: Maximum messages to include (default: 200)
    /// - Returns: Summary object with key points
    func summarizeConversation(conversationId: String, messageLimit: Int = 200) async throws -> Summary {
        guard checkRateLimit() else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])
        }

        guard !conversationId.isEmpty else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Conversation ID cannot be empty"])
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            print("📝 [AIService] Requesting summary for conversation: \(conversationId)")

            let params: [String: Any] = [
                "conversationId": conversationId,
                "messageLimit": messageLimit
            ]

            let result = try await functions.httpsCallable("summarizeConversation").call(params)

            guard let data = result.data as? [String: Any] else {
                throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }

            // Parse the response
            let summaryText = data["summary"] as? String ?? ""
            let keyPoints = data["keyPoints"] as? [String] ?? []
            let messageCount = data["messageCount"] as? Int ?? 0
            let participants = data["participants"] as? [String] ?? []

            // Parse time range if present
            var timeRange: Summary.TimeRange? = nil
            if let timeRangeData = data["timeRange"] as? [String: Any],
               let startTimestamp = timeRangeData["start"] as? [String: Any],
               let endTimestamp = timeRangeData["end"] as? [String: Any],
               let startSeconds = startTimestamp["_seconds"] as? Double,
               let endSeconds = endTimestamp["_seconds"] as? Double {
                timeRange = Summary.TimeRange(
                    start: Date(timeIntervalSince1970: startSeconds),
                    end: Date(timeIntervalSince1970: endSeconds)
                )
            }

            let summary = Summary(
                conversationId: conversationId,
                summary: summaryText,
                keyPoints: keyPoints,
                messageCount: messageCount,
                timeRange: timeRange,
                participants: participants
            )

            print("✅ [AIService] Summary generated: \(keyPoints.count) key points")
            return summary

        } catch {
            let errorMsg = handleError(error)
            errorMessage = errorMsg
            print("❌ [AIService] Summarization failed: \(errorMsg)")
            throw error
        }
    }

    /// Extract action items from a conversation
    /// - Parameter conversationId: ID of the conversation
    /// - Returns: Array of action items
    func extractActionItems(conversationId: String) async throws -> [String] {
        // TODO: Implement in PR #25
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not yet implemented"])
    }

    /// Smart search across all messages using semantic similarity
    /// - Parameters:
    ///   - query: Search query
    ///   - topK: Number of results to return (default: 5)
    ///   - conversationId: Optional conversation filter
    /// - Returns: Array of search results with message data and scores
    func smartSearch(query: String, topK: Int = 5, conversationId: String? = nil) async throws -> [[String: Any]] {
        guard checkRateLimit() else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])
        }

        guard !query.isEmpty else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Search query cannot be empty"])
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            var params: [String: Any] = [
                "query": query,
                "topK": topK
            ]

            if let conversationId = conversationId {
                params["conversationId"] = conversationId
            }

            let result = try await functions.httpsCallable("smartSearch").call(params)

            if let data = result.data as? [String: Any],
               let results = data["results"] as? [[String: Any]] {
                print("✅ [AIService] Found \(results.count) results for query: \(query)")
                return results
            }

            return []
        } catch {
            let errorMsg = handleError(error)
            errorMessage = errorMsg
            throw error
        }
    }

    /// Extract decisions from a conversation
    /// - Parameter conversationId: ID of the conversation
    /// - Returns: Array of decisions
    func extractDecisions(conversationId: String) async throws -> [String] {
        // TODO: Implement in PR #28
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not yet implemented"])
    }

    // MARK: - Test Function

    /// Test Cloud Functions connection
    /// Calls a simple hello-world function to verify setup
    func testConnection() async throws -> String {
        guard checkRateLimit() else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let result = try await functions.httpsCallable("testAI").call()

            if let data = result.data as? [String: Any],
               let message = data["message"] as? String {
                return message
            }

            return "Connection successful"
        } catch {
            let errorMsg = handleError(error)
            errorMessage = errorMsg
            throw error
        }
    }
}
