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
    /// - Returns: Summary object with key points
    func summarizeConversation(conversationId: String) async throws -> String {
        // TODO: Implement in PR #24
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not yet implemented"])
    }

    /// Extract action items from a conversation
    /// - Parameter conversationId: ID of the conversation
    /// - Returns: Array of action items
    func extractActionItems(conversationId: String) async throws -> [String] {
        // TODO: Implement in PR #25
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not yet implemented"])
    }

    /// Smart search across all messages
    /// - Parameter query: Search query
    /// - Returns: Array of relevant messages
    func smartSearch(query: String) async throws -> [String] {
        // TODO: Implement in PR #26
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not yet implemented"])
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
