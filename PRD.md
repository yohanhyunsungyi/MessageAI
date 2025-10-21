# MessageAI MVP - Product Requirements Document

## Project Overview

**Project Name:** MessageAI MVP  
**Platform:** iOS (Swift + SwiftUI)  
**Backend:** Firebase (Firestore, Auth, Cloud Functions, FCM)  
**Timeline:** 24 hours  
**Objective:** Build a production-quality messaging infrastructure with real-time sync, offline support, and reliable message delivery.

---

## 1. Technical Architecture

### 1.1 System Components

```
┌─────────────────┐
│   iOS App       │
│   (SwiftUI)     │
├─────────────────┤
│ • UI Layer      │
│ • ViewModels    │
│ • Local Storage │
│ • Firebase SDK  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Firebase      │
├─────────────────┤
│ • Firestore     │
│ • Auth          │
│ • FCM           │
│ • Functions     │
└─────────────────┘
```

### 1.2 Tech Stack

**Frontend (iOS)**
- Swift 5.9+
- SwiftUI for UI
- SwiftData for local persistence
- Combine for reactive programming
- Firebase iOS SDK

**Backend (Firebase)**
- Firestore: Real-time database
- Firebase Auth: User authentication
- Cloud Functions: Server-side logic
- FCM: Push notifications

---

## 2. Data Models

### 2.1 Firestore Collections

#### **Users Collection** (`/users/{userId}`)
```swift
struct User: Codable, Identifiable {
    let id: String              // Firebase Auth UID
    var displayName: String
    var photoURL: String?
    var phoneNumber: String?
    var isOnline: Bool
    var lastSeen: Date
    var fcmToken: String?
    var createdAt: Date
}
```

#### **Conversations Collection** (`/conversations/{conversationId}`)
```swift
struct Conversation: Codable, Identifiable {
    let id: String
    var participantIds: [String]        // User IDs
    var participantNames: [String: String] // userId: displayName
    var participantPhotos: [String: String?] // userId: photoURL
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var lastMessageSenderId: String?
    var type: ConversationType          // .oneOnOne or .group
    var groupName: String?              // Only for groups
    var createdAt: Date
    var createdBy: String
}

enum ConversationType: String, Codable {
    case oneOnOne
    case group
}
```

#### **Messages Subcollection** (`/conversations/{conversationId}/messages/{messageId}`)
```swift
struct Message: Codable, Identifiable {
    let id: String
    let senderId: String
    let senderName: String
    let senderPhotoURL: String?
    var text: String
    var timestamp: Date
    var status: MessageStatus
    var readBy: [String: Date]          // userId: readTimestamp
    var deliveredTo: [String: Date]     // userId: deliveredTimestamp
    var localId: String?                // For optimistic updates
}

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}
```

### 2.2 Local Storage (SwiftData)

```swift
@Model
class LocalMessage {
    @Attribute(.unique) var id: String
    var conversationId: String
    var senderId: String
    var senderName: String
    var text: String
    var timestamp: Date
    var status: String
    var isPending: Bool
    var localId: String?
    
    init(id: String, conversationId: String, senderId: String, 
         senderName: String, text: String, timestamp: Date, 
         status: String, isPending: Bool, localId: String?) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
        self.status = status
        self.isPending = isPending
        self.localId = localId
    }
}

@Model
class LocalConversation {
    @Attribute(.unique) var id: String
    var participantIds: [String]
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var type: String
    var groupName: String?
    
    init(id: String, participantIds: [String], lastMessage: String?, 
         lastMessageTimestamp: Date?, type: String, groupName: String?) {
        self.id = id
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.type = type
        self.groupName = groupName
    }
}
```

---

## 3. Core Features Specification

### 3.1 Authentication

**Requirements:**
- Email/password authentication
- Google Social Login (Sign in with Google)
- User profile creation with onboarding screen
- Session persistence

**Implementation:**
```swift
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var needsOnboarding = false
    
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signInWithGoogle() async throws
    func signOut() throws
    func completeOnboarding(displayName: String, photoURL: String?) async throws
}
```

**Onboarding Flow:**
1. User signs up or signs in with Google
2. Check if user profile exists in Firestore
3. If new user → show OnboardingView
4. User enters display name and optional photo
5. Create user document in Firestore
6. Navigate to main app

### 3.2 One-on-One Chat

**Requirements:**
- Start new conversations
- Send text messages
- Real-time message delivery
- Message persistence
- Optimistic UI updates

**User Flow:**
1. User selects a contact or enters contact details
2. System creates or retrieves conversation
3. User types message and taps send
4. Message appears immediately in UI (optimistic)
5. Message syncs to Firestore
6. Recipient receives message in real-time
7. Status updates: sending → sent → delivered → read

### 3.3 Group Chat

**Requirements:**
- Create groups with 3+ participants
- Add/remove participants (creator only)
- Group name and avatar
- Message attribution (show sender name)
- Delivery tracking per participant

**User Flow:**
1. User creates group, selects participants
2. User sets group name
3. Messages show sender name/photo
4. All participants see messages in real-time
5. Read receipts show who read the message

### 3.4 Real-Time Messaging

**Requirements:**
- Sub-100ms message delivery (when online)
- Firestore real-time listeners
- Automatic reconnection
- Queue messages when offline
- Sync on reconnection

**Implementation Strategy:**
- Use Firestore snapshots for real-time updates
- Local queue for offline messages
- Background sync when connectivity returns
- Handle app lifecycle (foreground/background)

### 3.5 Message Status & Read Receipts

**Status Flow:**
```
User A sends message:
1. sending → update local storage immediately (instant UI feedback)
2. sent → written to Firestore (cloud sync complete)
3. delivered → User B's device receives message
4. read → User B opens chat and views message
```

**Local-First Approach:**
- Update local SwiftData storage FIRST for instant UI
- Then sync to Firestore in background
- UI shows message immediately without waiting for server

**Implementation:**
- Update `status` field in Firestore
- Update `deliveredTo` map when message received
- Update `readBy` map when user views message
- Show checkmarks in UI: ✓ (sent), ✓✓ (delivered), ✓✓ (read - blue)

**Read Receipt Logic:**
```swift
func markMessagesAsRead(conversationId: String, messageIds: [String]) async {
    let userId = currentUserId
    let timestamp = Date()
    
    // 1. Update local storage first (instant UI)
    await localDB.markAsRead(messageIds)
    
    // 2. Update Firestore in background
    for messageId in messageIds {
        firestore.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .updateData([
                "readBy.\(userId)": timestamp,
                "status": "read"
            ])
    }
}
```

### 3.6 Online/Offline Presence

**Requirements:**
- Show online/offline indicator
- Last seen timestamp
- Real-time updates

**Implementation:**
- Update `isOnline` and `lastSeen` in Firestore
- Use Firebase Presence system
- Handle app lifecycle events
- Show "Online" or "Last seen at HH:MM"

### 3.7 Typing Indicators

**Requirements:**
- Show when other user is typing
- Hide after 3 seconds of inactivity
- Works in groups (show "User X is typing...")

**Implementation:**
- Create temporary subcollection `/conversations/{id}/typing/{userId}`
- Set with TTL (auto-delete after 3 seconds)
- Listen for changes
- Debounce typing events

### 3.8 Push Notifications

**Requirements:**
- **Foreground notifications ONLY** (when app is open)
- Show sender name and message preview
- Tap notification banner to jump to conversation
- Simple implementation without background complexity

**Implementation:**
- Register for FCM token on app launch
- Store token in user document
- Use UNUserNotificationCenter for local notifications
- Display banner when new message arrives while app is active
- No background notification handling for MVP

**Note:** Background push notifications are out of scope for MVP to keep implementation simple and fast.

---

## 4. Service Layer Architecture

### 4.1 MessageService

```swift
class MessageService: ObservableObject {
    @Published var messages: [Message] = []
    private var listener: ListenerRegistration?
    
    // Real-time message listener
    func startListening(conversationId: String)
    
    // Send message with optimistic update
    func sendMessage(conversationId: String, text: String, senderId: String) async throws
    
    // Mark messages as read
    func markAsRead(conversationId: String, messageIds: [String], userId: String) async throws
    
    // Handle offline queue
    func processOfflineQueue() async
}
```

### 4.2 ConversationService

```swift
class ConversationService: ObservableObject {
    @Published var conversations: [Conversation] = []
    
    // Create one-on-one conversation
    func createOrGetConversation(participantIds: [String]) async throws -> String
    
    // Create group conversation
    func createGroupConversation(participantIds: [String], groupName: String) async throws -> String
    
    // Get conversation by ID
    func getConversation(id: String) async throws -> Conversation
    
    // Update last message
    func updateLastMessage(conversationId: String, message: Message) async throws
}
```

### 4.3 PresenceService

```swift
class PresenceService {
    // Set user online
    func setOnline(userId: String) async throws
    
    // Set user offline
    func setOffline(userId: String) async throws
    
    // Listen to presence changes
    func observePresence(userIds: [String]) -> AsyncStream<[String: Bool]>
}
```

### 4.4 NotificationService

```swift
class NotificationService {
    // Request notification permissions
    func requestPermissions() async throws
    
    // Register FCM token
    func registerToken() async throws
    
    // Show foreground notification
    func showForegroundNotification(from: String, message: String, conversationId: String)
    
    // Handle notification tap
    func handleNotificationTap(conversationId: String)
}
```

### 4.5 UserService

```swift
class UserService: ObservableObject {
    @Published var allUsers: [User] = []
    
    // Fetch all registered users
    func fetchAllUsers() async throws -> [User]
    
    // Get specific user by ID
    func getUser(id: String) async throws -> User
    
    // Search users by name
    func searchUsers(query: String) -> [User]
    
    // Update user profile
    func updateProfile(userId: String, displayName: String, photoURL: String?) async throws
}
```

---

## 5. UI Components

### 5.1 View Hierarchy

```
App
├── AuthView (login/signup/Google sign-in)
├── OnboardingView (profile setup for new users)
├── MainTabView
    ├── ConversationsListView
    │   └── ConversationRowView
    ├── UsersListView (shows all registered users)
    │   └── UserRowView
    ├── ChatView
    │   ├── MessageListView
    │   │   └── MessageBubbleView
    │   ├── MessageInputView
    │   └── TypingIndicatorView
    └── ProfileView
```

### 5.2 Key Views

**AuthView**
- Email/password sign in and sign up
- Google Sign-In button
- Error handling and validation
- Navigate to onboarding or main app

**OnboardingView**
- Display name input
- Optional profile photo picker
- Welcome message
- "Get Started" button
- Only shown for new users

**UsersListView**
- Shows all registered users from Firebase Auth
- Search/filter functionality
- Tap user to start conversation
- Display user status (online/offline)
- Show user profile photos and display names
- Exclude current user from list

**ConversationsListView**
- List of all conversations
- Show last message preview
- Show unread badge
- Pull to refresh
- Search functionality

**ChatView**
- Message list (scrollable)
- Message input field
- Send button
- Online/typing indicators
- Read receipts
- Timestamp grouping (Today, Yesterday, etc.)

**MessageBubbleView**
- Different styles for sent/received
- Show sender name (in groups)
- Show timestamp
- Show status (checkmarks)
- Simple tap to view details (no long press menus)

---

## 6. Local-First Architecture & Optimistic Updates

### 6.1 Local-First Approach

**Core Principle:** Update local storage FIRST, then sync to Firestore in background.

**Benefits:**
- Instant UI feedback (no waiting for network)
- Works offline seamlessly
- Better perceived performance
- User sees changes immediately

### 6.2 Optimistic Update Flow

```swift
func sendMessage(text: String) async {
    // 1. Generate temporary ID
    let localId = UUID().uuidString
    
    // 2. Create message object
    let message = Message(
        id: localId,
        senderId: currentUserId,
        senderName: currentUserName,
        text: text,
        timestamp: Date(),
        status: .sending
    )
    
    // 3. UPDATE LOCAL STORAGE FIRST (instant UI)
    saveToLocalStorage(message)
    
    // 4. Update UI immediately
    DispatchQueue.main.async {
        self.messages.append(message)
    }
    
    // 5. THEN sync to Firestore in background
    do {
        let docRef = try await firestore
            .collection("conversations/\(conversationId)/messages")
            .addDocument(from: message)
        
        // 6. Update local storage with server ID
        updateLocalMessage(localId: localId, serverId: docRef.documentID, status: .sent)
        
        // 7. Update UI with confirmation
        DispatchQueue.main.async {
            if let index = self.messages.firstIndex(where: { $0.id == localId }) {
                self.messages[index].id = docRef.documentID
                self.messages[index].status = .sent
            }
        }
    } catch {
        // 8. Mark as failed locally
        updateLocalMessage(localId: localId, status: .failed)
        
        // 9. Queue for retry
        queueForRetry(message)
    }
}
```

**Key Points:**
- User sees message appear instantly (step 3-4)
- Network operations happen in background (step 5)
- Failures are handled gracefully (step 8-9)
- No blocking or waiting for server

### 6.3 Sync Strategy

**On App Launch:**
1. Load messages from local SwiftData storage
2. Display cached messages immediately (instant app launch)
3. Start Firestore listeners in background
4. Process offline message queue
5. Sync read receipts and delivery status
6. Update UI with any new messages from Firestore

**On Reconnection:**
1. Detect network connectivity change
2. Process queued messages (send failed messages)
3. Sync delivery/read status
4. Update presence to online
5. Resume real-time listeners

**During Normal Operation:**
- All writes go to local storage first
- Firestore sync happens in background
- Real-time listeners update UI with remote changes
- Conflicts resolved by timestamp (last write wins)

---

## 7. Implementation Plan (Priority Order)

### Phase 1: Foundation (Hours 0-6)
1. **Project Setup**
   - Create Xcode project with SwiftUI
   - Install Firebase SDK via SPM
   - Configure Firebase project (create app, download GoogleService-Info.plist)
   - Setup Firestore security rules
   - Enable Google Sign-In in Firebase Console

2. **Authentication**
   - Build AuthService with email/password and Google Sign-In
   - Create sign up/sign in views with Google button
   - Implement session persistence
   - Create OnboardingView for profile setup
   - Handle new user flow (check if profile exists → show onboarding)

3. **Data Models**
   - Define Firestore models
   - Setup SwiftData schema
   - Create local storage layer

4. **Users List Screen**
   - Create UserService to fetch all users
   - Build UsersListView UI
   - Add search/filter functionality
   - Display online/offline status

### Phase 2: Core Messaging (Hours 6-14)
5. **Basic Chat UI**
   - ConversationsListView
   - ChatView with message list
   - Message input field
   - Message bubbles (sent/received)
   - Simple tap interactions (no long press menus)

6. **Message Sending with Local-First Updates**
   - MessageService implementation
   - **Update local SwiftData FIRST for instant UI**
   - Then sync to Firestore in background
   - Real-time listener for incoming messages
   - Display messages in UI

7. **Message Persistence**
   - Save messages to SwiftData immediately
   - Load from local storage on launch (instant app start)
   - Handle app lifecycle
   - Queue failed messages for retry

### Phase 3: Advanced Features (Hours 14-20)
8. **Local-First Optimistic Updates**
   - Implement instant message appearance (local update first)
   - Handle server confirmation and ID replacement
   - Retry logic for failed messages
   - Status updates: sending → sent → delivered → read

9. **Read Receipts & Status**
   - Track message delivery (update local then Firestore)
   - Track message read status
   - Display checkmarks in UI
   - Update read receipts when user opens chat

10. **Group Chat**
    - Create group conversation flow (no group avatars)
    - Handle multiple participants
    - Show sender attribution in messages

11. **Presence & Typing**
    - Online/offline indicators
    - Typing indicators
    - Last seen timestamps

### Phase 4: Polish & Testing (Hours 20-24)
12. **Push Notifications (Foreground Only)**
    - Setup FCM
    - Request permissions
    - Handle foreground notifications only (app is open)
    - Show notification banner for incoming messages
    - No background notification implementation

13. **Testing & Bug Fixes**
    - Test on two physical devices
    - Test offline scenarios and local-first updates
    - Test app lifecycle
    - Test group chat with 3+ users
    - Test users list screen
    - Test Google Sign-In flow
    - Test onboarding for new users
    - Fix critical bugs

---

## 8. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && isOwner(userId);
      allow update: if isSignedIn() && isOwner(userId);
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      allow read: if isSignedIn() && 
        request.auth.uid in resource.data.participantIds;
      allow create: if isSignedIn() && 
        request.auth.uid in request.resource.data.participantIds;
      allow update: if isSignedIn() && 
        request.auth.uid in resource.data.participantIds;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if isSignedIn() && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
        allow create: if isSignedIn() && 
          request.auth.uid == request.resource.data.senderId &&
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
        allow update: if isSignedIn() && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
      }
    }
  }
}
```

---

## 9. Cloud Functions (for Notifications)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendMessageNotification = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const conversationId = context.params.conversationId;
    
    // Get conversation to find recipients
    const conversationSnap = await admin.firestore()
      .collection('conversations')
      .doc(conversationId)
      .get();
    
    const conversation = conversationSnap.data();
    const recipientIds = conversation.participantIds.filter(
      id => id !== message.senderId
    );
    
    // Get recipient FCM tokens
    const usersSnap = await admin.firestore()
      .collection('users')
      .where(admin.firestore.FieldPath.documentId(), 'in', recipientIds)
      .get();
    
    const tokens = [];
    usersSnap.forEach(doc => {
      const fcmToken = doc.data().fcmToken;
      if (fcmToken) tokens.push(fcmToken);
    });
    
    if (tokens.length === 0) return null;
    
    // Send notification
    const payload = {
      notification: {
        title: message.senderName,
        body: message.text,
        sound: 'default'
      },
      data: {
        conversationId: conversationId,
        type: 'new_message'
      }
    };
    
    return admin.messaging().sendToDevice(tokens, payload);
  });
```

---

## 10. Testing Checklist

### Critical Path Testing

**Authentication Test:**
- [ ] Sign up with email/password
- [ ] Sign in with email/password
- [ ] Sign in with Google
- [ ] New user sees onboarding screen
- [ ] Complete onboarding and create profile
- [ ] Existing user bypasses onboarding

**Users List Test:**
- [ ] Users list shows all registered users
- [ ] Current user not shown in list
- [ ] Search/filter works
- [ ] Online/offline status displays
- [ ] Tap user to start conversation

**Two Device Test:**
- [ ] User A sends message to User B
- [ ] Message appears INSTANTLY on User A (local update)
- [ ] Message syncs to Firestore
- [ ] Message appears on User B's device in real-time
- [ ] User B sends reply
- [ ] Reply appears on User A's device

**Local-First Update Test:**
- [ ] Send message - appears instantly in UI
- [ ] Check local storage - message saved immediately
- [ ] Message shows "sending" status
- [ ] Status updates to "sent" after Firestore sync
- [ ] No delay in UI update

**Offline Test:**
- [ ] Disable wifi on User A's device
- [ ] User A sends message
- [ ] Message appears in UI immediately (local update)
- [ ] Message marked as "sending" (not sent)
- [ ] Enable wifi
- [ ] Message syncs to Firestore automatically
- [ ] Status updates to "sent"
- [ ] User B receives message

**Persistence Test:**
- [ ] Send messages between users
- [ ] Force quit app on both devices
- [ ] Reopen app
- [ ] All messages still visible (loaded from local storage)
- [ ] Messages appear instantly on launch

**App Lifecycle Test:**
- [ ] Send message while app in foreground
- [ ] Background app
- [ ] Send message from other user
- [ ] Foreground app - message should appear

**Group Chat Test:**
- [ ] Create group with 3 users (no group avatar)
- [ ] Set group name only
- [ ] Each user sends message
- [ ] All messages visible to all users
- [ ] Messages show sender name/photo

**Read Receipts Test:**
- [ ] User A sends message
- [ ] User B receives (show delivered ✓✓)
- [ ] User B opens chat (show read ✓✓ blue)
- [ ] Read status updates in User A's chat

**Presence Test:**
- [ ] User A opens app → shows online
- [ ] User A closes app → shows offline
- [ ] User A opens chat → User B sees "User A is typing..."

**Push Notifications Test (Foreground Only):**
- [ ] User B has app open
- [ ] User A sends message
- [ ] User B sees notification banner at top
- [ ] Tap banner → opens conversation
- [ ] (Background notifications out of scope)

---

## 11. Deployment

### TestFlight Deployment

1. **Prepare App:**
   - Set bundle identifier
   - Configure signing & capabilities
   - Enable push notifications capability
   - Set version and build number

2. **Archive & Upload:**
   - Product → Archive
   - Upload to App Store Connect
   - Wait for processing

3. **TestFlight Setup:**
   - Create beta testing group
   - Add internal testers
   - Submit for review (if needed)
   - Share TestFlight link

### Local Testing (Fallback)

If TestFlight is blocked:
- Provide detailed setup instructions
- Include Firebase configuration steps
- Explain how to run on simulator/physical device
- Document any environment-specific setup

---

## 12. Performance Targets

- **Message Send Time:** < 200ms (optimistic UI)
- **Message Delivery:** < 100ms (when both online)
- **App Launch:** < 2 seconds to show cached messages
- **Sync Time:** < 500ms to sync after reconnection
- **UI Responsiveness:** 60fps scrolling in message list

---

## 13. Success Criteria

The MVP is considered complete when:

✅ Google Sign-In works alongside email/password auth  
✅ New users see onboarding screen to create profile  
✅ Users list screen shows all registered users  
✅ Two users can chat in real-time  
✅ Messages appear INSTANTLY in UI (local-first update)  
✅ Messages persist across app restarts (loaded from local storage)  
✅ Local-first optimistic UI works (no delay in message appearance)  
✅ Online/offline presence is visible  
✅ Message timestamps are shown  
✅ User authentication works  
✅ Group chat works with 3+ users (no group avatar needed)  
✅ Read receipts function properly (local update then Firestore)  
✅ Push notifications work in foreground (banner appears when app open)  
✅ App is deployed (TestFlight or runnable locally)  
✅ Offline mode works seamlessly (messages queue and sync on reconnect)  

---

## 14. Known Limitations & Future Work

**MVP Scope Limitations:**
- No media messages (images, videos, files)
- No message editing/deletion/copy actions
- No voice/video calls
- No end-to-end encryption
- Foreground notifications only (no background push)
- No message search
- No group avatars
- No phone number authentication
- Simple user list (no contact sync)

**Local-First Architecture Benefits:**
- ✅ Instant UI feedback (no loading spinners)
- ✅ Works perfectly offline
- ✅ Better perceived performance
- ✅ Messages never get stuck
- ✅ Seamless online/offline transitions

**Post-MVP Enhancements:**
- Image/video sharing with local caching
- Voice messages
- Message actions (edit, delete, copy, forward)
- Profile customization
- Message reactions and emojis
- Advanced search across conversations
- Block/report users
- Chat backup/export
- Background push notifications
- Contact sync
- Group management (avatars, admin controls)
- End-to-end encryption

---

## Appendix A: Key Code Snippets

### Google Sign-In Implementation

```swift
// Install: GoogleSignIn SDK via SPM
import GoogleSignIn
import FirebaseAuth

func signInWithGoogle() async throws {
    // 1. Get client ID from Firebase config
    guard let clientID = FirebaseApp.app()?.options.clientID else {
        throw AuthError.missingClientID
    }
    
    // 2. Configure Google Sign-In
    let config = GIDConfiguration(clientID: clientID)
    GIDSignIn.sharedInstance.configuration = config
    
    // 3. Get root view controller
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first?.rootViewController else {
        throw AuthError.noRootViewController
    }
    
    // 4. Sign in with Google
    let result = try await GIDSignIn.sharedInstance.signIn(
        withPresenting: rootViewController
    )
    
    // 5. Get Google credentials
    guard let idToken = result.user.idToken?.tokenString else {
        throw AuthError.missingIDToken
    }
    let accessToken = result.user.accessToken.tokenString
    
    // 6. Create Firebase credential
    let credential = GoogleAuthProvider.credential(
        withIDToken: idToken,
        accessToken: accessToken
    )
    
    // 7. Sign in to Firebase
    let authResult = try await Auth.auth().signIn(with: credential)
    
    // 8. Check if user needs onboarding
    let userExists = try await checkUserExists(uid: authResult.user.uid)
    if !userExists {
        needsOnboarding = true
    }
}
```

### Firebase Configuration

```swift
// FirebaseManager.swift
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class FirebaseManager {
    static let shared = FirebaseManager()
    
    let auth: Auth
    let firestore: Firestore
    
    private init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        
        // Enable offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        firestore.settings = settings
    }
}
```

### Real-time Message Listener

```swift
func startListening(conversationId: String) {
    listener = firestore
        .collection("conversations")
        .document(conversationId)
        .collection("messages")
        .order(by: "timestamp", descending: false)
        .addSnapshotListener { [weak self] snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            let messages = documents.compactMap { doc -> Message? in
                try? doc.data(as: Message.self)
            }
            
            DispatchQueue.main.async {
                self?.messages = messages
            }
        }
}
```

### Fetch All Users

```swift
// UserService.swift
func fetchAllUsers() async throws -> [User] {
    let snapshot = try await firestore
        .collection("users")
        .getDocuments()
    
    let users = snapshot.documents.compactMap { doc -> User? in
        try? doc.data(as: User.self)
    }
    
    // Filter out current user
    let filteredUsers = users.filter { $0.id != Auth.auth().currentUser?.uid }
    
    DispatchQueue.main.async {
        self.allUsers = filteredUsers
    }
    
    return filteredUsers
}
```

### Local-First Message Send

```swift
func sendMessage(conversationId: String, text: String) async throws {
    let messageId = UUID().uuidString
    let message = Message(
        id: messageId,
        senderId: currentUserId,
        senderName: currentUserName,
        text: text,
        timestamp: Date(),
        status: .sending
    )
    
    // 1. SAVE TO LOCAL STORAGE FIRST
    try localDB.save(message)
    
    // 2. UPDATE UI IMMEDIATELY
    await MainActor.run {
        messages.append(message)
    }
    
    // 3. SYNC TO FIRESTORE IN BACKGROUND
    let docRef = try await firestore
        .collection("conversations")
        .document(conversationId)
        .collection("messages")
        .addDocument(from: message)
    
    // 4. UPDATE WITH SERVER ID
    message.id = docRef.documentID
    message.status = .sent
    try localDB.update(message)
    
    await MainActor.run {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index] = message
        }
    }
}
```

---

**Document Version:** 2.0  
**Last Updated:** October 20, 2025  
**Status:** Ready for Implementation  
**Key Updates:** Google Sign-In, Onboarding Flow, Users List Screen, Local-First Architecture, Foreground Notifications Only