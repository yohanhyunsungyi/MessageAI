//
//  ActionItemsListView.swift
//  messageAI
//
//  List view for all action items
//

import SwiftUI
import FirebaseFirestore

struct ActionItemsListView: View {
    private let firebaseManager = FirebaseManager.shared
    @State private var actionItems: [ActionItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCompletedOnly = false
    @State private var listener: ListenerRegistration?

    var filteredActionItems: [ActionItem] {
        if showCompletedOnly {
            return actionItems.filter { $0.status == .completed }
        } else {
            return actionItems.filter { $0.status == .pending }
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading && actionItems.isEmpty {
                    ProgressView("Loading action items...")
                } else if filteredActionItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(showCompletedOnly ? "No completed items" : "No pending items")
                            .font(.headline)
                        Text("Action items will appear here when extracted from conversations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredActionItems) { item in
                            ActionItemRowView(
                                actionItem: item,
                                onToggleComplete: { toggledItem in
                                    toggleActionItemStatus(toggledItem)
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    dismissActionItem(item)
                                } label: {
                                    Label("Dismiss", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Action Items")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showCompletedOnly = false
                        } label: {
                            Label("Pending", systemImage: showCompletedOnly ? "circle" : "checkmark.circle")
                        }

                        Button {
                            showCompletedOnly = true
                        } label: {
                            Label("Completed", systemImage: showCompletedOnly ? "checkmark.circle" : "circle")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .onAppear {
                startListening()
            }
            .onDisappear {
                listener?.remove()
            }
        }
    }

    // MARK: - Firestore Listeners

    private func startListening() {
        isLoading = true

        // Listen to all action items in real-time
        listener = firebaseManager.firestore
            .collection("actionItems")
            .order(by: "extractedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                isLoading = false

                if let error = error {
                    print("❌ [ActionItemsListView] Error listening to action items: \(error)")
                    errorMessage = "Failed to load action items: \(error.localizedDescription)"
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ [ActionItemsListView] No action items found")
                    actionItems = []
                    return
                }

                actionItems = documents.compactMap { doc in
                    ActionItem(document: doc.data())
                }

                print("📋 [ActionItemsListView] Loaded \(actionItems.count) action items")
            }
    }

    // MARK: - Actions

    private func toggleActionItemStatus(_ item: ActionItem) {
        let newStatus: ActionItem.Status = item.status == .completed ? .pending : .completed
        let completedAt = newStatus == .completed ? Timestamp(date: Date()) : nil

        firebaseManager.firestore
            .collection("actionItems")
            .document(item.id)
            .updateData([
                "status": newStatus.rawValue,
                "completedAt": completedAt as Any
            ]) { error in
                if let error = error {
                    print("❌ [ActionItemsListView] Error updating action item: \(error)")
                    errorMessage = "Failed to update action item"
                } else {
                    print("✅ [ActionItemsListView] Action item marked as \(newStatus.rawValue)")
                }
            }
    }

    private func dismissActionItem(_ item: ActionItem) {
        firebaseManager.firestore
            .collection("actionItems")
            .document(item.id)
            .updateData([
                "status": ActionItem.Status.dismissed.rawValue
            ]) { error in
                if let error = error {
                    print("❌ [ActionItemsListView] Error dismissing action item: \(error)")
                    errorMessage = "Failed to dismiss action item"
                } else {
                    print("✅ [ActionItemsListView] Action item dismissed")
                }
            }
    }
}

// Preview
#Preview {
    ActionItemsListView()
}
