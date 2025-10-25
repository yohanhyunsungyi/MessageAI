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
import FirebaseAuth
import Combine

/// Service for AI-powered features using Cloud Functions
/// Handles summarization, action items, search, and more
@MainActor
class AIService: ObservableObject {

    // MARK: - Properties

    private let functions: Functions

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Search Cache

    /// Cache for search results
    /// Key: search query, Value: (results, timestamp)
    private var searchCache: [String: (results: [SearchResult], timestamp: Date)] = [:]
    private let cacheExpirationInterval: TimeInterval = 5 * 60 // 5 minutes
    private let maxCachedQueries = 10

    // MARK: - Initialization

    init() {
        // CRITICAL: Use the default Firebase app instance
        // This ensures auth context is automatically included in callable function requests
        self.functions = Functions.functions()

        // NOTE: Firebase automatically routes to the correct region based on function deployment
        // No need to specify region explicitly for callable functions

        // Configure Functions for emulator if needed
        #if DEBUG
        // Uncomment to use emulator during development
        // functions.useEmulator(withHost: "localhost", port: 5001)
        #endif
    }

    // Computed property to access shared Auth instance
    private var auth: Auth {
        FirebaseManager.shared.auth
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
        // Check authentication first
        guard auth.currentUser != nil else {
            let error = NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to use AI features"])
            print("❌ [AIService] User not authenticated")
            throw error
        }

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
            let userId = auth.currentUser?.uid ?? "unknown"
            print("📝 [AIService] User authenticated: \(userId)")

            // Get fresh ID token to ensure it's valid
            if let user = auth.currentUser {
                do {
                    let token = try await user.getIDToken()
                    print("📝 [AIService] Got ID token (length: \(token.count))")
                } catch {
                    print("⚠️ [AIService] Failed to get ID token: \(error)")
                }
            }

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
    /// - Parameter messageLimit: Maximum messages to include (default: 200)
    /// - Returns: Array of action items
    func extractActionItems(conversationId: String, messageLimit: Int = 200) async throws -> [ActionItem] {
        // Check authentication first
        guard auth.currentUser != nil else {
            let error = NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to use AI features"])
            print("❌ [AIService] User not authenticated")
            throw error
        }

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
            let userId = auth.currentUser?.uid ?? "unknown"
            print("📋 [AIService] User authenticated: \(userId)")

            // Get fresh ID token to ensure it's valid
            if let user = auth.currentUser {
                do {
                    let token = try await user.getIDToken()
                    print("📋 [AIService] Got ID token (length: \(token.count))")
                } catch {
                    print("⚠️ [AIService] Failed to get ID token: \(error)")
                }
            }

            print("📋 [AIService] Extracting action items for conversation: \(conversationId)")

            let params: [String: Any] = [
                "conversationId": conversationId,
                "messageLimit": messageLimit
            ]

            let result = try await functions.httpsCallable("extractActionItems").call(params)

            guard let data = result.data as? [String: Any] else {
                throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }

            // Parse the response
            guard let actionItemsData = data["actionItems"] as? [[String: Any]] else {
                throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid action items format"])
            }

            // Convert to ActionItem models
            let actionItems = actionItemsData.compactMap { itemData -> ActionItem? in
                guard let id = itemData["id"] as? String,
                      let description = itemData["description"] as? String,
                      let assignee = itemData["assignee"] as? String,
                      let deadline = itemData["deadline"] as? String,
                      let priorityStr = itemData["priority"] as? String,
                      let priority = ActionItem.Priority(rawValue: priorityStr),
                      let conversationId = itemData["conversationId"] as? String,
                      let conversationName = itemData["conversationName"] as? String,
                      let extractedBy = itemData["extractedBy"] as? String,
                      let statusStr = itemData["status"] as? String,
                      let status = ActionItem.Status(rawValue: statusStr) else {
                    return nil
                }

                return ActionItem(
                    id: id,
                    description: description,
                    assignee: assignee,
                    deadline: deadline,
                    priority: priority,
                    conversationId: conversationId,
                    conversationName: conversationName,
                    extractedAt: Date(),
                    extractedBy: extractedBy,
                    status: status
                )
            }

            print("✅ [AIService] Extracted \(actionItems.count) action items")
            return actionItems

        } catch {
            let errorMsg = handleError(error)
            errorMessage = errorMsg
            print("❌ [AIService] Action item extraction failed: \(errorMsg)")
            throw error
        }
    }

    /// Smart search across all messages using semantic similarity
    /// - Parameters:
    ///   - query: Search query
    ///   - topK: Number of results to return (default: 5)
    ///   - conversationId: Optional conversation filter
    /// - Returns: Array of search results with message data and scores
    func smartSearch(query: String, topK: Int = 5, conversationId: String? = nil) async throws -> [SearchResult] {
        guard checkRateLimit() else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])
        }

        guard !query.isEmpty else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Search query cannot be empty"])
        }

        // Check cache first
        let cacheKey = "\(query)|\(topK)|\(conversationId ?? "")"
        if let cached = getCachedSearchResults(for: cacheKey) {
            print("✅ [AIService] Returning \(cached.count) cached results for query: \(query)")
            return cached
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

            print("🔍 [AIService] Searching for: \(query)")

            let result = try await functions.httpsCallable("smartSearch").call(params)

            guard let data = result.data as? [String: Any],
                  let resultsData = data["results"] as? [[String: Any]] else {
                print("⚠️ [AIService] No results found for query: \(query)")
                return []
            }

            // Parse results into SearchResult models
            let results = resultsData.compactMap { SearchResult(from: $0) }

            print("✅ [AIService] Found \(results.count) results for query: \(query)")

            // Cache the results
            cacheSearchResults(results, for: cacheKey)

            return results
        } catch {
            let errorMsg = handleError(error)
            errorMessage = errorMsg
            throw error
        }
    }

    // MARK: - Cache Management

    /// Get cached search results if still valid
    private func getCachedSearchResults(for key: String) -> [SearchResult]? {
        guard let cached = searchCache[key] else {
            return nil
        }

        // Check if cache is still valid
        let now = Date()
        if now.timeIntervalSince(cached.timestamp) < cacheExpirationInterval {
            return cached.results
        }

        // Cache expired, remove it
        searchCache.removeValue(forKey: key)
        return nil
    }

    /// Cache search results
    private func cacheSearchResults(_ results: [SearchResult], for key: String) {
        // Enforce cache size limit
        if searchCache.count >= maxCachedQueries {
            // Remove oldest entry
            if let oldestKey = searchCache.min(by: { $0.value.timestamp < $1.value.timestamp })?.key {
                searchCache.removeValue(forKey: oldestKey)
            }
        }

        searchCache[key] = (results: results, timestamp: Date())
    }

    /// Clear search cache
    func clearSearchCache() {
        searchCache.removeAll()
        print("🗑️ [AIService] Search cache cleared")
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
