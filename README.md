# MessageAI - AI-Powered Real-Time Messaging App

A production-quality iOS messaging application built with SwiftUI, Firebase, and AI-powered features for remote teams.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![iOS](https://img.shields.io/badge/iOS-26.0+-blue)]()
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange)]()
[![Firebase](https://img.shields.io/badge/Firebase-12.4.0-yellow)]()
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-green)]()
[![Pinecone](https://img.shields.io/badge/Pinecone-Vector_DB-blueviolet)]()

## 🚀 Features

### Core Messaging (MVP Complete ✅)
- ✅ **Authentication:** Email/password and Google Sign-In
- ✅ **One-on-One Chat:** Real-time messaging with status tracking
- ✅ **Group Chat:** Multi-participant conversations (3+ users)
- ✅ **Message Status:** sending → sent → delivered → read
- ✅ **Read Receipts:** Track who read messages
- ✅ **Online/Offline Presence:** Real-time user status
- ✅ **Typing Indicators:** See when others are typing
- ✅ **Local-First Architecture:** Instant UI updates, offline support
- ✅ **Push Notifications:** FCM push notifications

### AI Features (Powered by OpenAI GPT-4 + Pinecone)
- ✅ **Thread Summarization:** Get concise summaries of long conversations with key points and action items
- ✅ **Smart Search (RAG):** Semantic search across all messages using vector embeddings
- 🚧 **Action Item Extraction:** Automatically identify and track action items from conversations
- 🚧 **Priority Detection:** AI classifies urgent messages in real-time
- 🚧 **Decision Tracking:** Track important decisions made in conversations
- 🚧 **Proactive Assistant:** Multi-step AI agent that detects scheduling needs and suggests meeting times

## 🏗️ Architecture

- **Frontend:** iOS (Swift + SwiftUI)
- **Backend:** Firebase (Firestore, Auth, FCM, Cloud Functions)
- **Local Storage:** SwiftData for offline persistence
- **AI Services:** OpenAI GPT-4 Turbo, Pinecone Vector DB
- **Approach:** Local-first for instant UI feedback + AI-powered intelligence

```
┌─────────────────────────────────┐
│   iOS App (SwiftUI)             │
├─────────────────────────────────┤
│ • UI Layer (Chat, AI Assistant) │
│ • ViewModels                    │
│ • Local Storage (SwiftData)     │
│ • Firebase SDK                  │
│ • AIService (Cloud Functions)   │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│   Firebase Cloud Platform       │
├─────────────────────────────────┤
│ • Firestore (Real-time DB)      │
│ • Authentication (OAuth)        │
│ • Cloud Messaging (FCM)         │
│ • Cloud Functions (Node.js)     │
│   - Summarization               │
│   - Smart Search (RAG)          │
│   - Action Items                │
│   - Priority Detection          │
│   - Proactive Assistant         │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│   AI Services                   │
├─────────────────────────────────┤
│ • OpenAI GPT-4 Turbo            │
│ • Pinecone Vector Database      │
│ • RAG Pipeline (Embeddings)     │
└─────────────────────────────────┘
```

See [Architecture.md](Architecture.md) for detailed architecture diagram with full data flow.

## 📋 Prerequisites

- **Xcode:** 16.0+ (for iOS 26.0 support)
- **iOS:** 26.0+ (Deployment target)
- **Swift:** 5.9+
- **Firebase CLI:** 14.8.0+ (for emulators and deployment)
- **Node.js:** 18+ (for Firebase Cloud Functions)
- **Git:** 2.0+
- **OpenAI API Key:** For AI features
- **Pinecone API Key:** For vector search

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

### 5. Setup AI Services (Cloud Functions)

```bash
# Navigate to functions directory
cd backend/functions

# Install dependencies
npm install

# Setup environment variables
cp .env.example .env.local

# Add your API keys to .env.local:
# OPENAI_API_KEY=sk-...
# PINECONE_API_KEY=...
# PINECONE_INDEX_NAME=messageai-messages

# Deploy Cloud Functions
npm run deploy

# Set OpenAI key in Firebase config (for production)
firebase functions:config:set openai.api_key="YOUR_OPENAI_API_KEY"
```

See `backend/functions/QUICK_START.md` for detailed AI setup instructions.

### 6. Firebase Emulators (for Testing)

```bash
# Start emulators
firebase emulators:start

# Emulators will run on:
# - Auth: localhost:9099
# - Firestore: localhost:8080
# - Functions: localhost:5001
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
│   │   ├── Services/                  # Business logic layer
│   │   │   ├── FirebaseManager.swift
│   │   │   ├── MessageService.swift
│   │   │   ├── ConversationService.swift
│   │   │   ├── AIService.swift        # AI features wrapper
│   │   │   ├── AuthService.swift
│   │   │   └── LocalStorageService.swift
│   │   ├── ViewModels/                # State management
│   │   ├── Views/                     # SwiftUI views
│   │   │   ├── Chat/
│   │   │   │   ├── ChatView.swift
│   │   │   │   └── SummaryView.swift  # AI summaries
│   │   │   ├── Conversations/
│   │   │   ├── Users/
│   │   │   └── Auth/
│   │   ├── Models/                    # Firebase models
│   │   │   ├── Message.swift
│   │   │   ├── Conversation.swift
│   │   │   ├── User.swift
│   │   │   └── Summary.swift          # AI summary model
│   │   ├── LocalModels/               # SwiftData models
│   │   └── GoogleService-Info.plist   # Firebase config (not in git)
│   ├── messageAITests/                # Unit & Integration tests
│   └── messageAIUITests/              # UI tests
├── backend/                           # Firebase Cloud Functions
│   └── functions/
│       ├── src/
│       │   ├── ai/                    # AI infrastructure
│       │   │   ├── openai.js          # OpenAI client
│       │   │   ├── pinecone.js        # Pinecone vector DB
│       │   │   ├── embeddings.js      # Embedding generation
│       │   │   ├── prompts.js         # AI prompts
│       │   │   └── tools.js           # Function calling schemas
│       │   ├── features/              # AI features
│       │   │   ├── summarization.js   # Thread summarization
│       │   │   ├── vectorSearch.js    # Smart search (RAG)
│       │   │   ├── actionItems.js     # Action extraction
│       │   │   └── priority.js        # Priority detection
│       │   ├── triggers/              # Firestore triggers
│       │   │   └── onMessageCreate.js # Message indexing
│       │   ├── middleware/            # Rate limiting, auth
│       │   └── __tests__/             # Cloud Function tests
│       ├── index.js                   # Function exports
│       ├── package.json
│       └── .env.example               # Environment template
├── firebase.json                      # Firebase configuration
├── firestore.rules                    # Firestore security rules
├── firestore.indexes.json             # Firestore indexes
├── Architecture.md                    # Architecture documentation
├── PRD.md                            # Product requirements (AI features)
├── Tasks_final.md                    # AI features task breakdown
├── Tasks_MVP.md                      # MVP task list
├── TESTING_NOTES.md                  # Testing documentation
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

- **[PRD.md](PRD.md)** - Product Requirements Document (AI features, 976 lines)
- **[Architecture.md](Architecture.md)** - System architecture diagram (Mermaid graph)
- **[Tasks_final.md](Tasks_final.md)** - AI features task breakdown (15 PRs)
- **[Tasks_MVP.md](Tasks_MVP.md)** - MVP task breakdown (21 PRs, complete)
- **[TESTING_NOTES.md](TESTING_NOTES.md)** - Comprehensive testing guide
- **[backend/functions/QUICK_START.md](backend/functions/QUICK_START.md)** - 5-minute AI setup guide
- **[CLAUDE.md](CLAUDE.md)** - Development guidelines for Claude Code

## 📊 Development Progress

### MVP Features (Complete ✅)
**All 21 PRs from Tasks_MVP.md completed**
- ✅ Foundation (PR #1-4): Project setup, Firebase, data models, local storage
- ✅ Authentication & Users (PR #5-9): Auth service, UI, onboarding, users list
- ✅ Core Messaging (PR #10-14): Conversations, messages, chat UI, read receipts
- ✅ Advanced Features (PR #15-18): Group chat, presence, typing indicators, push notifications
- ✅ Polish & Deploy (PR #19-21): Offline support, testing, deployment

### AI Features (In Progress 🚧)
**Phase 1: AI Infrastructure (PRs 22-23) - Day 1**
- ✅ PR #22: AI Infrastructure Setup (OpenAI, Pinecone, rate limiting)
- 🚧 PR #23: RAG Pipeline Implementation (currently working on)

**Phase 2: Core AI Features (PRs 24-28) - Days 2-3**
- ✅ PR #24: Thread Summarization (GPT-4 summaries with key points)
- ⏳ PR #25: Action Item Extraction
- ⏳ PR #26: Smart Search (semantic search with RAG)
- ⏳ PR #27: Priority Message Detection
- ⏳ PR #28: Decision Tracking

**Phase 3: Advanced AI (PRs 29-32) - Day 4**
- ⏳ PR #29: AI Chat Assistant Interface
- ⏳ PR #30-32: Proactive Assistant (multi-step scheduling agent)

**Phase 4: Polish & Deploy (PRs 33-36) - Day 5**
- ⏳ PR #33: AI Usage Analytics
- ⏳ PR #34: Error Handling & Graceful Degradation
- ⏳ PR #35: AI Features Polish & Optimization
- ⏳ PR #36: Documentation, Demo & Final Testing

See [Tasks_final.md](Tasks_final.md) for complete AI features task list.

**Current Status:** Working on PR #23 (RAG Pipeline)
**Target:** A grade (90-100 points)

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

**Core Collections:**
- `/users/{userId}` - User profiles with presence and FCM tokens
- `/conversations/{conversationId}` - Conversations (1-on-1 and group)
- `/conversations/{conversationId}/messages/{messageId}` - Messages with status tracking
- `/conversations/{conversationId}/typing/{userId}` - Typing indicators (auto-cleanup)

**AI Collections:**
- `/summaries/{summaryId}` - Conversation summaries generated by AI
- `/actionItems/{itemId}` - Action items extracted from conversations
- `/decisions/{decisionId}` - Important decisions tracked by AI
- `/proactiveSuggestions/{suggestionId}` - Meeting suggestions from proactive assistant

**Vector Database (Pinecone):**
- Index: `messageai-messages` (1536 dimensions)
- Stores message embeddings for semantic search

### Technology Versions

**iOS:**
- Firebase iOS SDK: 12.4.0
- Google Sign-In: 9.0.0
- Swift: 5.9+
- SwiftUI (iOS 26.0+)

**Backend (Cloud Functions):**
- Node.js: 18
- Firebase Admin SDK: Latest
- OpenAI: 6.7.0
- Pinecone: 6.1.2
- Firebase Functions: v5 (2nd gen)

## 🐛 Known Issues

**AI Features:**
- RAG pipeline batch indexing script not yet implemented (for existing messages)
- Action item extraction UI not yet built
- Priority detection trigger needs optimization for <500ms latency

See [Issues](https://github.com/yohanhyunsungyi/MessageAI/issues) for bug reports.

## 📞 Contact

Yohan Yi - [@yohanhyunsungyi](https://github.com/yohanhyunsungyi)

## 🎯 Target Persona

**Remote Team Professional** - Software engineers, designers, and product managers working in distributed teams across time zones who need to:
- Stay on top of multiple conversation threads
- Never miss critical information
- Reduce context-switching overhead
- Coordinate meetings across time zones
- Track decisions and action items automatically

## 🧠 AI Features Deep Dive

### 1. Thread Summarization (✅ Live)
- **What:** Get concise summaries of long conversations
- **How:** GPT-4 analyzes messages and extracts key points, decisions, blockers
- **Performance:** <2 seconds for 100-message conversations
- **UI:** Sparkles button in chat view → summary sheet

### 2. Smart Search with RAG (✅ Infrastructure Ready)
- **What:** Semantic search across all your messages
- **How:** Vector embeddings (Pinecone) + GPT-4 re-ranking
- **Performance:** <1 second for search results
- **UI:** Search bar in conversations list

### 3. Action Item Extraction (🚧 In Development)
- **What:** Automatically identify tasks and to-dos from conversations
- **How:** GPT-4 function calling to extract structured action items
- **Performance:** <2 seconds
- **UI:** Dedicated action items tab with priority indicators

### 4. Priority Detection (🚧 Planned)
- **What:** Real-time classification of urgent messages
- **How:** Fast GPT-4 call (<500ms) analyzing urgency indicators
- **Performance:** <500ms (must be real-time)
- **UI:** Priority badges (🔴 critical, 🟡 high) on messages

### 5. Proactive Assistant (🚧 Planned)
- **What:** Multi-step AI agent that detects scheduling needs and suggests meeting times
- **How:** Monitors conversations → identifies participants → checks timezones → generates suggestions
- **Performance:** <15 seconds end-to-end
- **UI:** Inline suggestion cards with time options

---

**Last Updated:** October 24, 2025
**Current Branch:** `feature/rag-pipeline` (PR #23)
**Status:** MVP Complete ✅ | AI Features: 2/15 PRs Complete
**Build Status:** ✅ Passing

