# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.


# Rules Rules Rules
- No Over-Engineering - Implement only what is planned, keep it simple
- Production Code Only - No mocks, stubs, placeholders, or temporary files. Everything must actually work and be connected
- No Fake Implementations - If not ready, let it error. Don't pretend with mock data
- Search First - Always check for existing reusable modules before creating new ones
- Minimal Changes - Only modify code related to current task. Don't touch unrelated code
- Research Unknown Code - Use Context7 MCP or web search. Never guess
- Ask When Unclear - Don't assume. Confirm with user if ambiguous
- First Build Mindset - NO fallbacks, backward compatibility, or migrations. Errors are expected if wrong
- Complete Tasks Properly - Update TODO and commit after each task
- Simple, clean, real. Production-level code only.

## Project Overview

MessageAI is a production-quality iOS messaging application built with SwiftUI, Firebase, and a local-first architecture. The app implements real-time messaging with offline support, typing indicators, presence tracking, and push notifications.

**Key Technologies:**
- iOS 26.0+ with Swift 5.9+ and SwiftUI
- Firebase (Firestore, Auth, FCM, Cloud Functions)
- SwiftData for local persistence
- Local-first architecture for instant UI updates

## Development Commands

### iOS Development

```bash
# Open project in Xcode
open messageAI/messageAI.xcodeproj

# Build project (in Xcode: ⌘B)
xcodebuild -scheme messageAI -configuration Debug build

# Run tests (in Xcode: ⌘U)
xcodebuild test -scheme messageAI -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test suite
xcodebuild test -scheme messageAI -only-testing:messageAITests
xcodebuild test -scheme messageAI -only-testing:messageAIUITests

# Clean build folder (in Xcode: ⌘⇧K)
xcodebuild clean -scheme messageAI
```

### Firebase Development

```bash
# Deploy Firestore rules and indexes
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes

# Deploy Cloud Functions
cd backend/functions
npm install
npm run deploy

# Start Firebase emulators for local development
firebase emulators:start

# Emulator ports:
# - Auth: localhost:9099
# - Firestore: localhost:8080
# - Functions: localhost:5001
# - UI Dashboard: localhost:4000

# View Firebase logs
firebase functions:log
```

### Testing & Reset Scripts

```bash
# Complete reset (deletes all Firestore data, resets simulators)
./complete-reset.sh

# Reset iOS simulator only
./reset-simulator.sh

# Deploy notification functions
./deploy-notifications.sh
```

## Architecture

### Local-First Pattern

MessageAI uses a **local-first architecture** where all operations happen locally first, then sync to Firebase:

1. **Write to local SwiftData storage** (instant UI update)
2. **Update UI immediately** with optimistic updates
3. **Sync to Firestore** in background
4. **Handle conflicts** if sync fails

```swift
// Example: Sending a message
func sendMessage(text: String) async {
    // 1. Create message with temporary ID
    let message = Message(id: UUID().uuidString, text: text, status: .sending)

    // 2. Save to local storage (instant)
    await localStorageService.saveMessage(message)

    // 3. Update UI (instant)
    messages.append(message)

    // 4. Sync to Firestore (background)
    do {
        let serverMessage = try await syncToFirestore(message)
        // Update with server ID and status
        updateMessage(serverMessage)
    } catch {
        // Mark as failed, allow retry
        message.status = .failed
    }
}
```

### Core Services Layer

**FirebaseManager** (`Services/FirebaseManager.swift`):
- Singleton providing centralized access to Firebase Auth and Firestore
- Configures offline persistence with unlimited cache
- Access via `FirebaseManager.shared`

**MessageService** (`Services/MessageService.swift`):
- Handles all message operations (send, receive, listen)
- Implements local-first pattern with SwiftData
- Manages offline queue for failed sends
- Real-time listeners for incoming messages

**ConversationService** (`Services/ConversationService.swift`):
- Creates and manages conversations (1-on-1 and group)
- Tracks participants, last message, unread counts
- Syncs with local storage

**PresenceService** (`Services/PresenceService.swift`):
- Tracks online/offline status for users
- Updates user status in Firestore
- Listens to presence changes

**NotificationService** (`Services/NotificationService.swift`):
- Handles FCM token registration
- Manages foreground notifications
- Shows in-app notifications when app is open

**LocalStorageService** (`Services/LocalStorageService.swift`):
- SwiftData wrapper for offline persistence
- Stores messages and conversations locally
- Handles migrations and queries

### Data Flow

```
User Action (UI)
    ↓
ViewModel
    ↓
Service Layer (local-first)
    ↓
Local Storage (SwiftData) ← Instant UI update
    ↓
Firebase Sync (background)
    ↓
Firestore ← Real-time listeners
    ↓
Service Layer (incoming changes)
    ↓
ViewModel
    ↓
UI Update
```

### Firestore Data Structure

```
/users/{userId}
  - email: string
  - displayName: string
  - profileImageURL: string?
  - isOnline: boolean
  - lastSeen: timestamp
  - fcmToken: string?

/conversations/{conversationId}
  - type: "oneOnOne" | "group"
  - participantIds: [string]
  - participantNames: [string]
  - createdAt: timestamp
  - lastMessage: string?
  - lastMessageTimestamp: timestamp?
  - unreadCount: {userId: number}

  /messages/{messageId}
    - id: string
    - conversationId: string
    - senderId: string
    - text: string
    - timestamp: timestamp
    - status: "sending" | "sent" | "delivered" | "read"
    - readBy: [string]

  /typing/{userId}
    - isTyping: boolean
    - timestamp: timestamp
```

## Project Structure

```
messageAI/messageAI/
├── Services/           # Business logic layer
│   ├── FirebaseManager.swift
│   ├── AuthService.swift
│   ├── UserService.swift
│   ├── ConversationService.swift
│   ├── MessageService.swift
│   ├── PresenceService.swift
│   ├── NotificationService.swift
│   └── LocalStorageService.swift
├── ViewModels/         # State management
│   ├── AuthViewModel.swift
│   ├── UsersViewModel.swift
│   ├── ConversationsViewModel.swift
│   └── ChatViewModel.swift
├── Views/              # SwiftUI views
│   ├── Auth/           # Sign in/up flows
│   ├── Main/           # Tab navigation
│   ├── Users/          # User list
│   ├── Conversations/  # Conversation list
│   ├── Chat/           # Message UI
│   ├── Profile/        # User profile
│   └── Onboarding/     # First-time setup
├── Models/             # Firebase data models
│   ├── User.swift
│   ├── Message.swift
│   ├── Conversation.swift
│   ├── MessageStatus.swift
│   └── ConversationType.swift
├── LocalModels/        # SwiftData models
│   ├── LocalMessage.swift
│   └── LocalConversation.swift
└── Utils/              # Helpers
    ├── Constants.swift
    ├── UIStyleGuide.swift
    └── Extensions.swift
```

## Important Patterns

### @MainActor Usage
All ViewModels and Services that update UI are marked `@MainActor` to ensure UI updates happen on main thread:

```swift
@MainActor
class MessageService: ObservableObject {
    @Published var messages: [Message] = []
    // ...
}
```

### Error Handling
Services use `@Published var errorMessage: String?` for user-facing errors. Always handle Firebase errors gracefully:

```swift
do {
    try await firestore.collection("messages").addDocument(...)
} catch {
    errorMessage = "Failed to send message: \(error.localizedDescription)"
    print("❌ [MessageService] Error: \(error)")
}
```

### Firebase Listeners
Always store listener references and clean them up:

```swift
private var listener: ListenerRegistration?

func startListening() {
    listener = firestore.collection("messages")
        .addSnapshotListener { snapshot, error in
            // Handle updates
        }
}

deinit {
    listener?.remove()
}
```

### SwiftData Queries
Use predicate-based queries for local storage:

```swift
let descriptor = FetchDescriptor<LocalMessage>(
    predicate: #Predicate { msg in
        msg.conversationId == conversationId
    },
    sortBy: [SortDescriptor(\.timestamp)]
)
let messages = try modelContext.fetch(descriptor)
```

## Common Development Workflows

### Adding a New Feature

1. Update data models if needed (`Models/` and `LocalModels/`)
2. Add service methods in appropriate service file
3. Update ViewModel to expose new functionality
4. Create/update SwiftUI views
5. Test with Firebase emulators first
6. Deploy Firestore rules if data structure changed

### Modifying Firestore Rules

1. Edit `firestore.rules`
2. Test rules with emulators: `firebase emulators:start`
3. Deploy: `firebase deploy --only firestore:rules`
4. Verify in Firebase Console

### Testing Firebase Integrations

Always use Firebase emulators for testing:

```bash
# Terminal 1: Start emulators
firebase emulators:start

# Terminal 2: Run tests
xcodebuild test -scheme messageAI -only-testing:messageAITests/Integration
```

Access emulator UI at http://localhost:4000 to inspect data during testing.

## Configuration Notes

### GoogleService-Info.plist
This file is in `.gitignore` and must be added manually:
1. Download from Firebase Console
2. Place at `messageAI/messageAI/GoogleService-Info.plist`
3. Ensure bundle ID matches: `app.messageAI.messageAI`

### Firebase Project
- Project ID: `messagingai-75f21`
- Region: us-central1
- Enable: Auth (Email/Password, Google), Firestore, FCM

### Deployment Target
- iOS 26.0+ required
- Xcode 16.0+ required
- Swift 5.9+ required

## Known Patterns & Conventions

- Use `// MARK: -` comments to organize code sections
- Prefix print statements with emoji for easy filtering: `print("📨 [MessageService] Sending message")`
- Always use `async/await` over completion handlers
- Use `@Published` for any state that drives UI
- Keep ViewModels thin - business logic belongs in Services
- Use dependency injection for Services (pass to ViewModels)
- Test against emulators before production deployment

## Documentation References

- [Architecture.md](Architecture.md) - Visual architecture diagram
- [PRD.md](PRD.md) - Full product requirements (1160 lines)
- [Tasks.md](Tasks.md) - Development task breakdown with PR tracking
- [TESTING_NOTES.md](TESTING_NOTES.md) - Comprehensive testing guide
- [README.md](README.md) - Setup instructions and feature list
