//
//  ProactiveAssistantService.swift
//  messageAI
//
//  Service for listening to proactive suggestions from AI assistant
//

import Foundation
import FirebaseFirestore
import Combine

/// Service for managing proactive AI suggestions
@MainActor
class ProactiveAssistantService: ObservableObject {

    // MARK: - Properties

    private let firestore: Firestore
    private var listener: ListenerRegistration?

    @Published var activeSuggestions: [ProactiveSuggestion] = []
    @Published var errorMessage: String?

    // MARK: - Initialization

    init() {
        self.firestore = FirebaseManager.shared.firestore
    }

    // MARK: - Listening

    /// Start listening for suggestions in a specific conversation
    /// - Parameter conversationId: The conversation to monitor
    func startListening(for conversationId: String) {
        print("👂 [ProactiveAssistantService] Starting listener for conversation: \(conversationId)")

        stopListening() // Stop any previous listener

        listener = firestore.collection("proactiveSuggestions")
            .whereField("conversationId", isEqualTo: conversationId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ [ProactiveAssistantService] Listener error: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load suggestions"
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ [ProactiveAssistantService] No documents found")
                    return
                }

                // Parse suggestions
                let suggestions = documents.compactMap { doc -> ProactiveSuggestion? in
                    do {
                        let suggestion = try doc.data(as: ProactiveSuggestion.self)
                        // Ensure the document ID is set
                        if suggestion.id == nil {
                            var mutableSuggestion = suggestion
                            mutableSuggestion.id = doc.documentID
                            return mutableSuggestion
                        }
                        return suggestion
                    } catch {
                        print("❌ [ProactiveAssistantService] Failed to decode suggestion: \(error)")
                        return nil
                    }
                }

                // Filter for valid suggestions only
                let validSuggestions = suggestions.filter { $0.isStillValid }

                print("✅ [ProactiveAssistantService] Loaded \(validSuggestions.count) active suggestions")
                self.activeSuggestions = validSuggestions
            }
    }

    /// Stop listening for suggestions
    func stopListening() {
        listener?.remove()
        listener = nil
        print("🛑 [ProactiveAssistantService] Stopped listening")
    }

    // MARK: - Actions

    /// Accept a suggestion and create calendar event
    /// - Parameters:
    ///   - suggestion: The suggestion to accept
    ///   - timeSlot: The selected time slot
    func acceptSuggestion(_ suggestion: ProactiveSuggestion, timeSlot: TimeSlot) async throws {
        guard let suggestionId = suggestion.id else {
            throw NSError(domain: "ProactiveAssistantService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid suggestion ID"])
        }

        print("✅ [ProactiveAssistantService] Accepting suggestion: \(suggestionId)")

        // Update Firestore
        try await firestore.collection("proactiveSuggestions")
            .document(suggestionId)
            .updateData([
                "status": "accepted",
                "acceptedTimeSlot": try Firestore.Encoder().encode(timeSlot),
                "acceptedAt": FieldValue.serverTimestamp()
            ])

        print("✅ [ProactiveAssistantService] Suggestion accepted successfully")
    }

    /// Dismiss a suggestion
    /// - Parameter suggestion: The suggestion to dismiss
    func dismissSuggestion(_ suggestion: ProactiveSuggestion) async throws {
        guard let suggestionId = suggestion.id else {
            throw NSError(domain: "ProactiveAssistantService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid suggestion ID"])
        }

        print("❌ [ProactiveAssistantService] Dismissing suggestion: \(suggestionId)")

        // Update Firestore
        try await firestore.collection("proactiveSuggestions")
            .document(suggestionId)
            .updateData([
                "status": "dismissed",
                "dismissedAt": FieldValue.serverTimestamp()
            ])

        print("✅ [ProactiveAssistantService] Suggestion dismissed successfully")
    }
}
