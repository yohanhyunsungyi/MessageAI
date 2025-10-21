# MessageAI MVP - Task List & PR Checklist

**Timeline:** 24 Hours  
**Total PRs:** 15  
**Tracking:** Check off each subtask as you complete it

---

## File Structure Overview

```
MessageAI/
├── MessageAI.xcodeproj
├── MessageAI/
│   ├── MessageAIApp.swift
│   ├── GoogleService-Info.plist
│   ├── Info.plist
│   │
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Conversation.swift
│   │   ├── Message.swift
│   │   ├── MessageStatus.swift
│   │   └── ConversationType.swift
│   │
│   ├── LocalModels/
│   │   ├── LocalMessage.swift
│   │   └── LocalConversation.swift
│   │
│   ├── Services/
│   │   ├── FirebaseManager.swift
│   │   ├── AuthService.swift
│   │   ├── UserService.swift
│   │   ├── ConversationService.swift
│   │   ├── MessageService.swift
│   │   ├── PresenceService.swift
│   │   ├── NotificationService.swift
│   │   └── LocalStorageService.swift
│   │
│   ├── Views/
│   │   ├── Auth/
│   │   │   ├── AuthView.swift
│   │   │   ├── SignInView.swift
│   │   │   └── SignUpView.swift
│   │   ├── Onboarding/
│   │   │   └── OnboardingView.swift
│   │   ├── Main/
│   │   │   └── MainTabView.swift
│   │   ├── Users/
│   │   │   ├── UsersListView.swift
│   │   │   └── UserRowView.swift
│   │   ├── Conversations/
│   │   │   ├── ConversationsListView.swift
│   │   │   └── ConversationRowView.swift
│   │   ├── Chat/
│   │   │   ├── ChatView.swift
│   │   │   ├── MessageListView.swift
│   │   │   ├── MessageBubbleView.swift
│   │   │   ├── MessageInputView.swift
│   │   │   └── TypingIndicatorView.swift
│   │   └── Profile/
│   │       └── ProfileView.swift
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── UsersViewModel.swift
│   │   ├── ConversationsViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   └── ProfileViewModel.swift
│   │
│   └── Utils/
│       ├── Constants.swift
│       ├── Extensions.swift
│       └── DateFormatter+Extensions.swift
│
└── Podfile / Package.swift (for dependencies)
```

---

## PR #1: Project Setup & Firebase Configuration
**Priority:** Critical  
**Estimated Time:** 1-1.5 hours  
**Branch:** `feature/project-setup`

### Subtasks:
- [x] Create new Xcode project with SwiftUI
  - **Files Created:** `messageAI.xcodeproj`, `messageAIApp.swift`, `ContentView.swift`
  
- [x] Enable unit testing and UI testing targets
  - **Targets Created:** `messageAITests`, `messageAIUITests`
  - Configure test targets in Xcode
  
- [x] Configure project settings (bundle ID, deployment target iOS 17+)
  - **Bundle ID:** `app.messageAI.messageAI`
  - **Deployment Target:** iOS 26.0
  
- [x] Add Firebase SDK via Swift Package Manager
  - **Packages Added:** 
    - `FirebaseAuth` v12.4.0
    - `FirebaseFirestore` v12.4.0
    - `FirebaseMessaging` v12.4.0
    - `FirebaseCore` v12.4.0
    - `FirebaseFunctions` v12.4.0
    - `FirebaseDatabase` v12.4.0
  
- [x] Create Firebase project in console (https://console.firebase.google.com)
  - **Project ID:** `messagingai-75f21`
  - Created iOS app
  - Downloaded `GoogleService-Info.plist`
  
- [x] Add GoogleService-Info.plist to project
  - **Files Created:** `messageAI/GoogleService-Info.plist`
  
- [x] Enable Google Sign-In in Firebase Console
  - Authentication → Sign-in method → Google → Enable ✅
  
- [x] Add Google Sign-In SDK via SPM
  - **Package Added:** `GoogleSignInSwift` v9.0.0 (https://github.com/google/GoogleSignIn-iOS)
  
- [x] Configure URL schemes for Google Sign-In
  - **Files Created:** `messageAI/Info.plist`
  - Added `CFBundleURLTypes` with reversed client ID: `com.googleusercontent.apps.66323540487-kntg9rmvh4blv8613dh806cik7nac2gc`
  - Configured project to use custom Info.plist
  
- [x] Initialize Firebase in App file
  - **Files Edited:** `messageAIApp.swift`
  - Import FirebaseCore ✅
  - Add `FirebaseApp.configure()` ✅
  - Build verified successfully ✅
  
- [x] Setup Firestore security rules in Firebase Console
  - **Files Created:** `firestore.rules`, `firebase.json`, `firestore.indexes.json`, `.firebaserc`
  - Deployed to Firebase project: `messagingai-75f21` ✅
  - Rules include: users, conversations, messages, typing indicators

### Testing Setup:
  
- [x] Firebase Emulator Suite configuration
  - Firebase CLI v14.8.0 installed ✅
  - Emulators configured in `firebase.json` ✅
  - Auth Emulator: `localhost:9099`
  - Firestore Emulator: `localhost:8080`
  - Emulator UI: `localhost:4000`
  
- [x] Create test helper files
  - **Files Created:** `messageAITests/Helpers/FirebaseTestHelper.swift` ✅
  - Emulator connection configuration
  - Test user creation/deletion
  - Firestore data cleanup utilities
  - Base test case class: `FirebaseIntegrationTestCase`
  - **Files Created:** `messageAITests/Helpers/MockHelpers.swift` ✅
  - Mock data generators (User, Message, Conversation, Group)
  - Test credential constants
  - XCTest extensions for async testing
  
- [x] Create TESTING_NOTES.md
  - **Files Created:** `TESTING_NOTES.md` ✅
  - Comprehensive testing documentation (500+ lines)
  - Firebase Emulator setup and usage instructions
  - Running unit, integration, and UI tests
  - Manual testing procedures and checklists
  - Two-device messaging test scenarios
  - Offline testing procedures
  - Test helper API documentation
  - Troubleshooting common issues
  - Test coverage goals and best practices

### Files Summary:
- **Created:** 
  - `messageAI.xcodeproj` ✅
  - `messageAIApp.swift` ✅
  - `GoogleService-Info.plist` ✅
  - `Info.plist` ✅
  - `firebase.json` (with emulator config) ✅
  - `.firebaserc` ✅
  - `firestore.rules` ✅
  - `firestore.indexes.json` ✅
  - `messageAITests/Helpers/FirebaseTestHelper.swift` ✅
  - `messageAITests/Helpers/MockHelpers.swift` ✅
  - `TESTING_NOTES.md` ✅
- **Edited:** 
  - `messageAIApp.swift` (Firebase initialization) ✅
  - `project.pbxproj` (SDK dependencies, Info.plist config) ✅
- **Targets:** `messageAI`, `messageAITests`, `messageAIUITests` ✅
- **Status:** ✅ PR #1 COMPLETE - All tasks finished including testing setup

---

## PR #2: Firebase Manager & Core Services Setup
**Priority:** Critical  
**Estimated Time:** 1 hour  
**Branch:** `feature/firebase-manager`

### Subtasks:
- [x] Create FirebaseManager singleton
  - **Files Created:** `Services/FirebaseManager.swift` ✅
  - Initialize Auth, Firestore ✅
  - Enable offline persistence ✅
  - Unlimited cache size for better offline support ✅
  
- [x] Create Constants file
  - **Files Created:** `Utils/Constants.swift` ✅
  - Firebase collection names ✅
  - Message status constants ✅
  - Conversation type constants ✅
  - UserDefaults keys ✅
  - Notification names ✅
  - Timeouts and limits ✅
  
- [x] Create Extensions file
  - **Files Created:** `Utils/Extensions.swift` ✅
  - Date extensions (isToday, isYesterday, relativeTimeString, etc.) ✅
  - String extensions (isValidEmail, trimmed, isBlank, truncated) ✅
  - Color extensions (message bubble colors, status colors) ✅
  - View extensions (hideKeyboard, conditional modifiers) ✅
  
- [x] Create DateFormatter extensions
  - **Files Created:** `Utils/DateFormatter+Extensions.swift` ✅
  - Static formatters (messageTime, messageDate, fullTimestamp, lastSeen) ✅
  - Conversation timestamp formatting ✅
  - Chat section headers ✅
  - Last seen string formatting ✅

### Testing:
- [x] Create FirebaseManager unit tests
  - **Files Created:** `messageAITests/Services/FirebaseManagerTests.swift` ✅
  - Test singleton initialization ✅
  - Test Auth and Firestore initialization ✅
  - Test offline persistence enabled ✅
  - Test cache size unlimited ✅
  - Test currentUserId and isAuthenticated properties ✅
  - Performance tests ✅
  
- [x] Create Extensions unit tests
  - **Files Created:** `messageAITests/Utils/ExtensionsTests.swift` ✅
  - Test Date extensions (isToday, isYesterday, isInCurrentWeek) ✅
  - Test String extensions (isValidEmail, trimmed, isBlank, truncated) ✅
  - Test DateFormatter extensions (conversationTimestamp, chatSectionHeader, lastSeenString) ✅
  - Test relative time formatting ✅
  - Performance tests ✅

### Files Summary:
- **Created:** `Services/FirebaseManager.swift`, `Utils/Constants.swift`, `Utils/Extensions.swift`, `Utils/DateFormatter+Extensions.swift` ✅
- **Tests Created:** `messageAITests/Services/FirebaseManagerTests.swift`, `messageAITests/Utils/ExtensionsTests.swift` ✅
- **Status:** ✅ PR #2 COMPLETE - All linter errors fixed, production-ready code

---

## PR #3: Data Models
**Priority:** Critical  
**Estimated Time:** 1 hour  
**Branch:** `feature/data-models`

### Subtasks:
- [x] Create User model
  - **Files Created:** `Models/User.swift` ✅
  - All properties from PRD ✅
  - Codable conformance ✅
  
- [x] Create Message model
  - **Files Created:** `Models/Message.swift` ✅
  - All properties from PRD ✅
  - Codable conformance ✅
  
- [x] Create MessageStatus enum
  - **Files Created:** `Models/MessageStatus.swift` ✅
  - Cases: sending, sent, delivered, read, failed ✅
  
- [x] Create Conversation model
  - **Files Created:** `Models/Conversation.swift` ✅
  - All properties from PRD ✅
  - Codable conformance ✅
  
- [x] Create ConversationType enum
  - **Files Created:** `Models/ConversationType.swift` ✅
  - Cases: oneOnOne, group ✅
  
- [x] Create LocalMessage SwiftData model
  - **Files Created:** `LocalModels/LocalMessage.swift` ✅
  - @Model macro ✅
  - All properties for local storage ✅
  
- [x] Create LocalConversation SwiftData model
  - **Files Created:** `LocalModels/LocalConversation.swift` ✅
  - @Model macro ✅
  - All properties for local storage ✅

### Testing:
- [x] Create model unit tests
  - **Files Created:** `messageAITests/Models/ModelTests.swift` ✅
  - Test User model encoding/decoding ✅
  - Test Message model encoding/decoding ✅
  - Test Conversation model encoding/decoding ✅
  - Test MessageStatus enum cases ✅
  - Test ConversationType enum cases ✅
  - Test LocalMessage model creation and updates ✅
  - Test LocalConversation model creation and updates ✅
  - Test default values and validation ✅
  - 17 test cases total ✅

### Files Summary:
- **Created:** `Models/User.swift`, `Models/Message.swift`, `Models/MessageStatus.swift`, `Models/Conversation.swift`, `Models/ConversationType.swift`, `LocalModels/LocalMessage.swift`, `LocalModels/LocalConversation.swift` ✅
- **Tests Created:** `messageAITests/Models/ModelTests.swift` ✅
- **Status:** ✅ PR #3 COMPLETE - All models created with unit tests, linter errors fixed, production-ready code

---

## PR #4: Local Storage Service
**Priority:** Critical  
**Estimated Time:** 1.5 hours  
**Branch:** `feature/local-storage`

### Subtasks:
- [x] Create LocalStorageService
  - **Files Created:** `Services/LocalStorageService.swift` ✅
  - Setup SwiftData ModelContainer ✅
  - Setup ModelContext ✅
  - @MainActor for thread safety ✅
  
- [x] Implement save message to local storage
  - **Files Edited:** `Services/LocalStorageService.swift` ✅
  - `saveMessage(_ message: Message, conversationId: String)` ✅
  
- [x] Implement fetch messages from local storage
  - **Files Edited:** `Services/LocalStorageService.swift` ✅
  - `fetchMessages(conversationId: String) -> [LocalMessage]` ✅
  - `fetchAllMessages() -> [LocalMessage]` ✅
  - `fetchPendingMessages() -> [LocalMessage]` ✅
  
- [x] Implement update message status
  - **Files Edited:** `Services/LocalStorageService.swift` ✅
  - `updateMessageStatus(messageId: String, status: MessageStatus)` ✅
  - `updateMessageId(localId: String, serverId: String, status: MessageStatus)` ✅
  
- [x] Implement save conversation to local storage
  - **Files Edited:** `Services/LocalStorageService.swift` ✅
  - `saveConversation(_ conversation: Conversation)` ✅
  
- [x] Implement fetch conversations from local storage
  - **Files Edited:** `Services/LocalStorageService.swift` ✅
  - `fetchConversations() -> [LocalConversation]` ✅
  - `fetchConversation(id: String) -> LocalConversation?` ✅
  - `updateConversationLastMessage()` ✅
  
- [x] Implement delete operations
  - **Files Edited:** `Services/LocalStorageService.swift` ✅
  - `deleteMessage(messageId: String)` ✅
  - `deleteMessages(conversationId: String)` ✅
  - `deleteConversation(conversationId: String)` ✅
  - `clearAllData()` ✅
  
- [x] Configure SwiftData in App file
  - **Files Edited:** `messageAIApp.swift` ✅
  - Updated Schema to use LocalMessage and LocalConversation ✅
  - Removed unused Item model from schema ✅
  - Added `.modelContainer` modifier ✅

### Testing:
- [x] Create LocalStorageService unit tests
  - **Files Created:** `messageAITests/Services/LocalStorageServiceTests.swift` ✅
  - Test save message to local storage ✅
  - Test fetch messages from local storage ✅
  - Test fetch messages by conversation ✅
  - Test fetch all messages ✅
  - Test fetch pending messages ✅
  - Test update message status locally ✅
  - Test update message ID after server sync ✅
  - Test delete message ✅
  - Test delete messages for conversation ✅
  - Test save conversation to local storage ✅
  - Test fetch conversations from local storage ✅
  - Test fetch conversation by ID ✅
  - Test update conversation last message ✅
  - Test delete conversation ✅
  - Test clear all data ✅
  - Test error handling (non-existent items) ✅
  - Use in-memory ModelContainer for tests ✅
  - Build successful ✅

### Files Summary:
- **Created:** `Services/LocalStorageService.swift` ✅
- **Edited:** `messageAIApp.swift` ✅
- **Tests Created:** `messageAITests/Services/LocalStorageServiceTests.swift` ✅
- **Status:** ✅ PR #4 COMPLETE - All linter errors fixed, tests compile successfully

---

## PR #5: Authentication Service & Google Sign-In
**Priority:** Critical  
**Estimated Time:** 2 hours  
**Branch:** `feature/authentication`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Create AuthService
  - **Files Created:** `Services/AuthService.swift` ✅
  - ObservableObject protocol ✅
  - @Published properties for currentUser, isAuthenticated, needsOnboarding ✅
  
- [x] Implement email sign up
  - **Files Edited:** `Services/AuthService.swift` ✅
  - `signUp(email: String, password: String) async throws` ✅
  
- [x] Implement email sign in
  - **Files Edited:** `Services/AuthService.swift` ✅
  - `signIn(email: String, password: String) async throws` ✅
  
- [x] Implement Google Sign-In
  - **Files Edited:** `Services/AuthService.swift` ✅
  - `signInWithGoogle() async throws` ✅
  - Full Google OAuth flow from PRD ✅
  
- [x] Implement check user exists
  - **Files Edited:** `Services/AuthService.swift` ✅
  - `checkUserExists(uid: String) async throws -> Bool` ✅
  
- [x] Implement sign out
  - **Files Edited:** `Services/AuthService.swift` ✅
  - `signOut() throws` ✅
  
- [x] Implement session persistence
  - **Files Edited:** `Services/AuthService.swift` ✅
  - Listen to auth state changes ✅
  - Auto-restore session ✅
  
- [x] Create AuthViewModel
  - **Files Created:** `ViewModels/AuthViewModel.swift` ✅
  - Connect to AuthService ✅
  - Handle UI state ✅

### Testing:
- [x] Create AuthService unit tests
  - **Files Created:** `messageAITests/Services/AuthServiceTests.swift` ✅
  - Test email validation logic ✅
  - Test password validation ✅
  - Test auth state management ✅
  - Mock Firebase Auth for isolated testing ✅
  
- [x] Create Firebase Auth integration tests
  - **Files Created:** `messageAITests/Integration/AuthIntegrationTests.swift` ✅
  - Test actual sign up with Firebase (use test account) ✅
  - Test actual sign in with Firebase ✅
  - Test sign out ✅
  - Test session persistence ✅
  - **Note:** Use Firebase Emulator or test project for integration tests ✅
  
- [x] Create AuthViewModel unit tests
  - **Files Created:** `messageAITests/ViewModels/AuthViewModelTests.swift` ✅
  - Test view state changes ✅
  - Test error handling ✅
  - Mock AuthService ✅

### Files Summary:
- **Created:** `Services/AuthService.swift` (481 lines), `ViewModels/AuthViewModel.swift` (217 lines) ✅
- **Tests Created:** `messageAITests/Services/AuthServiceTests.swift` (277 lines), `messageAITests/Integration/AuthIntegrationTests.swift` (447 lines), `messageAITests/ViewModels/AuthViewModelTests.swift` (327 lines) ✅
- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #5 COMPLETE - All tasks finished, build successful

---

## PR #6: Auth UI (Sign In, Sign Up)
**Priority:** Critical  
**Estimated Time:** 2 hours  
**Branch:** `feature/auth-ui`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Create AuthView (entry point)
  - **Files Created:** `Views/Auth/AuthView.swift` ✅
  - Toggle between sign in and sign up ✅
  - Beautiful gradient background ✅
  - Logo and branding ✅
  
- [x] Create SignInView
  - **Files Created:** `Views/Auth/SignInView.swift` ✅
  - Email/password fields ✅
  - Sign in button with loading state ✅
  - Google Sign-In button ✅
  - Link to sign up (in AuthView) ✅
  - Form validation UI ✅
  
- [x] Create SignUpView
  - **Files Created:** `Views/Auth/SignUpView.swift` ✅
  - Email/password fields ✅
  - Confirm password field ✅
  - Sign up button with loading state ✅
  - Google Sign-In button ✅
  - Link to sign in (in AuthView) ✅
  - Terms and privacy notice ✅
  
- [x] Add form validation
  - **Files Edited:** `Views/Auth/SignInView.swift`, `Views/Auth/SignUpView.swift` ✅
  - Email format validation with error messages ✅
  - Password strength check (min 6 chars) ✅
  - Password match validation ✅
  - Real-time validation feedback ✅
  
- [x] Integrate with AuthViewModel
  - **Files Edited:** `Views/Auth/SignInView.swift`, `Views/Auth/SignUpView.swift` ✅
  - Call AuthService methods ✅
  - Handle loading states ✅
  - Handle errors with alerts ✅
  - Form enable/disable based on validation ✅
  
- [x] Update App entry point to show AuthView
  - **Files Edited:** `messageAIApp.swift` ✅
  - Show AuthView if not authenticated ✅
  - Show placeholder for onboarding (PR #7) ✅
  - Show placeholder for MainTabView (PR #9) ✅

### Testing:
- [ ] Create Auth UI tests (Deferred to PR #20)
  - **Files Created:** `messageAIUITests/AuthUITests.swift`
  - Test sign in flow UI navigation
  - Test sign up flow UI navigation
  - Test toggle between sign in/sign up
  - Test form validation displays errors
  - Test Google Sign-In button exists
  - Test successful auth navigates to main app
  
- [ ] Test email validation in UI (Deferred to PR #20)
  - **Files Edited:** `messageAIUITests/AuthUITests.swift`
  - Test invalid email shows error
  - Test valid email accepts input

### Files Summary:
- **Created:** `Views/Auth/AuthView.swift` (93 lines), `Views/Auth/SignInView.swift` (159 lines), `Views/Auth/SignUpView.swift` (193 lines) ✅
- **Edited:** `messageAIApp.swift` ✅
- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #6 COMPLETE - UI tests deferred to PR #20

---

## PR #7: Onboarding Flow
**Priority:** Critical  
**Estimated Time:** 1.5 hours  
**Branch:** `feature/onboarding`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Create OnboardingView
  - **Files Created:** `Views/Onboarding/OnboardingView.swift` ✅
  - Welcome message ✅
  - Display name input field ✅
  - Optional profile photo picker ✅
  - Get Started button ✅
  
- [x] Implement profile photo picker
  - **Files Edited:** `Views/Onboarding/OnboardingView.swift` ✅
  - PhotosPicker integration ✅
  - Image preview ✅
  - Image resizing for performance ✅
  - Base64 encoding for MVP (Firebase Storage integration later) ✅
  
- [x] Add profile creation logic in AuthService
  - **Files Edited:** `Services/AuthService.swift` ✅
  - `completeOnboarding(displayName: String, photoURL: String?) async throws` (already existed) ✅
  - Create user document in Firestore ✅
  
- [x] Add onboarding check after authentication
  - **Files Edited:** `Services/AuthService.swift` ✅
  - After sign in, check if user profile exists (already existed) ✅
  - Set `needsOnboarding` flag (already existed) ✅
  
- [x] Update App to show onboarding when needed
  - **Files Edited:** `messageAIApp.swift` ✅
  - Show OnboardingView if `needsOnboarding == true` ✅
  - Pass authService as EnvironmentObject ✅

### Files Summary:
- **Created:** `Views/Onboarding/OnboardingView.swift` (238 lines) ✅
- **Edited:** `messageAIApp.swift` ✅
- **Build Status:** ✅ PASSING
- **Linter Status:** ✅ NO ERRORS
- **Status:** ✅ PR #7 COMPLETE

---

## PR #8: User Service & Users List Screen
**Priority:** Critical  
**Estimated Time:** 2 hours  
**Branch:** `feature/users-list`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Create UserService
  - **Files Created:** `Services/UserService.swift` ✅
  - ObservableObject protocol ✅
  - @Published var allUsers ✅
  
- [x] Implement fetch all users from Firestore
  - **Files Edited:** `Services/UserService.swift` ✅
  - `fetchAllUsers() async throws -> [User]` ✅
  - Filter out current user ✅
  
- [x] Implement get user by ID
  - **Files Edited:** `Services/UserService.swift` ✅
  - `getUser(id: String) async throws -> User` ✅
  
- [x] Implement search users
  - **Files Edited:** `Services/UserService.swift` ✅
  - `searchUsers(query: String) -> [User]` ✅
  - Filter by display name ✅
  
- [x] Create UsersViewModel
  - **Files Created:** `ViewModels/UsersViewModel.swift` ✅
  - Connect to UserService ✅
  - Handle search state ✅
  
- [x] Create UsersListView
  - **Files Created:** `Views/Users/UsersListView.swift` ✅
  - List of all users ✅
  - Search bar ✅
  - Pull to refresh ✅
  
- [x] Create UserRowView
  - **Files Created:** `Views/Users/UserRowView.swift` ✅
  - User photo ✅
  - Display name ✅
  - Online/offline indicator ✅
  - Tap to start conversation ✅
  
- [x] Add navigation to chat on user tap
  - **Files Edited:** `Views/Users/UsersListView.swift` ✅
  - Placeholder sheet for ChatView ✅
  - Create or get conversation (PR #10) ✅

### Testing:
- [x] Create UserService unit tests
  - **Files Created:** `MessageAITests/Services/UserServiceTests.swift` ✅
  - Test search users logic ✅
  - Test filtering current user ✅
  - Test user data mapping ✅
  - Mock Firestore responses ✅
  
- [x] Create Firebase Firestore integration tests
  - **Files Created:** `MessageAITests/Integration/UserFirestoreTests.swift` ✅
  - Test fetch all users from Firestore ✅
  - Test get user by ID ✅
  - Test user document creation ✅
  - **Note:** Use Firebase Emulator or test project ✅
  
- [x] Create UsersViewModel unit tests
  - **Files Created:** `MessageAITests/ViewModels/UsersViewModelTests.swift` ✅
  - Test search filtering ✅
  - Test loading states ✅
  - Mock UserService ✅

### Files Summary:
- **Created:** `Services/UserService.swift` (240 lines), `ViewModels/UsersViewModel.swift` (127 lines), `Views/Users/UsersListView.swift` (172 lines), `Views/Users/UserRowView.swift` (134 lines) ✅
- **Tests Created:** `MessageAITests/Services/UserServiceTests.swift` (260 lines), `MessageAITests/Integration/UserFirestoreTests.swift` (357 lines), `MessageAITests/ViewModels/UsersViewModelTests.swift` (355 lines) ✅
- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #8 COMPLETE

---

## PR #9: Main Tab View & Navigation
**Priority:** Critical  
**Estimated Time:** 1 hour  
**Branch:** `feature/main-navigation`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Create UIStyleGuide with design system
  - **Files Created:** `Utils/UIStyleGuide.swift` ✅
  - Colors, typography, spacing, corner radius, shadows
  - View extensions for button styles and cards
  
- [x] Create MainTabView
  - **Files Created:** `Views/Main/MainTabView.swift` ✅
  - TabView with 3 tabs
  
- [x] Add Conversations tab
  - **Files Created:** `Views/Conversations/ConversationsListView.swift` ✅
  - Placeholder with empty state
  - Tab icon: message bubble
  
- [x] Add Users tab
  - **Files Edited:** `Views/Main/MainTabView.swift` ✅
  - UsersListView (already exists)
  - Tab icon: person.2
  
- [x] Add Profile tab
  - **Files Created:** `Views/Profile/ProfileView.swift` ✅
  - Tab icon: person.circle
  
- [x] Create ProfileView with user info
  - **Files Created:** `Views/Profile/ProfileView.swift` ✅
  - Profile header with photo and online status
  - User info card (Email, Member Since)
  - Settings section (Notifications only)
  - Sign out button with confirmation alert
  
- [x] Update App to use MainTabView
  - **Files Edited:** `messageAIApp.swift` ✅
  - Show MainTabView when authenticated
  
- [x] Update UsersListView to use UIStyleGuide
  - **Files Edited:** `Views/Users/UsersListView.swift` ✅
  - Applied consistent styling
  
- [x] Update UserRowView to use UIStyleGuide
  - **Files Edited:** `Views/Users/UserRowView.swift` ✅
  - Enhanced last seen formatting
  
- [x] Simplify OnboardingView
  - **Files Edited:** `Views/Onboarding/OnboardingView.swift` ✅
  - Removed photo upload feature
  - Show circle with user initial only
  
- [x] Move Color(hex:) extension to Extensions.swift
  - **Files Edited:** `Utils/Extensions.swift` ✅
  - Removed duplicate from AuthView.swift
  
- [x] Fix Auth view previews
  - **Files Edited:** `Views/Auth/SignInView.swift`, `Views/Auth/SignUpView.swift` ✅
  - Updated Preview macros

### Files Summary:
- **Created:** 
  - `Utils/UIStyleGuide.swift` (183 lines) ✅
  - `Views/Main/MainTabView.swift` (75 lines) ✅
  - `Views/Conversations/ConversationsListView.swift` (78 lines) ✅
  - `Views/Profile/ProfileView.swift` (299 lines) ✅
- **Edited:** 
  - `messageAIApp.swift` ✅
  - `Views/Users/UsersListView.swift` ✅
  - `Views/Users/UserRowView.swift` ✅
  - `Views/Onboarding/OnboardingView.swift` ✅
  - `Utils/Extensions.swift` ✅
  - `Views/Auth/AuthView.swift` ✅
  - `Views/Auth/SignInView.swift` ✅
  - `Views/Auth/SignUpView.swift` ✅
- **Status:** ✅ PR #9 COMPLETE - Design system implemented, 3-tab navigation working

---

## PR #10: Conversation Service
**Priority:** Critical  
**Estimated Time:** 1.5 hours  
**Branch:** `feature/conversation-service`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Create ConversationService
  - **Files Created:** `Services/ConversationService.swift` (440 lines) ✅
  - ObservableObject protocol ✅
  - @Published var conversations ✅
  - Local storage integration ✅
  
- [x] Implement create or get one-on-one conversation
  - **Files Edited:** `Services/ConversationService.swift` ✅
  - `createOrGetConversation(participantIds: [String]) async throws -> String` ✅
  - Check if conversation exists ✅
  - Create if doesn't exist ✅
  - Prevent duplicates ✅
  
- [x] Implement create group conversation
  - **Files Edited:** `Services/ConversationService.swift` ✅
  - `createGroupConversation(participantIds: [String], groupName: String) async throws -> String` ✅
  - Minimum 3 participants validation ✅
  - Group name validation ✅
  
- [x] Implement get conversation by ID
  - **Files Edited:** `Services/ConversationService.swift` ✅
  - `getConversation(id: String) async throws -> Conversation` ✅
  - Local storage first ✅
  
- [x] Implement fetch all conversations
  - **Files Edited:** `Services/ConversationService.swift` ✅
  - `fetchConversations() async throws` ✅
  - Get conversations where user is participant ✅
  - Load from local storage first ✅
  - Sync with Firestore ✅
  
- [x] Implement update last message
  - **Files Edited:** `Services/ConversationService.swift` ✅
  - `updateLastMessage(conversationId: String, message: Message) async throws` ✅
  - Update Firestore and local storage ✅
  
- [x] Add real-time listener for conversations
  - **Files Edited:** `Services/ConversationService.swift` ✅
  - `startListening(userId: String)` ✅
  - `stopListening()` ✅
  - Listen to Firestore changes ✅
  - Auto-update local storage ✅

### Testing:
- [x] Create ConversationService unit tests
  - **Files Created:** `MessageAITests/Services/ConversationServiceTests.swift` (243 lines) ✅
  - Test create conversation logic ✅
  - Test duplicate conversation prevention ✅
  - Test update last message logic ✅
  - Mock Firestore ✅
  - 10 test cases ✅
  
- [x] Create Conversation Firestore integration tests
  - **Files Created:** `MessageAITests/Integration/ConversationFirestoreTests.swift` (412 lines) ✅
  - Test create one-on-one conversation in Firestore ✅
  - Test create group conversation in Firestore ✅
  - Test fetch conversations by participant ✅
  - Test real-time listener functionality ✅
  - Test update last message ✅
  - **Note:** Use Firebase Emulator ✅
  - 13 test cases ✅
  
- [x] Update MockHelpers
  - **Files Updated:** `MessageAITests/Helpers/MockHelpers.swift` ✅
  - Added `mockMessage()` ✅
  - Added `mockConversation()` ✅

### Files Summary:
- **Created:** 
  - `Services/ConversationService.swift` (440 lines) ✅
  - `MessageAITests/Services/ConversationServiceTests.swift` (243 lines) ✅
  - `MessageAITests/Integration/ConversationFirestoreTests.swift` (412 lines) ✅
  - `PR10_QUICK_NOTES.md` ✅
- **Updated:**
  - `MessageAITests/Helpers/MockHelpers.swift` ✅
- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #10 COMPLETE - All tasks finished, ready for PR #11

---

## PR #11: Conversations List UI
**Priority:** Critical  
**Estimated Time:** 1.5 hours  
**Branch:** `feature/conversations-list`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Create ConversationsViewModel
  - **Files Created:** `ViewModels/ConversationsViewModel.swift` (189 lines) ✅
  - Connect to ConversationService ✅
  - Handle loading state ✅
  - Search and filtering ✅
  - Real-time updates via Combine ✅
  
- [x] Create ConversationsListView
  - **Files Updated:** `Views/Conversations/ConversationsListView.swift` (247 lines) ✅
  - List of conversations ✅
  - Pull to refresh ✅
  - Navigation to ChatView (placeholder) ✅
  - Loading and empty states ✅
  - Search functionality ✅
  
- [x] Create ConversationRowView
  - **Files Created:** `Views/Conversations/ConversationRowView.swift` (224 lines) ✅
  - Show participant names/photos (or group name) ✅
  - Last message preview ✅
  - Timestamp formatting (Today, Yesterday, day, date) ✅
  - Unread badge (placeholder) ✅
  - Avatar with user initial or group icon ✅
  
- [x] Add empty state
  - **Files Edited:** `Views/Conversations/ConversationsListView.swift` ✅
  - Show message when no conversations ✅
  - "Start a conversation" message ✅
  - Search empty state ✅
  
- [x] Connect to ConversationService
  - **Files Edited:** `Views/Conversations/ConversationsListView.swift` ✅
  - Fetch conversations on appear ✅
  - Start real-time listener ✅
  - Local-first loading from SwiftData ✅
  
- [x] Update UsersListView
  - **Files Edited:** `Views/Users/UsersListView.swift` (228 lines) ✅
  - Create conversation on user tap ✅
  - Loading overlay during creation ✅
  - Navigate to chat view ✅
  - Error handling ✅

### Files Summary:
- **Created:** 
  - `ViewModels/ConversationsViewModel.swift` (189 lines) ✅
  - `Views/Conversations/ConversationRowView.swift` (224 lines) ✅
  - `PR11_COMPLETION_SUMMARY.md` ✅
  - `PR11_QUICK_NOTES.md` ✅
- **Updated:** 
  - `Views/Conversations/ConversationsListView.swift` (247 lines) ✅
  - `Views/Users/UsersListView.swift` (228 lines) ✅
- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #11 COMPLETE - All tasks finished, ready for PR #12

---

## PR #12: Message Service (Local-First)
**Priority:** Critical  
**Estimated Time:** 2 hours  
**Branch:** `feature/message-service`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Create MessageService
  - **Files Created:** `Services/MessageService.swift` (450 lines) ✅
  - ObservableObject protocol ✅
  - @Published var messages ✅
  
- [x] Implement local-first send message
  - **Files Edited:** `Services/MessageService.swift` ✅
  - `sendMessage(conversationId: String, text: String) async throws` ✅
  - **Step 1:** Save to local storage FIRST ✅
  - **Step 2:** Update UI immediately ✅
  - **Step 3:** Sync to Firestore in background ✅
  - **Step 4:** Update with server ID ✅
  
- [x] Implement fetch messages from local storage
  - **Files Edited:** `Services/MessageService.swift` ✅
  - `fetchLocalMessages(conversationId: String)` ✅
  - Load on app launch ✅
  
- [x] Implement real-time message listener
  - **Files Edited:** `Services/MessageService.swift` ✅
  - `startListening(conversationId: String)` ✅
  - Listen to Firestore messages collection ✅
  
- [x] Implement sync local with remote
  - **Files Edited:** `Services/MessageService.swift` ✅
  - `mergeMessages()` ✅
  - Merge local and remote messages ✅
  
- [x] Implement offline message queue
  - **Files Edited:** `Services/MessageService.swift` ✅
  - Queue failed messages ✅
  - Retry on reconnection ✅
  
- [x] Implement mark messages as delivered
  - **Files Edited:** `Services/MessageService.swift` ✅
  - `markAsDelivered(conversationId: String, messageId: String) async throws` ✅
  
- [x] Implement mark messages as read
  - **Files Edited:** `Services/MessageService.swift` ✅
  - `markAsRead(conversationId: String, messageIds: [String]) async throws` ✅
  - Update local first, then Firestore ✅

### Testing:
- [x] Create MessageService unit tests
  - **Files Created:** `messageAITests/Services/MessageServiceTests.swift` (397 lines) ✅
  - Test local-first message send logic ✅
  - Test message status transitions ✅
  - Test offline queue management ✅
  - Test message validation ✅
  - Test multiple messages ordering ✅
  - 18 test cases ✅
  
- [x] Create Message Firestore integration tests
  - **Files Created:** `messageAITests/Integration/MessageFirestoreTests.swift` (393 lines) ✅
  - Test send message to Firestore ✅
  - Test receive message via real-time listener ✅
  - Test mark as delivered ✅
  - Test mark as read ✅
  - Test message ordering by timestamp ✅
  - Test typing indicators ✅
  - 13 test cases ✅
  - **Note:** Use Firebase Emulator ✅

### Files Summary:
- **Created:** `Services/MessageService.swift` (450 lines), `PR12_COMPLETION_SUMMARY.md`, `PR12_QUICK_NOTES.md` ✅
- **Tests Created:** `messageAITests/Services/MessageServiceTests.swift` (397 lines), `messageAITests/Integration/MessageFirestoreTests.swift` (393 lines) ✅
- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #12 COMPLETE - All tasks finished, ready for PR #13

---

## PR #13: Chat UI
**Priority:** Critical  
**Estimated Time:** 2.5 hours  
**Branch:** `feature/chat-ui`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Create ChatViewModel
  - **Files Created:** `ViewModels/ChatViewModel.swift` (275 lines) ✅
  - Connect to MessageService ✅
  - Handle message sending ✅
  - Handle loading states ✅
  - Manage typing indicators ✅
  - Auto-mark messages as read ✅
  
- [x] Create ChatView
  - **Files Created:** `Views/Chat/ChatView.swift` (228 lines) ✅
  - Navigation bar with participant info ✅
  - ScrollView for messages ✅
  - Message input at bottom ✅
  - Typing indicators display ✅
  - Date dividers (Today, Yesterday, etc.) ✅
  - Empty and loading states ✅
  
- [x] Create MessageBubbleView
  - **Files Created:** `Views/Chat/MessageBubbleView.swift` (265 lines) ✅
  - Different styles for sent/received ✅
  - Lime yellow for sent, white for received ✅
  - Show sender name (for groups) ✅
  - Show timestamp on tap ✅
  - Show status checkmarks (✓ ✓✓) ✅
  - Blue checkmarks for read ✅
  - Avatar circles with initials ✅
  
- [x] Create MessageInputView
  - **Files Created:** `Views/Chat/MessageInputView.swift` (121 lines) ✅
  - Multi-line text field (1-6 lines) ✅
  - Circular send button ✅
  - Disable when empty ✅
  - Clear after send ✅
  - Trigger typing indicator ✅
  
- [x] Create TypingIndicatorView
  - **Files Created:** `Views/Chat/TypingIndicatorView.swift` (119 lines) ✅
  - Animated three dots ✅
  - Show when user is typing ✅
  - Handle multiple users ✅
  
- [x] Connect ChatView to MessageService
  - **Files Edited:** `Views/Chat/ChatView.swift` ✅
  - Load messages on appear ✅
  - Start real-time listener ✅
  - Send messages ✅
  
- [x] Implement message sending from input
  - **Files Edited:** `Views/Chat/MessageInputView.swift`, `ViewModels/ChatViewModel.swift` ✅
  - Call MessageService.sendMessage ✅
  - Show instant feedback (local-first) ✅
  
- [x] Add mark as read on view appear
  - **Files Edited:** `Views/Chat/ChatView.swift` ✅
  - When chat opens, mark all messages as read ✅
  - Call MessageService.markAsRead ✅
  
- [x] Update ConversationsListView navigation
  - **Files Edited:** `Views/Conversations/ConversationsListView.swift` ✅
  - Navigate to real ChatView ✅
  - Remove placeholder ✅
  
- [x] Update UsersListView navigation
  - **Files Edited:** `Views/Users/UsersListView.swift` ✅
  - Navigate to real ChatView ✅
  - Remove placeholder ✅
  
- [x] Add default initializer to LocalStorageService
  - **Files Edited:** `Services/LocalStorageService.swift` ✅
  - Convenience init() for standalone usage ✅

### Testing:
- [ ] Create ChatViewModel unit tests (Deferred to PR #20)
  - **Files Created:** `MessageAITests/ViewModels/ChatViewModelTests.swift`
  - Test message sending logic
  - Test loading states
  - Test error handling
  - Mock MessageService
  
- [ ] Create Chat UI tests (Deferred to PR #20)
  - **Files Created:** `MessageAIUITests/ChatUITests.swift`
  - Test navigation to chat view
  - Test message input field interaction
  - Test send button enabled/disabled states
  - Test message appears in list after send
  - Test scroll to bottom on new message
  - Test message bubble styling (sent vs received)
  - Test timestamp display
  
- [ ] Create end-to-end messaging UI test (Deferred to PR #20)
  - **Files Created:** `MessageAIUITests/MessagingE2ETests.swift`
  - Test full flow: sign in → select user → send message → verify message appears
  - Test message persists after app restart (relaunch app)
  - Test offline message sending (mock network)

### Files Summary:
- **Created:** 
  - `ViewModels/ChatViewModel.swift` (275 lines) ✅
  - `Views/Chat/ChatView.swift` (228 lines) ✅
  - `Views/Chat/MessageBubbleView.swift` (265 lines) ✅
  - `Views/Chat/MessageInputView.swift` (121 lines) ✅
  - `Views/Chat/TypingIndicatorView.swift` (119 lines) ✅
  - `PR13_COMPLETION_SUMMARY.md` ✅
  - `PR13_QUICK_NOTES.md` ✅
- **Edited:**
  - `Services/LocalStorageService.swift` ✅
  - `Views/Conversations/ConversationsListView.swift` ✅
  - `Views/Users/UsersListView.swift` ✅
- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #13 COMPLETE - All tasks finished, UI tests deferred to PR #20

---

## PR #14: Read Receipts & Message Status
**Priority:** High  
**Estimated Time:** 1.5 hours  
**Branch:** `feature/read-receipts`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Implement status updates in MessageService
  - **Files Edited:** `Services/MessageService.swift` ✅
  - Update message status: sending → sent → delivered → read ✅
  - Update local storage first ✅
  - **Note:** Already implemented in PR #12
  
- [x] Add checkmark UI in MessageBubbleView
  - **Files Edited:** `Views/Chat/MessageBubbleView.swift` ✅
  - Show ✓ for sent ✅
  - Show ✓✓ for delivered ✅
  - Show blue ✓✓ for read (WhatsApp style) ✅
  - Only for sent messages ✅
  
- [x] Implement auto-mark as delivered
  - **Files Edited:** `Services/MessageService.swift` ✅
  - When message received via listener, mark as delivered ✅
  - Update deliveredTo map in Firestore ✅
  - **Note:** Already implemented in PR #12
  
- [x] Implement auto-mark as read
  - **Files Edited:** `ViewModels/ChatViewModel.swift` ✅
  - When ChatView appears, mark all unread messages as read ✅
  - Update readBy map in Firestore ✅
  - **Note:** Already implemented in PR #13
  
- [x] Update ConversationRowView to show unread badge
  - **Files Edited:** `Views/Conversations/ConversationRowView.swift`, `Views/Conversations/ConversationsListView.swift` ✅
  - Added unread count parameter ✅
  - Show lime yellow badge with count ✅
  - **Note:** Actual unread count calculation to be implemented later

### Testing:
- [x] Create read receipts integration tests
  - **Files Created:** `messageAITests/Integration/ReadReceiptsTests.swift` (317 lines) ✅
  - Test message status updates from sending → sent → delivered → read ✅
  - Test deliveredTo map updates in Firestore ✅
  - Test readBy map updates in Firestore ✅
  - Test auto-mark as delivered ✅
  - Test multiple messages read receipts ✅
  - Performance tests included ✅
  
- [ ] Create read receipts UI tests (Deferred to PR #20)
  - **Files Created:** `messageAIUITests/ReadReceiptsUITests.swift`
  - Test single checkmark appears for sent message
  - Test double checkmark appears for delivered message
  - Test blue double checkmark appears for read message
  - Test unread badge appears in conversations list
  - Test unread badge disappears after reading

### Files Summary:
- **Edited:** 
  - `Views/Chat/MessageBubbleView.swift` (enhanced status icons) ✅
  - `Views/Conversations/ConversationRowView.swift` (added unreadCount parameter) ✅
  - `Views/Conversations/ConversationsListView.swift` (pass unreadCount) ✅
- **Tests Created:** 
  - `messageAITests/Integration/ReadReceiptsTests.swift` (317 lines) ✅
- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #14 COMPLETE - Read receipts UI and integration tests ready

---

## PR #15: Group Chat ✅ COMPLETE
**Priority:** High  
**Estimated Time:** 2 hours  
**Actual Time:** 2.5 hours  
**Branch:** `feature/group-chat`

### Subtasks:
- [x] Create group creation UI
  - **Files Created:** `Views/Conversations/CreateGroupView.swift`
  - Select multiple users with search
  - Enter group name validation (minimum 2 participants)
  - Create button with loading state
  - Auto-dismiss on success (no auto-navigation to avoid crash)
  
- [x] Implement create group in ConversationService
  - **Files Verified:** `Services/ConversationService.swift`
  - createGroupConversation fully implemented and tested
  
- [x] Add navigation to create group
  - **Files Edited:** `Views/Conversations/ConversationsListView.swift`
  - Added "New Group" button in navigation bar (black tint)
  - Sheet presentation of CreateGroupView
  
- [x] Update ChatView to show group info
  - **Files Verified:** `Views/Chat/ChatView.swift`, `ViewModels/ChatViewModel.swift`
  - Group name displayed in navigation title
  - Participant count shown in subtitle ("{count} members")
  
- [x] Update MessageBubbleView for groups
  - **Files Verified:** `Views/Chat/MessageBubbleView.swift`
  - Sender name displayed for received messages in groups
  - Sender photo shown
  - Own messages don't show sender name
  
- [x] Test group messaging with 3+ users
  - **Successfully tested** with real users in simulator
  - Messages delivered to all participants
  - Read receipts work in groups
  
- [x] Fix LocalConversation decoding crash
  - **Files Edited:** `LocalModels/LocalConversation.swift`
  - Improved toConversation() with proper error handling
  - Safe decoding of nullable participantPhotos dictionary
  - Fallback mechanism prevents crashes

### Testing:
- [x] Create group chat integration tests
  - **Files Created:** `messageAITests/Integration/GroupChatTests.swift`
  - Test create group conversation with 3+ participants ✅
  - Test send message to group ✅
  - Test all participants receive message ✅
  - Test message attribution (sender name shows correctly) ✅
  - Test group name display ✅
  - Test participant count validation ✅
  - Test group appears in conversations list ✅
  
- [ ] Create group chat UI tests (Deferred)
  - UI tests can be added in future PR if needed

### Files Summary:
- **Created:** `Views/Conversations/CreateGroupView.swift`, `messageAITests/Integration/GroupChatTests.swift`
- **Edited:** `Views/Conversations/ConversationsListView.swift` (added New Group button), `LocalModels/LocalConversation.swift` (crash fix), `messageAITests/Services/ConversationServiceTests.swift` (test fixes)
- **Verified Working:** `Services/ConversationService.swift`, `Views/Chat/ChatView.swift`, `ViewModels/ChatViewModel.swift`, `Views/Chat/MessageBubbleView.swift`

### Key Implementation Details:
- Group creation uses sheet presentation with proper view model/service injection
- Dismiss modal after group creation (safer than immediate navigation)
- Real-time Firestore listener automatically shows new group in list
- LocalConversation safely handles nullable values in participantPhotos
- Integration tests cover full group chat lifecycle

- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #15 COMPLETE - Group chat fully functional with integration tests

---

## PR #16: Presence Service & Online Status
**Priority:** High  
**Estimated Time:** 1.5 hours  
**Branch:** `feature/presence`  
**Status:** ✅ COMPLETE

### Subtasks:
- [x] Create PresenceService
  - **Files Created:** `Services/PresenceService.swift` ✅
  - Set user online ✅
  - Set user offline ✅
  - Listen to presence changes ✅
  - Real-time Firestore listeners ✅
  - Last seen timestamp tracking ✅
  
- [x] Implement set online
  - **Files Edited:** `Services/PresenceService.swift` ✅
  - `setOnline(userId: String) async throws` ✅
  - Update user document: isOnline = true ✅
  - Update lastSeen timestamp ✅
  
- [x] Implement set offline
  - **Files Edited:** `Services/PresenceService.swift` ✅
  - `setOffline(userId: String) async throws` ✅
  - Update user document: isOnline = false, lastSeen = now ✅
  
- [x] Add app lifecycle observers
  - **Files Edited:** `messageAIApp.swift` ✅
  - On app foreground → set online ✅
  - On app background → set offline ✅
  - Handle inactive state (no action) ✅
  
- [x] Update UserRowView to show online status
  - **Files Edited:** `Views/Users/UserRowView.swift` ✅
  - Green dot for online ✅
  - "Last seen..." for offline ✅
  - **Note:** Already existed from previous PR, no changes needed
  
- [x] Update ChatView to show online status
  - **Files Edited:** `ViewModels/ChatViewModel.swift` ✅
  - Show in navigation subtitle ✅
  - "Online" or "Offline" status ✅
  - Real-time presence tracking for 1-on-1 chats ✅

### Testing:
- [x] Create PresenceService unit tests
  - **Files Created:** `messageAITests/Services/PresenceServiceTests.swift` (262 lines) ✅
  - Test set online logic ✅
  - Test set offline logic ✅
  - Test lastSeen timestamp updates ✅
  - Test listener management ✅
  - Test error handling ✅
  - 16 test cases total ✅
  
- [x] Create presence integration tests
  - **Files Created:** `messageAITests/Integration/PresenceTests.swift` (373 lines) ✅
  - Test user goes online (isOnline = true in Firestore) ✅
  - Test user goes offline (isOnline = false in Firestore) ✅
  - Test lastSeen updates on offline ✅
  - Test presence updates on app lifecycle events ✅
  - Test real-time listeners ✅
  - Test multiple users ✅
  - 11 test cases total ✅
  
- [ ] Create presence UI tests (Deferred to PR #20)
  - **Files Created:** `messageAIUITests/PresenceUITests.swift`
  - Test online indicator shows in users list
  - Test "Last seen" shows when offline
  - Test online status shows in chat header

### Files Summary:
- **Created:** 
  - `Services/PresenceService.swift` (210 lines) ✅
  - `messageAITests/Services/PresenceServiceTests.swift` (262 lines) ✅
  - `messageAITests/Integration/PresenceTests.swift` (373 lines) ✅
  - `PR16_COMPLETION_SUMMARY.md` ✅
  - `PR16_QUICK_NOTES.md` ✅
- **Edited:** 
  - `messageAIApp.swift` (app lifecycle observers) ✅
  - `ViewModels/ChatViewModel.swift` (presence tracking & navigation subtitle) ✅
- **Tests Created:** 27 test cases (16 unit + 11 integration) ✅
- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #16 COMPLETE - Real-time presence tracking fully functional

---

## PR #17: Typing Indicators
**Priority:** Medium  
**Estimated Time:** 1.5 hours  
**Branch:** `feature/typing-indicators`

### Subtasks:
- [x] Add typing indicator logic to MessageService
  - **Files Edited:** `Services/MessageService.swift` ✅
  - `setTyping(conversationId: String, isTyping: Bool) async throws` ✅
  - Write to temporary Firestore subcollection with TTL ✅
  
- [x] Add typing state listener
  - **Files Edited:** `Services/MessageService.swift` ✅
  - `startListeningForTyping(conversationId: String)` ✅
  - Listen to typing subcollection ✅
  - Update @Published var typingUsers ✅
  
- [x] Add typing detection in MessageInputView
  - **Files Edited:** `Views/Chat/MessageInputView.swift` ✅
  - On text change → set typing = true ✅
  - Debounce for 3 seconds → set typing = false ✅
  
- [x] Update TypingIndicatorView
  - **Files Edited:** `Views/Chat/TypingIndicatorView.swift` ✅
  - Show "User is typing..." for 1-on-1 ✅
  - Show "User X is typing..." for groups ✅
  - Animated dots ✅
  
- [x] Add typing indicator to ChatView
  - **Files Edited:** `Views/Chat/ChatView.swift` ✅
  - Show TypingIndicatorView when someone is typing ✅
  - Position above message input ✅

### Testing:
- [ ] Create typing indicators integration tests
  - **Files Created:** `MessageAITests/Integration/TypingIndicatorTests.swift`
  - Test typing state writes to Firestore subcollection
  - Test typing state expires after 3 seconds (TTL)
  - Test typing listener detects changes
  - Test debounce logic (stops typing after 3 seconds)
  
- [ ] Create typing indicators UI tests
  - **Files Created:** `MessageAIUITests/TypingIndicatorUITests.swift`
  - Test typing indicator appears when typing
  - Test typing indicator shows correct user name
  - Test typing indicator disappears after delay
  - Test animated dots display

### Files Summary:
- **Edited:** 
  - `Services/MessageService.swift` (setTyping, startListeningForTyping) ✅
  - `ViewModels/ChatViewModel.swift` (onMessageTextChanged, typing debounce) ✅
  - `Views/Chat/MessageInputView.swift` (onTextChanged callback) ✅
  - `Views/Chat/TypingIndicatorView.swift` (animated UI) ✅
  - `Views/Chat/ChatView.swift` (typing indicator display) ✅
- **Tests Created:** None yet (deferred)
- **Build Status:** ✅ PASSING
- **Status:** ✅ PR #17 COMPLETE - Typing indicators fully functional (tests deferred to PR #20)

---

## PR #18: Push Notifications (Foreground Only)
**Priority:** High  
**Estimated Time:** 2 hours  
**Branch:** `feature/notifications`

### Subtasks:
- [ ] Create NotificationService
  - **Files Created:** `Services/NotificationService.swift`
  - Request permissions
  - Register FCM token
  - Show foreground notifications
  
- [ ] Implement request permissions
  - **Files Edited:** `Services/NotificationService.swift`
  - `requestPermissions() async throws`
  - Use UNUserNotificationCenter
  
- [ ] Implement FCM token registration
  - **Files Edited:** `Services/NotificationService.swift`
  - `registerToken() async throws`
  - Get FCM token
  - Save to user document in Firestore
  
- [ ] Add FCM token to User model
  - **Files Edited:** `Models/User.swift`
  - Add fcmToken property if not already there
  
- [ ] Request permissions on app launch
  - **Files Edited:** `MessageAIApp.swift`
  - Call NotificationService.requestPermissions()
  - Register FCM token after auth
  
- [ ] Implement foreground notification display
  - **Files Edited:** `Services/NotificationService.swift`
  - `showForegroundNotification(from: String, message: String, conversationId: String)`
  - Use UNUserNotificationCenter to show banner
  
- [ ] Add notification listener in MessageService
  - **Files Edited:** `Services/MessageService.swift`
  - When new message arrives, check if current conversation
  - If different conversation, show notification
  
- [ ] Add notification tap handling
  - **Files Edited:** `Services/NotificationService.swift`, `MessageAIApp.swift`
  - Navigate to conversation on tap

### Testing:
- [ ] Create NotificationService unit tests
  - **Files Created:** `MessageAITests/Services/NotificationServiceTests.swift`
  - Test permission request logic
  - Test FCM token handling
  - Test notification payload creation
  - Mock UNUserNotificationCenter
  
- [ ] Create notifications integration tests
  - **Files Created:** `MessageAITests/Integration/NotificationsTests.swift`
  - Test FCM token saves to user document in Firestore
  - Test foreground notification displays
  - Test notification tap navigation
  - **Note:** May need to manually test on device
  
- [ ] Manual testing checklist for notifications
  - **Files Created:** `TESTING_NOTES.md`
  - Document manual test steps for:
    - Foreground notification appears when message received
    - Tap notification navigates to correct conversation
    - Notification shows correct sender name and message preview

### Files Summary:
- **Created:** `Services/NotificationService.swift`, `TESTING_NOTES.md`
- **Edited:** `Models/User.swift`, `MessageAIApp.swift`, `Services/MessageService.swift`
- **Tests Created:** `MessageAITests/Services/NotificationServiceTests.swift`, `MessageAITests/Integration/NotificationsTests.swift`

---

## PR #19: Offline Support & Error Handling
**Priority:** High  
**Estimated Time:** 2 hours  
**Branch:** `feature/offline-support`

### Subtasks:
- [ ] Add network reachability monitoring
  - **Files Edited:** `Services/MessageService.swift` or create `NetworkMonitor.swift`
  - Monitor network status
  - Detect online/offline transitions
  
- [ ] Implement offline message queue
  - **Files Edited:** `Services/MessageService.swift`
  - Store failed messages in local queue
  - Retry on reconnection
  
- [ ] Add retry logic for failed messages
  - **Files Edited:** `Services/MessageService.swift`
  - `processOfflineQueue() async`
  - Called when network returns
  
- [ ] Add error handling in all services
  - **Files Edited:** All service files
  - Try-catch blocks
  - User-friendly error messages
  
- [ ] Add loading states in ViewModels
  - **Files Edited:** All ViewModel files
  - @Published var isLoading
  - @Published var errorMessage
  
- [ ] Add error alerts in UI
  - **Files Edited:** `Views/Chat/ChatView.swift`, `Views/Conversations/ConversationsListView.swift`
  - Show alert for errors
  - Retry button
  
- [ ] Add offline indicator in UI
  - **Files Edited:** `Views/Chat/ChatView.swift`
  - Show banner when offline
  - "Waiting for network..."
  
- [ ] Test offline scenarios
  - Manual testing with airplane mode
  - Ensure messages queue properly
  - Ensure sync on reconnection

### Testing:
- [ ] Create offline support unit tests
  - **Files Created:** `MessageAITests/Integration/OfflineSupportTests.swift`
  - Test message queues when offline
  - Test retry logic triggers on reconnection
  - Test local storage persists during offline
  - Test sync merges local and remote messages
  - Mock network reachability
  
- [ ] Create error handling tests
  - **Files Created:** `MessageAITests/Services/ErrorHandlingTests.swift`
  - Test error handling in all services
  - Test user-friendly error messages
  - Test retry mechanisms
  - Test graceful degradation
  
- [ ] Create network transition integration tests
  - **Files Created:** `MessageAITests/Integration/NetworkTransitionTests.swift`
  - Test online → offline transition
  - Test offline → online transition
  - Test message queuing during offline
  - Test automatic sync on reconnection
  - Test presence updates on network change
  
- [ ] Manual offline testing checklist
  - **Files Edited:** `TESTING_NOTES.md`
  - Add offline test scenarios:
    - Enable airplane mode → send message → message appears locally
    - Disable airplane mode → message syncs to Firestore
    - Receive message while offline → message appears when back online
    - App performance during poor network conditions

### Files Summary:
- **Edited:** All service files, all ViewModel files, `Views/Chat/ChatView.swift`, `Views/Conversations/ConversationsListView.swift`, `TESTING_NOTES.md`
- **Tests Created:** `MessageAITests/Integration/OfflineSupportTests.swift`, `MessageAITests/Services/ErrorHandlingTests.swift`, `MessageAITests/Integration/NetworkTransitionTests.swift`

---

## PR #20: Testing & Bug Fixes
**Priority:** Critical  
**Estimated Time:** 2-3 hours  
**Branch:** `feature/comprehensive-testing`

### Subtasks:

#### Two-Device Real-Time Testing:
- [ ] Test two-device real-time messaging
  - Use two physical devices or simulators
  - Send messages back and forth
  - Verify instant UI updates
  - Verify messages sync to both devices
  - **Document results in:** `TESTING_NOTES.md`
  
- [ ] Run all unit tests
  - Execute test suite for all services
  - Execute test suite for all ViewModels
  - Execute test suite for all models
  - Fix any failing tests
  - Aim for >80% code coverage on critical paths

#### Integration Testing:
- [ ] Run all Firebase integration tests
  - Test with Firebase Emulator or test project
  - Verify Auth integration tests pass
  - Verify Firestore integration tests pass
  - Verify real-time listeners work correctly
  - **Document any issues in:** `TESTING_NOTES.md`
  
- [ ] Test offline scenarios (manual + automated)
  - Run offline support integration tests
  - Disable network on one device
  - Send messages
  - Re-enable network
  - Verify messages sync
  - Verify no data loss
  
- [ ] Test app lifecycle (manual)
  - Background app mid-conversation
  - Receive messages while backgrounded
  - Foreground app
  - Verify messages appear
  - Force quit and relaunch
  - Verify messages persist

#### UI Testing:
- [ ] Run all UI test suites
  - Auth UI tests
  - Chat UI tests
  - End-to-end messaging tests
  - Read receipts UI tests
  - Group chat UI tests
  - Presence UI tests
  - Typing indicators UI tests
  - Fix any failing UI tests
  
- [ ] Test group chat with 3+ users (manual)
  - Create group with 3 users
  - Each user sends message
  - Verify all receive messages
  - Verify sender attribution
  
- [ ] Test authentication flows (manual)
  - Sign up with email
  - Sign in with email
  - Sign in with Google
  - Sign out
  - Test onboarding for new users
  
- [ ] Test users list (manual)
  - Verify all users shown
  - Test search
  - Test starting conversation from users list
  
- [ ] Test read receipts (manual)
  - Send message
  - Verify checkmarks update
  - Open chat on recipient device
  - Verify read checkmarks
  
- [ ] Test presence indicators (manual)
  - Go online/offline
  - Verify status updates in real-time
  
- [ ] Test typing indicators (manual)
  - Type in chat
  - Verify typing appears on other device
  
- [ ] Test foreground notifications (manual)
  - Open app on device B
  - Send message from device A
  - Verify notification banner appears

#### Bug Fixes:
- [ ] Create bug tracking document
  - **Files Created:** `BUGS.md`
  - Log all bugs found during testing
  - Prioritize by severity (Critical, High, Medium, Low)
  
- [ ] Fix critical bugs
  - Messages not syncing
  - App crashes
  - Authentication failures
  - Data loss issues
  
- [ ] Fix high priority bugs
  - UI glitches
  - Performance issues
  - Incorrect status updates
  
- [ ] Re-test after bug fixes
  - Verify fixes work
  - Run regression tests
  - Update test documentation

#### Polish & Performance:
- [ ] Polish UI
  - Adjust spacing, colors
  - Add loading indicators
  - Improve animations
  - Ensure consistent styling
  
- [ ] Performance testing
  - Test with 100+ messages in chat
  - Test with 20+ conversations
  - Verify smooth scrolling (60fps)
  - Check memory usage
  - Profile with Instruments if needed
  - Optimize slow operations
  
- [ ] Accessibility check
  - Test VoiceOver navigation
  - Verify proper labels
  - Check color contrast
  - Test Dynamic Type

#### Test Documentation:
- [ ] Update TESTING_NOTES.md
  - **Files Edited:** `TESTING_NOTES.md`
  - Document all manual test results
  - Document any known issues
  - Document workarounds
  - Document test environment setup
  
- [ ] Create test coverage report
  - Generate code coverage report
  - Document coverage percentage
  - Identify untested code paths
  - Add tests for critical untested areas

### Files Summary:
- **Created:** `BUGS.md`
- **Edited:** `TESTING_NOTES.md`, any files with bugs found during testing
- **Tests Run:** All unit tests, integration tests, UI tests

---

## PR #21: Final Deployment Preparation
**Priority:** Critical  
**Estimated Time:** 1-2 hours  
**Branch:** `feature/deployment`

### Subtasks:
- [ ] Update app bundle identifier
  - **Files Edited:** Project settings
  - Use unique identifier
  
- [ ] Configure signing & capabilities
  - **Files Edited:** Project settings
  - Add push notifications capability
  - Sign with Apple Developer account
  
- [ ] Set app version and build number
  - **Files Edited:** Project settings
  - Version: 1.0.0
  - Build: 1
  
- [ ] Add app icon
  - **Files Created:** Assets.xcassets/AppIcon
  - All required sizes
  
- [ ] Test on physical device
  - Deploy to iPhone
  - Full flow test
  
- [ ] Create archive for TestFlight
  - Product → Archive
  - Validate archive
  
- [ ] Upload to App Store Connect
  - Distribute to TestFlight
  - Fill in app information
  
- [ ] Create internal testing group (optional)
  - Add testers
  - Send invites
  
- [ ] Write README.md
  - **Files Created:** `README.md` at project root
  - Setup instructions
  - Firebase configuration steps
  - How to run locally
  
- [ ] Prepare demo video script
  - Plan what to show
  - Practice demo flow

### Files Summary:
- **Created:** `README.md`, app icon assets
- **Edited:** Project settings

---

## Testing Strategy Summary

### Testing Philosophy:

**Test Early, Test Often**
- Write tests alongside feature development (TDD when possible)
- Each PR includes relevant tests
- Critical paths have both unit and integration tests
- UI tests for key user flows

**Test Pyramid Approach:**
```
        /\
       /UI\         Few, slow, expensive - Key user flows
      /----\
     / Intg \       Moderate - Firebase & service integration
    /--------\
   /   Unit   \     Many, fast, cheap - Business logic & services
  /____________\
```

**When to Write Each Test Type:**
- **Unit Tests:** Write FIRST for all business logic, services, ViewModels, utilities
- **Integration Tests:** Write AFTER unit tests for Firebase operations, real-time sync, local-first architecture
- **UI Tests:** Write LAST for critical user journeys and end-to-end flows
- **Manual Tests:** Use for device-specific features (notifications, network transitions, multi-device scenarios)

### Test Organization:

```
MessageAITests/
├── Services/              # Unit tests for all services
│   ├── AuthServiceTests.swift
│   ├── MessageServiceTests.swift
│   ├── ConversationServiceTests.swift
│   └── ...
├── ViewModels/            # Unit tests for ViewModels
│   ├── AuthViewModelTests.swift
│   ├── ChatViewModelTests.swift
│   └── ...
├── Models/                # Unit tests for data models
│   └── ModelTests.swift
├── Utils/                 # Unit tests for utilities
│   └── ExtensionsTests.swift
├── Integration/           # Firebase integration tests
│   ├── AuthIntegrationTests.swift
│   ├── MessageFirestoreTests.swift
│   ├── LocalFirstIntegrationTests.swift
│   ├── ReadReceiptsTests.swift
│   ├── OfflineSupportTests.swift
│   └── ...
└── Helpers/              # Test utilities
    ├── FirebaseTestHelper.swift
    └── MockHelpers.swift

MessageAIUITests/
├── AuthUITests.swift
├── ChatUITests.swift
├── MessagingE2ETests.swift
├── ReadReceiptsUITests.swift
├── GroupChatUITests.swift
└── ...
```

### Test Types Implemented:

**Unit Tests** (Isolated component testing)
- FirebaseManager, AuthService, UserService, ConversationService, MessageService, PresenceService, NotificationService
- All ViewModels (AuthViewModel, UsersViewModel, ChatViewModel, etc.)
- Data models encoding/decoding
- Extensions and utilities
- **Location:** `MessageAITests/Services/`, `MessageAITests/ViewModels/`, `MessageAITests/Models/`, `MessageAITests/Utils/`

**Integration Tests** (Firebase & service integration)
- Firebase Auth integration
- Firestore CRUD operations
- Real-time listeners
- Local-first architecture
- Read receipts flow
- Presence updates
- Typing indicators
- Offline support and sync
- Network transitions
- **Location:** `MessageAITests/Integration/`
- **Note:** Requires Firebase Emulator Suite

**UI Tests** (End-to-end user flows)
- Authentication flow
- Chat messaging flow
- Read receipts display
- Group chat creation
- Presence indicators
- Typing indicators
- End-to-end messaging scenarios
- **Location:** `MessageAIUITests/`

**Manual Tests** (Device-specific features)
- Two-device real-time messaging
- Push notifications (foreground)
- Offline scenarios with airplane mode
- App lifecycle (background/foreground)
- Performance with large datasets
- **Documentation:** `TESTING_NOTES.md`

### Running Tests:

```bash
# Run all unit tests
xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 15'

# Run unit tests only
xcodebuild test -scheme MessageAI -only-testing:MessageAITests

# Run UI tests only
xcodebuild test -scheme MessageAI -only-testing:MessageAIUITests

# Run specific test class
xcodebuild test -scheme MessageAI -only-testing:MessageAITests/MessageServiceTests

# Start Firebase Emulator (for integration tests)
firebase emulators:start

# Run integration tests with emulator
xcodebuild test -scheme MessageAI -only-testing:MessageAITests/Integration
```

### Test Coverage Goals:

- **Critical Services:** >90% coverage (MessageService, AuthService, ConversationService)
- **Other Services:** >80% coverage
- **ViewModels:** >80% coverage
- **Models:** >90% coverage
- **Overall Project:** >75% coverage

### Key Test Files Created:

| Test File | Type | Tests |
|-----------|------|-------|
| `FirebaseManagerTests.swift` | Unit | Firebase initialization |
| `ModelTests.swift` | Unit | Data model encoding/decoding |
| `LocalStorageServiceTests.swift` | Unit | SwiftData operations |
| `AuthServiceTests.swift` | Unit | Auth logic |
| `AuthIntegrationTests.swift` | Integration | Firebase Auth |
| `AuthViewModelTests.swift` | Unit | Auth UI logic |
| `AuthUITests.swift` | UI | Auth flow E2E |
| `UserServiceTests.swift` | Unit | User management logic |
| `UserFirestoreTests.swift` | Integration | User CRUD in Firestore |
| `UsersViewModelTests.swift` | Unit | Users list logic |
| `ConversationServiceTests.swift` | Unit | Conversation logic |
| `ConversationFirestoreTests.swift` | Integration | Conversation CRUD |
| `MessageServiceTests.swift` | Unit | Message logic |
| `MessageFirestoreTests.swift` | Integration | Message CRUD & sync |
| `LocalFirstIntegrationTests.swift` | Integration | Local-first architecture |
| `ChatViewModelTests.swift` | Unit | Chat UI logic |
| `ChatUITests.swift` | UI | Chat interface |
| `MessagingE2ETests.swift` | UI | Complete messaging flow |
| `ReadReceiptsTests.swift` | Integration | Read receipts flow |
| `ReadReceiptsUITests.swift` | UI | Read receipts display |
| `GroupChatTests.swift` | Integration | Group messaging |
| `GroupChatUITests.swift` | UI | Group chat interface |
| `PresenceServiceTests.swift` | Unit | Presence logic |
| `PresenceTests.swift` | Integration | Presence updates |
| `PresenceUITests.swift` | UI | Online/offline display |
| `TypingIndicatorTests.swift` | Integration | Typing state sync |
| `TypingIndicatorUITests.swift` | UI | Typing indicator display |
| `NotificationServiceTests.swift` | Unit | Notification logic |
| `NotificationsTests.swift` | Integration | FCM & notifications |
| `OfflineSupportTests.swift` | Integration | Offline queue & sync |
| `ErrorHandlingTests.swift` | Unit | Error scenarios |
| `NetworkTransitionTests.swift` | Integration | Online/offline transitions |

**Total Test Files:** 30+ test files covering unit, integration, and UI tests

---

## Quick Reference Checklist

### Phase 1: Foundation (PRs 1-4) - Hours 0-6
- [x] PR #1: Project Setup & Firebase Configuration
- [x] PR #2: Firebase Manager & Core Services Setup
- [x] PR #3: Data Models
- [x] PR #4: Local Storage Service

### Phase 2: Authentication & Users (PRs 5-9) - Hours 6-12 ✅ COMPLETE
- [x] PR #5: Authentication Service & Google Sign-In ✅
- [x] PR #6: Auth UI (Sign In, Sign Up) ✅
- [x] PR #7: Onboarding Flow ✅
- [x] PR #8: User Service & Users List Screen ✅
- [x] PR #9: Main Tab View & Navigation ✅

### Phase 3: Core Messaging (PRs 10-14) - Hours 12-18 ✅ COMPLETE
- [x] PR #10: Conversation Service ✅
- [x] PR #11: Conversations List UI ✅
- [x] PR #12: Message Service (Local-First) ✅
- [x] PR #13: Chat UI ✅
- [x] PR #14: Read Receipts & Message Status ✅

### Phase 4: Advanced Features (PRs 15-18) - Hours 18-22 🚧 IN PROGRESS
- [x] PR #15: Group Chat ✅
- [x] PR #16: Presence Service & Online Status ✅
- [ ] PR #17: Typing Indicators
- [ ] PR #18: Push Notifications (Foreground Only)

### Phase 5: Polish & Deploy (PRs 19-21) - Hours 22-24
- [ ] PR #19: Offline Support & Error Handling
- [ ] PR #20: Testing & Bug Fixes
- [ ] PR #21: Final Deployment Preparation

---

## Git Workflow

For each PR:
```bash
# Create feature branch
git checkout -b feature/branch-name

# Make changes and commit
git add .
git commit -m "PR #X: Description of changes"

# Push to GitHub
git push origin feature/branch-name

# Create Pull Request on GitHub
# After review, merge to main
git checkout main
git pull origin main

# Repeat for next PR
```

---

**Total PRs:** 21  
**Total Test Files:** 30+  
**Estimated Total Time:** 24 hours  
**Test Coverage Goal:** >75% overall, >90% critical paths  
**Last Updated:** October 20, 2025