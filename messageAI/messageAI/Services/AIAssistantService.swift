//
//  AIAssistantService.swift
//  messageAI
//
//  AI Assistant chat conversation manager
//  Handles local message history and AI interactions
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFunctions

/// AI Assistant message for local chat history
struct AIAssistantMessage: Identifiable, Equatable {
    let id: String
    let text: String
    let isFromUser: Bool
    let timestamp: Date

    init(id: String = UUID().uuidString, text: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

/// Service for managing AI Assistant conversation
/// This is a special, local-only conversation (not stored in Firestore)
@MainActor
class AIAssistantService: ObservableObject {

    // MARK: - Constants

    static let assistantConversationId = "ai-assistant"

    // MARK: - Published Properties

    @Published var messages: [AIAssistantMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let functions: Functions

    // MARK: - Initialization

    init() {
        self.functions = Functions.functions()

        // Add welcome message on first launch
        addWelcomeMessage()
    }

    private var auth: Auth {
        FirebaseManager.shared.auth
    }

    // MARK: - Welcome Message

    private func addWelcomeMessage() {
        let welcomeText = """
        👋 Hi! I'm your AI Assistant.

        I can help you with:
        • Summarize conversations
        • Find action items
        • Search messages
        • Track decisions

        **Try saying:**
        "Summarize my latest conversation"
        "What are my tasks?"
        "Search for deployment"
        """

        let welcomeMessage = AIAssistantMessage(
            text: welcomeText,
            isFromUser: false
        )

        messages.append(welcomeMessage)
    }

    // MARK: - Send Message

    /// Send a message to the AI Assistant
    /// - Parameter text: User's message text
    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }

        // Add user message to local history
        let userMessage = AIAssistantMessage(
            text: text,
            isFromUser: true
        )
        messages.append(userMessage)

        isLoading = true
        errorMessage = nil

        do {
            print("🤖 [AIAssistantService] Sending message to AI Assistant")

            // Call Cloud Function
            let params: [String: Any] = [
                "message": text
            ]

            let result = try await functions.httpsCallable("aiAssistant").call(params)

            guard let data = result.data as? [String: Any],
                  let response = data["response"] as? String else {
                throw NSError(domain: "AIAssistantService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }

            // Add AI response to local history
            let aiMessage = AIAssistantMessage(
                text: response,
                isFromUser: false
            )
            messages.append(aiMessage)

            print("✅ [AIAssistantService] Received AI response")

        } catch {
            print("❌ [AIAssistantService] Error: \(error.localizedDescription)")
            errorMessage = handleError(error)

            // Add error message to chat
            let errorMsg = AIAssistantMessage(
                text: "Sorry, I encountered an error: \(errorMessage ?? "Unknown error"). Please try again.",
                isFromUser: false
            )
            messages.append(errorMsg)
        }

        isLoading = false
    }

    // MARK: - Clear History

    /// Clear chat history (except welcome message)
    func clearHistory() {
        // Keep only the first welcome message
        if let welcomeMessage = messages.first {
            messages = [welcomeMessage]
        } else {
            messages = []
            addWelcomeMessage()
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) -> String {
        if let functionsError = error as NSError? {
            switch functionsError.code {
            case FunctionsErrorCode.unavailable.rawValue:
                return "AI service is temporarily unavailable."
            case FunctionsErrorCode.unauthenticated.rawValue:
                return "Please sign in to use AI features."
            case FunctionsErrorCode.resourceExhausted.rawValue:
                return "Rate limit exceeded. Please try again in a few minutes."
            case FunctionsErrorCode.invalidArgument.rawValue:
                return "Invalid request."
            case FunctionsErrorCode.deadlineExceeded.rawValue:
                return "Request timed out."
            default:
                return error.localizedDescription
            }
        }

        return "An unexpected error occurred."
    }
}
