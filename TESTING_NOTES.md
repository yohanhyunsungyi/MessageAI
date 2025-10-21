# MessageAI - Testing Documentation

## Overview

This document provides comprehensive information about testing the MessageAI application, including setup instructions, test types, and manual testing procedures.

---

## Table of Contents

1. [Firebase Emulator Setup](#firebase-emulator-setup)
2. [Running Tests](#running-tests)
3. [Test Types](#test-types)
4. [Manual Testing Procedures](#manual-testing-procedures)
5. [Test Helpers](#test-helpers)
6. [Common Issues](#common-issues)

---

## Firebase Emulator Setup

### Prerequisites

- Node.js and npm installed
- Firebase CLI installed globally: `npm install -g firebase-tools`
- Firebase project configured: `messagingai-75f21`

### Emulator Configuration

The project is configured to use the following emulators:

- **Auth Emulator:** `localhost:9099`
- **Firestore Emulator:** `localhost:8080`
- **Emulator UI:** `localhost:4000`

Configuration is in `firebase.json`:

```json
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "ui": {
      "enabled": true,
      "port": 4000
    },
    "singleProjectMode": true
  }
}
```

### Starting the Emulators

```bash
# Navigate to project root
cd /Users/yohanyi/Desktop/GauntletAI/02_messageAI

# Start all configured emulators
firebase emulators:start

# Or start specific emulators
firebase emulators:start --only auth,firestore
```

**Expected Output:**
```
✔  All emulators ready! View status and logs at http://localhost:4000
┌───────────┬────────────────┬─────────────────────────────────┐
│ Emulator  │ Host:Port      │ View in Emulator UI             │
├───────────┼────────────────┼─────────────────────────────────┤
│ Auth      │ localhost:9099 │ http://localhost:4000/auth      │
│ Firestore │ localhost:8080 │ http://localhost:4000/firestore │
└───────────┴────────────────┴─────────────────────────────────┘
```

### Emulator UI

Access the Firebase Emulator UI at: http://localhost:4000

Features:
- View and manage test users in Auth Emulator
- Browse Firestore collections and documents
- Clear data between test runs
- Monitor real-time changes

---

## Running Tests

### Unit Tests

Unit tests are isolated tests that don't require Firebase or network access.

```bash
# Run all unit tests
xcodebuild test \
  -scheme messageAI \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0' \
  -only-testing:messageAITests

# Run specific test class
xcodebuild test \
  -scheme messageAI \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0' \
  -only-testing:messageAITests/AuthServiceTests

# Run specific test method
xcodebuild test \
  -scheme messageAI \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0' \
  -only-testing:messageAITests/AuthServiceTests/testEmailValidation
```

**In Xcode:**
1. Open the project in Xcode
2. Select the messageAI scheme
3. Press `⌘U` to run all tests
4. Or click the diamond next to a test to run individually

### Integration Tests

Integration tests use Firebase Emulators. **Ensure emulators are running before tests!**

```bash
# 1. Start emulators in one terminal
firebase emulators:start

# 2. In another terminal, run integration tests
xcodebuild test \
  -scheme messageAI \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0' \
  -only-testing:messageAITests/Integration
```

### UI Tests

UI tests simulate user interactions with the app.

```bash
# Run all UI tests
xcodebuild test \
  -scheme messageAI \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0' \
  -only-testing:messageAIUITests

# Run specific UI test
xcodebuild test \
  -scheme messageAI \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0' \
  -only-testing:messageAIUITests/AuthUITests
```

### Run All Tests

```bash
# Run everything (requires emulators running)
xcodebuild test \
  -scheme messageAI \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0'
```

---

## Test Types

### 1. Unit Tests (`messageAITests/`)

**Purpose:** Test individual components in isolation

**Characteristics:**
- Fast execution (< 1 second per test)
- No external dependencies (Firebase, network)
- Use mocks and stubs
- High code coverage target (>80%)

**Examples:**
- `ModelTests.swift` - Data model encoding/decoding
- `AuthServiceTests.swift` - Auth logic without Firebase
- `MessageServiceTests.swift` - Message handling logic
- `ExtensionsTests.swift` - Utility functions

**Mock Usage:**
```swift
import XCTest
@testable import messageAI

class AuthServiceTests: XCTestCase {
    func testEmailValidation() {
        let authService = AuthService()
        
        XCTAssertTrue(authService.isValidEmail("test@example.com"))
        XCTAssertFalse(authService.isValidEmail("invalid-email"))
    }
}
```

### 2. Integration Tests (`messageAITests/Integration/`)

**Purpose:** Test components working together with Firebase

**Characteristics:**
- Requires Firebase Emulators
- Tests real Firebase interactions
- Slower than unit tests (1-5 seconds)
- Use FirebaseTestHelper for setup/teardown

**Examples:**
- `AuthIntegrationTests.swift` - Firebase Auth operations
- `MessageFirestoreTests.swift` - Firestore CRUD operations
- `LocalFirstIntegrationTests.swift` - Local-first sync flow

**Example:**
```swift
import XCTest
@testable import messageAI

class AuthIntegrationTests: FirebaseIntegrationTestCase {
    
    func testUserSignUp() async throws {
        let email = MockHelpers.uniqueTestEmail()
        let password = MockHelpers.testPassword
        
        let authResult = try await FirebaseTestHelper.shared
            .createTestUser(email: email, password: password)
        
        XCTAssertNotNil(authResult.user)
        XCTAssertEqual(authResult.user.email, email)
    }
}
```

### 3. UI Tests (`messageAIUITests/`)

**Purpose:** End-to-end user flow testing

**Characteristics:**
- Simulates real user interactions
- Slowest tests (10-30 seconds)
- Tests complete workflows
- Catches UI/UX issues

**Examples:**
- `AuthUITests.swift` - Sign in/sign up flows
- `ChatUITests.swift` - Messaging interface
- `MessagingE2ETests.swift` - Complete messaging flow

**Example:**
```swift
import XCTest

class AuthUITests: XCTestCase {
    
    func testSignInFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        app.buttons["Sign In"].tap()
        
        // Verify navigation to main screen
        XCTAssertTrue(app.tabBars.buttons["Conversations"].exists)
    }
}
```

---

## Manual Testing Procedures

### Setup for Manual Testing

1. **Simulator or Physical Device**
   - iOS Simulator: iPhone 16 (iOS 26.0)
   - Physical Device: iPhone with iOS 17+

2. **Build and Run**
   ```bash
   # Build for simulator
   xcodebuild build \
     -scheme messageAI \
     -sdk iphonesimulator \
     -destination 'platform=iOS Simulator,name=iPhone 16'
   
   # Or use Xcode: ⌘R to run
   ```

### Test Cases

#### Authentication Tests

**Test 1: Email Sign Up**
1. Launch app
2. Tap "Sign Up"
3. Enter email: `test1@messageai.com`
4. Enter password: `Test123!`
5. Confirm password: `Test123!`
6. Tap "Sign Up"
7. **Expected:** Onboarding screen appears

**Test 2: Google Sign-In**
1. Launch app
2. Tap "Sign In with Google"
3. Select Google account
4. **Expected:** Redirects to onboarding (if new) or main app

**Test 3: Onboarding**
1. After sign up, see onboarding screen
2. Enter display name: "Test User"
3. (Optional) Add profile photo
4. Tap "Get Started"
5. **Expected:** Navigate to main app

#### Two-Device Messaging Test

**Setup:**
- Device A: iPhone 16 Simulator
- Device B: iPhone 16 Pro Simulator (or physical device)

**Steps:**
1. **Device A:** Sign in as `user1@messageai.com`
2. **Device B:** Sign in as `user2@messageai.com`
3. **Device A:** Go to Users tab
4. **Device A:** Tap on "User 2"
5. **Device A:** Type "Hello from User 1" and send
6. **Expected:** Message appears INSTANTLY on Device A
7. **Device B:** Message should appear within 100ms
8. **Device B:** Open conversation
9. **Device B:** Type "Hello back!" and send
10. **Expected:** Device A receives message in real-time

**Verify:**
- ✅ Messages appear instantly (local-first)
- ✅ Messages sync between devices
- ✅ Status updates: sending → sent → delivered → read
- ✅ Read receipts show blue checkmarks

#### Offline Testing

**Test 1: Offline Message Send**
1. Turn on Airplane Mode
2. Send a message
3. **Expected:** Message appears in UI with "sending" status
4. Turn off Airplane Mode
5. **Expected:** Message syncs and status updates to "sent"

**Test 2: Offline App Launch**
1. Turn on Airplane Mode
2. Force quit app
3. Relaunch app
4. **Expected:** Previous messages load from local storage

#### Group Chat Test

1. Create group with 3+ users
2. Set group name: "Test Group"
3. Each user sends a message
4. **Verify:**
   - All users receive all messages
   - Sender names/photos appear correctly
   - Read receipts work for all participants

#### Presence Test

1. User A launches app
2. User B sees User A as "Online"
3. User A closes app
4. User B sees "Last seen at [time]"

#### Typing Indicator Test

1. User A opens chat with User B
2. User A starts typing
3. User B sees "User A is typing..."
4. User A stops typing (3 seconds)
5. Typing indicator disappears

---

## Test Helpers

### FirebaseTestHelper

Located in `messageAITests/Helpers/FirebaseTestHelper.swift`

**Purpose:** Configure Firebase to use emulators and manage test data

**Key Methods:**

```swift
// Configure Firebase for testing
FirebaseTestHelper.shared.configureForTesting()

// Create test user
let authResult = try await FirebaseTestHelper.shared
    .createTestUser(email: "test@example.com", password: "password123")

// Sign in test user
let authResult = try await FirebaseTestHelper.shared
    .signInTestUser(email: "test@example.com", password: "password123")

// Clear all test data
try await FirebaseTestHelper.shared.clearFirestoreData()

// Clean up after tests
try await FirebaseTestHelper.shared.cleanup()
```

**Base Test Class:**

```swift
class MyIntegrationTest: FirebaseIntegrationTestCase {
    // Automatically configures Firebase and cleans up
}
```

### MockHelpers

Located in `messageAITests/Helpers/MockHelpers.swift`

**Purpose:** Generate mock data for unit tests

**Key Methods:**

```swift
// Mock user data
let user = MockHelpers.mockUser(
    id: "user123",
    displayName: "Test User",
    email: "test@example.com"
)

// Mock message data
let message = MockHelpers.mockMessage(
    text: "Hello, World!",
    status: "sent"
)

// Generate unique test email
let email = MockHelpers.uniqueTestEmail()

// Test credentials
let email = MockHelpers.testEmail1
let password = MockHelpers.testPassword
```

---

## Common Issues

### Issue 1: Firebase Emulators Not Starting

**Error:** "Port already in use"

**Solution:**
```bash
# Find and kill process using port 8080
lsof -ti:8080 | xargs kill -9

# Find and kill process using port 9099
lsof -ti:9099 | xargs kill -9

# Restart emulators
firebase emulators:start
```

### Issue 2: Integration Tests Fail with "Connection Refused"

**Cause:** Firebase Emulators not running

**Solution:**
1. Start emulators: `firebase emulators:start`
2. Wait for "All emulators ready!" message
3. Run tests again

### Issue 3: Tests Fail with "Permission Denied"

**Cause:** Firestore security rules blocking test operations

**Solution:**
- Emulators bypass security rules by default
- Ensure `settings.isSSLEnabled = false` in FirebaseTestHelper
- Check emulator is running on localhost

### Issue 4: Build Fails with "Undefined symbols"

**Cause:** Missing Firebase SDK imports

**Solution:**
```swift
// Ensure all required imports are present
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
```

### Issue 5: UI Tests Can't Find Elements

**Cause:** Accessibility identifiers not set

**Solution:**
```swift
// Add accessibility identifiers to views
TextField("Email", text: $email)
    .accessibilityIdentifier("EmailField")

// In UI tests
let emailField = app.textFields["EmailField"]
```

---

## Test Coverage Goals

| Category | Target Coverage | Priority |
|----------|----------------|----------|
| Services (Auth, Message, Conversation) | >90% | Critical |
| ViewModels | >80% | High |
| Models | >90% | High |
| Extensions | >80% | Medium |
| UI Components | >60% | Medium |
| **Overall Project** | **>75%** | Critical |

### Checking Test Coverage

1. Run tests with code coverage enabled
2. In Xcode: Product → Test (⌘U)
3. View coverage: Report Navigator → Coverage tab
4. Identify untested code paths
5. Add tests for critical sections

---

## Best Practices

### 1. Test Naming Convention

```swift
// ✅ Good
func testSendMessageUpdatesLocalStorageFirst()
func testSignInWithValidCredentialsSucceeds()
func testCreateGroupWithThreeParticipants()

// ❌ Bad
func test1()
func testMessage()
func testStuff()
```

### 2. Arrange-Act-Assert Pattern

```swift
func testExample() {
    // Arrange - Set up test data
    let email = "test@example.com"
    let service = AuthService()
    
    // Act - Perform action
    let isValid = service.isValidEmail(email)
    
    // Assert - Verify result
    XCTAssertTrue(isValid)
}
```

### 3. Async Test Handling

```swift
func testAsyncOperation() async throws {
    let result = try await someAsyncFunction()
    XCTAssertNotNil(result)
}
```

### 4. Test Data Cleanup

```swift
override func tearDown() async throws {
    // Always clean up test data
    try await FirebaseTestHelper.shared.cleanup()
    try await super.tearDown()
}
```

### 5. Meaningful Assertions

```swift
// ✅ Good
XCTAssertEqual(message.status, .sent, "Message should be marked as sent after Firestore sync")

// ❌ Bad
XCTAssertTrue(message.status == .sent)
```

---

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [iOS Testing Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/01-introduction.html)

---

**Last Updated:** October 20, 2025  
**Document Version:** 1.0  
**Test Framework:** XCTest  
**Firebase Emulators:** Auth, Firestore

