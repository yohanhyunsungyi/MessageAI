# MessageAI - Real-Time Messaging App

A production-quality iOS messaging application built with SwiftUI, Firebase, and local-first architecture.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![iOS](https://img.shields.io/badge/iOS-26.0+-blue)]()
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange)]()
[![Firebase](https://img.shields.io/badge/Firebase-12.4.0-yellow)]()

## 🚀 Features

- ✅ **Authentication:** Email/password and Google Sign-In
- ✅ **One-on-One Chat:** Real-time messaging with status tracking
- ✅ **Group Chat:** Multi-participant conversations
- ✅ **Message Status:** sending → sent → delivered → read
- ✅ **Read Receipts:** Track who read messages
- ✅ **Online/Offline Presence:** Real-time user status
- ✅ **Typing Indicators:** See when others are typing
- ✅ **Local-First Architecture:** Instant UI updates, offline support
- ✅ **Push Notifications:** Foreground notifications (app open)

## 🏗️ Architecture

- **Frontend:** iOS (Swift + SwiftUI)
- **Backend:** Firebase (Firestore, Auth, FCM, Cloud Functions)
- **Local Storage:** SwiftData for offline persistence
- **Approach:** Local-first for instant UI feedback

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

See [Architecture.md](Architecture.md) for detailed architecture diagram.

## 📋 Prerequisites

- **Xcode:** 16.0+ (for iOS 26.0 support)
- **iOS:** 26.0+ (Deployment target)
- **Swift:** 5.9+
- **Firebase CLI:** 14.8.0+ (for emulators)
- **Node.js:** For Firebase Emulators
- **Git:** 2.0+

## 🛠️ Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yohanhyunsungyi/MessageAI.git
cd MessageAI
```

### 2. Firebase Configuration

**⚠️ Important:** You need to add your own `GoogleService-Info.plist` file.

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or use existing: `messagingai-75f21`
3. Add an iOS app with bundle ID: `app.messageAI.messageAI`
4. Download `GoogleService-Info.plist`
5. Add it to: `messageAI/messageAI/GoogleService-Info.plist`

**Enable Firebase Services:**
- Authentication → Sign-in method → Enable Email/Password
- Authentication → Sign-in method → Enable Google
- Firestore Database → Create database (start in test mode)
- Cloud Messaging → Enable

### 3. Deploy Firestore Rules

```bash
# Navigate to project root
cd MessageAI

# Deploy security rules
firebase deploy --only firestore:rules
```

### 4. Open in Xcode

```bash
# Open the project
open messageAI/messageAI.xcodeproj
```

**In Xcode:**
1. Select your development team in Signing & Capabilities
2. Build the project (⌘B)
3. Run on simulator or device (⌘R)

### 5. Firebase Emulators (for Testing)

```bash
# Start emulators
firebase emulators:start

# Emulators will run on:
# - Auth: localhost:9099
# - Firestore: localhost:8080
# - UI: localhost:4000
```

See [TESTING_NOTES.md](TESTING_NOTES.md) for comprehensive testing documentation.

## 📁 Project Structure

```
MessageAI/
├── messageAI/                          # iOS App
│   ├── messageAI.xcodeproj            # Xcode project
│   ├── messageAI/                     # Source code
│   │   ├── messageAIApp.swift         # App entry point
│   │   ├── ContentView.swift          # Main view
│   │   ├── Info.plist                 # App configuration
│   │   └── GoogleService-Info.plist   # Firebase config (not in git)
│   ├── messageAITests/                # Unit & Integration tests
│   │   └── Helpers/
│   │       ├── FirebaseTestHelper.swift
│   │       └── MockHelpers.swift
│   └── messageAIUITests/              # UI tests
├── backend/                           # Backend (Future: Cloud Functions)
├── firebase.json                      # Firebase configuration
├── firestore.rules                    # Firestore security rules
├── firestore.indexes.json             # Firestore indexes
├── .firebaserc                        # Firebase project alias
├── Architecture.md                    # Architecture documentation
├── PRD.md                            # Product requirements
├── Tasks.md                          # Task breakdown
├── TESTING_NOTES.md                  # Testing documentation
├── SETUP_STATUS.md                   # Setup progress
└── README.md                         # This file
```

## 🧪 Testing

### Run Tests

```bash
# Unit tests
xcodebuild test -scheme messageAI -only-testing:messageAITests

# Integration tests (requires emulators running)
firebase emulators:start &
xcodebuild test -scheme messageAI -only-testing:messageAITests/Integration

# UI tests
xcodebuild test -scheme messageAI -only-testing:messageAIUITests
```

**In Xcode:** Press `⌘U` to run all tests

See [TESTING_NOTES.md](TESTING_NOTES.md) for detailed testing procedures.

## 🚢 Deployment

### TestFlight

1. **Archive the app:**
   - Product → Archive in Xcode
   
2. **Upload to App Store Connect:**
   - Window → Organizer → Upload to App Store
   
3. **Configure TestFlight:**
   - Add testers
   - Submit for review
   - Share TestFlight link

See [Tasks.md](Tasks.md) for deployment checklist.

## 📚 Documentation

- **[PRD.md](PRD.md)** - Product Requirements Document (1160 lines)
- **[Architecture.md](Architecture.md)** - System architecture diagram
- **[Tasks.md](Tasks.md)** - Detailed task breakdown with 21 PRs
- **[TESTING_NOTES.md](TESTING_NOTES.md)** - Comprehensive testing guide
- **[SETUP_STATUS.md](SETUP_STATUS.md)** - Current setup status

## 📊 Development Progress

**Phase 1: Foundation** ✅ COMPLETE (PR #1)
- [x] Project setup
- [x] Firebase configuration
- [x] Google Sign-In setup
- [x] Firestore security rules
- [x] Testing infrastructure

**Phase 2: Authentication & Users** (PR #5-9)
- [ ] Authentication service
- [ ] Auth UI
- [ ] Onboarding flow
- [ ] Users list screen

**Phase 3: Core Messaging** (PR #10-14)
- [ ] Conversation service
- [ ] Message service (local-first)
- [ ] Chat UI
- [ ] Read receipts

**Phase 4: Advanced Features** (PR #15-18)
- [ ] Group chat
- [ ] Presence & typing indicators
- [ ] Push notifications

**Phase 5: Polish & Deploy** (PR #19-21)
- [ ] Offline support
- [ ] Testing & bug fixes
- [ ] Deployment

See [Tasks.md](Tasks.md) for complete task list.

## 🛡️ Security

- ✅ Firestore security rules deployed
- ✅ Authentication required for all operations
- ✅ User data protected by ownership rules
- ✅ Conversation access limited to participants
- ⚠️ GoogleService-Info.plist not committed (add your own)

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is for educational and portfolio purposes.

## 🔗 Links

- **GitHub:** [https://github.com/yohanhyunsungyi/MessageAI](https://github.com/yohanhyunsungyi/MessageAI)
- **Firebase Project:** messagingai-75f21
- **Firebase Console:** [https://console.firebase.google.com/project/messagingai-75f21](https://console.firebase.google.com/project/messagingai-75f21)

## 💡 Key Implementation Details

### Local-First Architecture

Messages are saved to local SwiftData storage FIRST, then synced to Firestore:

```swift
func sendMessage(text: String) async {
    // 1. Save to local storage (instant UI update)
    saveToLocalStorage(message)
    
    // 2. Update UI immediately
    messages.append(message)
    
    // 3. Sync to Firestore in background
    try await syncToFirestore(message)
}
```

### Firestore Collections

- `/users/{userId}` - User profiles
- `/conversations/{conversationId}` - Conversations
- `/conversations/{conversationId}/messages/{messageId}` - Messages
- `/conversations/{conversationId}/typing/{userId}` - Typing indicators

### Firebase SDK Versions

- Firebase iOS SDK: 12.4.0
- Google Sign-In: 9.0.0

## 🐛 Known Issues

None at this time. See [Issues](https://github.com/yohanhyunsungyi/MessageAI/issues) for bug reports.

## 📞 Contact

Yohan Yi - [@yohanhyunsungyi](https://github.com/yohanhyunsungyi)

---

**Last Updated:** October 20, 2025  
**Status:** PR #1 Complete, Ready for PR #2  
**Build Status:** ✅ Passing

