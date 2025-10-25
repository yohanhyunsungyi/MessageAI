# MessageAI Cloud Functions API Documentation

**Version:** 1.0
**Last Updated:** October 25, 2025
**Region:** us-central1
**Status:** Production Deployed ✅

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Rate Limiting](#rate-limiting)
4. [Error Handling](#error-handling)
5. [Cloud Functions Reference](#cloud-functions-reference)
   - [AI Features](#ai-features)
   - [Messaging](#messaging)
   - [Maintenance](#maintenance)
6. [Request/Response Examples](#requestresponse-examples)
7. [Error Codes](#error-codes)

---

## Overview

All Cloud Functions are deployed to Firebase Functions v2 (2nd generation) in the **us-central1** region.

**Base URL:**
```
https://us-central1-messagingai-75f21.cloudfunctions.net
```

**Invocation:**
- **iOS Client:** Use Firebase Functions SDK (`Functions.functions().httpsCallable()`)
- **HTTP:** POST requests with Firebase Auth ID token
- **Firestore Triggers:** Automatic (background execution)

---

## Authentication

All callable functions require Firebase Authentication.

### iOS SDK (Recommended)

```swift
import FirebaseFunctions

let functions = Functions.functions()

// Automatic auth context
let result = try await functions
    .httpsCallable("summarizeConversation")
    .call(["conversationId": "conv123"])
```

### HTTP Request (Manual)

```bash
curl -X POST \
  https://us-central1-messagingai-75f21.cloudfunctions.net/summarizeConversation \
  -H "Authorization: Bearer <FIREBASE_ID_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"data": {"conversationId": "conv123"}}'
```

### Authentication Context

Functions receive authenticated user info via `context.auth`:

```javascript
exports.myFunction = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const userId = context.auth.uid;
  const userEmail = context.auth.token.email;

  // Function logic
});
```

---

## Rate Limiting

**Global Limits:**
- 10 requests per minute per user
- 100 requests per day per user (free tier)

**Implementation:**
- In-memory tracking (resets on function cold start)
- Production: Should use Redis/Memorystore for persistence

**Rate Limit Error:**
```json
{
  "code": "resource-exhausted",
  "message": "Rate limit exceeded. Try again in 1 minute.",
  "details": null
}
```

---

## Error Handling

### Error Response Format

```json
{
  "code": "error-code",
  "message": "Human-readable error message",
  "details": {
    // Optional additional context
  }
}
```

### Common Error Codes

| Code | Description | Action |
|------|-------------|--------|
| `unauthenticated` | User not authenticated | Sign in required |
| `permission-denied` | User lacks permission | Check conversation access |
| `invalid-argument` | Invalid request parameters | Fix request data |
| `not-found` | Resource not found | Verify IDs |
| `resource-exhausted` | Rate limit exceeded | Wait and retry |
| `internal` | Server error | Retry with backoff |

### Client Error Handling (iOS)

```swift
do {
    let result = try await functions
        .httpsCallable("summarizeConversation")
        .call(["conversationId": id])
} catch {
    if let functionsError = error as NSError?,
       functionsError.domain == FunctionsErrorDomain {
        let code = FunctionsErrorCode(rawValue: functionsError.code)
        let message = functionsError.localizedDescription

        switch code {
        case .unauthenticated:
            // Redirect to login
        case .permissionDenied:
            // Show access error
        case .resourceExhausted:
            // Show rate limit message
        default:
            // Generic error
        }
    }
}
```

---

## Cloud Functions Reference

### AI Features

#### 1. summarizeConversation

Generates a concise summary of a conversation with key points and action items.

**Endpoint:** `summarizeConversation`

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `conversationId` | string | Yes | ID of conversation to summarize |
| `messageLimit` | number | No | Max messages to analyze (default: 100) |

**Request:**
```json
{
  "conversationId": "conv123",
  "messageLimit": 50
}
```

**Response:**
```json
{
  "summary": {
    "id": "sum_abc123",
    "conversationId": "conv123",
    "summary": "Key decisions were made about the API redesign...",
    "bulletPoints": [
      "Decided to migrate to GraphQL",
      "Bob will create the schema by Friday",
      "Performance benchmarks show 2x improvement"
    ],
    "messageCount": 47,
    "timeRange": {
      "start": "2025-10-24T10:00:00Z",
      "end": "2025-10-25T15:30:00Z"
    },
    "participants": ["alice", "bob", "charlie"],
    "generatedAt": "2025-10-25T15:35:00Z"
  }
}
```

**Performance:**
- Target: <2 seconds
- Actual: 1.5-2.5 seconds

**Errors:**
- `permission-denied`: User not a conversation participant
- `not-found`: Conversation not found
- `invalid-argument`: Invalid conversationId or messageLimit

**Cost:** ~$0.02 per summary

---

#### 2. extractActionItems

Extracts structured action items from a conversation.

**Endpoint:** `extractActionItems`

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `conversationId` | string | Yes | ID of conversation to analyze |
| `messageLimit` | number | No | Max messages to analyze (default: 100) |

**Request:**
```json
{
  "conversationId": "conv123",
  "messageLimit": 100
}
```

**Response:**
```json
{
  "actionItems": [
    {
      "id": "action_xyz789",
      "description": "Review PR #234 for API changes",
      "assignee": "sarah",
      "assigneeName": "Sarah Chen",
      "deadline": "2025-10-26T17:00:00Z",
      "priority": "high",
      "conversationId": "conv123",
      "conversationName": "#engineering-team",
      "extractedAt": "2025-10-25T15:40:00Z",
      "extractedBy": "ai",
      "status": "pending"
    },
    {
      "id": "action_def456",
      "description": "Update documentation for new API endpoints",
      "assignee": null,
      "deadline": null,
      "priority": "medium",
      "conversationId": "conv123",
      "conversationName": "#engineering-team",
      "extractedAt": "2025-10-25T15:40:00Z",
      "extractedBy": "ai",
      "status": "pending"
    }
  ]
}
```

**Storage:**
- Action items saved to `/actionItems/` Firestore collection
- Queryable by user, conversation, status

**Performance:**
- Target: <2 seconds
- Actual: 1-2 seconds

**Errors:**
- `permission-denied`: User not a conversation participant
- `not-found`: Conversation not found

**Cost:** ~$0.015 per extraction

---

#### 3. smartSearch

Performs semantic search across messages using RAG (Retrieval Augmented Generation).

**Endpoint:** `smartSearch`

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | Yes | Search query (natural language) |
| `topK` | number | No | Number of results (default: 5) |
| `conversationId` | string | No | Limit search to specific conversation |

**Request:**
```json
{
  "query": "discussion about caching strategy",
  "topK": 5,
  "conversationId": null
}
```

**Response:**
```json
{
  "results": [
    {
      "messageId": "msg_123",
      "conversationId": "conv_456",
      "conversationName": "#backend-team",
      "senderId": "user_alice",
      "senderName": "Alice Johnson",
      "text": "We should use Redis for session caching...",
      "timestamp": "2025-10-20T14:30:00Z",
      "relevanceScore": 0.92,
      "context": [
        "Previous: I looked into caching solutions...",
        "Current: We should use Redis for session caching...",
        "Next: That makes sense for our use case."
      ]
    },
    {
      "messageId": "msg_789",
      "conversationId": "conv_456",
      "conversationName": "#backend-team",
      "senderId": "user_bob",
      "senderName": "Bob Smith",
      "text": "Cache invalidation strategy needs consideration...",
      "timestamp": "2025-10-20T14:35:00Z",
      "relevanceScore": 0.87,
      "context": [...]
    }
  ]
}
```

**Performance:**
- Embedding generation: ~100ms
- Vector search: <100ms
- Re-ranking (optional): ~500ms
- **Total: <1 second**

**Errors:**
- `invalid-argument`: Empty query or invalid topK
- `not-found`: No results found

**Cost:** ~$0.001 per search

---

#### 4. extractDecisions

Identifies and tracks important decisions made in conversations.

**Endpoint:** `extractDecisions`

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `conversationId` | string | Yes | ID of conversation to analyze |
| `messageLimit` | number | No | Max messages to analyze (default: 100) |

**Request:**
```json
{
  "conversationId": "conv123",
  "messageLimit": 100
}
```

**Response:**
```json
{
  "decisions": [
    {
      "id": "dec_abc123",
      "summary": "Migrated to PostgreSQL for analytics database",
      "context": "After evaluating MongoDB and PostgreSQL, the team decided on PostgreSQL for better JSON support, team familiarity, and cost savings.",
      "participants": ["alice", "bob", "charlie"],
      "participantNames": ["Alice Johnson", "Bob Smith", "Charlie Davis"],
      "conversationId": "conv123",
      "conversationName": "#architecture",
      "timestamp": "2025-10-25T10:30:00Z",
      "tags": ["architecture", "database", "migration"],
      "createdBy": "ai"
    }
  ]
}
```

**Storage:**
- Decisions saved to `/decisions/` Firestore collection
- Queryable by conversation, participant, tags, date

**Performance:**
- Target: <4 seconds
- Actual: 2-4 seconds

**Errors:**
- `permission-denied`: User not a conversation participant
- `not-found`: Conversation not found

**Cost:** ~$0.03 per extraction

---

#### 5. aiAssistant

Natural language interface to AI features. Parses user intent and routes to appropriate feature.

**Endpoint:** `aiAssistant`

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message` | string | Yes | User's natural language command |

**Request:**
```json
{
  "message": "Summarize my latest conversation"
}
```

**Response (Summarization):**
```json
{
  "action": "summarize_conversation",
  "response": "📝 Here's a summary of #engineering-team:\n\n• Decided to use GraphQL for the new API\n• Bob will create the schema by Friday\n• Performance tests show 2x improvement\n\n3 action items identified.",
  "data": {
    "summary": {...},
    "actionItems": [...]
  }
}
```

**Request:**
```json
{
  "message": "What are my tasks?"
}
```

**Response (List Action Items):**
```json
{
  "action": "list_action_items",
  "response": "📋 You have 3 pending tasks:\n\n🔴 High: Review PR #234 (due today)\n🟡 Medium: Update API docs\n🟢 Low: Research GraphQL libraries\n\nTap any task to view details.",
  "data": {
    "actionItems": [...]
  }
}
```

**Supported Commands:**
- "Summarize my latest conversation"
- "What are my tasks?" / "List my action items"
- "Search for [topic]" / "Find messages about [topic]"
- "Track decisions in [conversation]"
- General conversational queries

**Performance:**
- Command parsing: ~500ms
- Feature execution: 1-4 seconds
- **Total: <3 seconds**

**Cost:** $0.005-0.05 depending on routed feature

---

#### 6. confirmSuggestion

Confirms a proactive meeting suggestion and creates a calendar event.

**Endpoint:** `confirmSuggestion`

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `suggestionId` | string | Yes | ID of proactive suggestion |
| `selectedSlotIndex` | number | Yes | Index of selected time slot (0-2) |

**Request:**
```json
{
  "suggestionId": "sugg_abc123",
  "selectedSlotIndex": 0
}
```

**Response:**
```json
{
  "success": true,
  "message": "Meeting scheduled successfully",
  "calendarMessage": {
    "id": "msg_calendar_xyz",
    "text": "📅 Meeting scheduled: API Redesign Discussion\n🕐 Tomorrow 2 PM PST / 5 PM EST / 10 PM GMT (60 min)\n👥 @alice @bob @charlie",
    "timestamp": "2025-10-25T16:00:00Z"
  },
  "suggestion": {
    "id": "sugg_abc123",
    "status": "accepted",
    "acceptedAt": "2025-10-25T16:00:00Z",
    "selectedTimeSlot": {
      "startTime": "2025-10-26T14:00:00-07:00",
      "endTime": "2025-10-26T15:00:00-07:00",
      "timezoneDisplays": {
        "America/Los_Angeles": "2 PM PST",
        "America/New_York": "5 PM EST",
        "Europe/London": "10 PM GMT"
      }
    }
  }
}
```

**Performance:**
- Target: <2 seconds
- Actual: 1-2 seconds

**Errors:**
- `not-found`: Suggestion not found
- `invalid-argument`: Invalid slot index
- `permission-denied`: User not a participant

---

#### 7. testAI

Health check endpoint to verify AI infrastructure (OpenAI, Pinecone).

**Endpoint:** `testAI`

**Parameters:**
None (or optional `testType` for specific tests)

**Request:**
```json
{}
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-25T16:00:00Z",
  "services": {
    "openai": {
      "status": "connected",
      "model": "gpt-4-turbo",
      "latency": 234
    },
    "pinecone": {
      "status": "connected",
      "index": "messageai-messages",
      "dimensions": 1536,
      "latency": 87
    }
  }
}
```

**Use Cases:**
- Deployment verification
- Monitoring/health checks
- Debugging AI infrastructure

---

### Messaging

#### 8. sendMessageNotification

**Type:** Firestore Trigger (onWrite)
**Path:** `/conversations/{conversationId}/messages/{messageId}`

**Automatic Processing:**
1. **Priority Classification:** Classifies message urgency
2. **Proactive Detection:** Detects scheduling needs
3. **Push Notification:** Sends FCM notifications to participants

**Trigger Logic:**
```javascript
exports.sendMessageNotification = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onWrite(async (change, context) => {
    const message = change.after.data();

    // 1. Classify priority
    const priority = await classifyPriority(message);
    if (priority === 'high' || priority === 'critical') {
      await change.after.ref.update({ priority, aiClassified: true });
    }

    // 2. Detect scheduling needs
    const schedulingDetection = await detectScheduling(message, conversation);
    if (schedulingDetection.needsMeeting && schedulingDetection.confidence > 0.7) {
      await createProactiveSuggestion(schedulingDetection);
    }

    // 3. Send push notifications
    await sendFCMNotifications(message, conversation, priority);
  });
```

**Performance:**
- Target: <1 second (non-blocking)
- Actual: 500-1000ms

---

#### 9. onMessageWritten

**Type:** Firestore Trigger (onWrite)
**Path:** `/conversations/{conversationId}/messages/{messageId}`

**Automatic Processing:**
1. **Generate Embedding:** Create vector embedding for message
2. **Index in Pinecone:** Store for semantic search

**Trigger Logic:**
```javascript
exports.onMessageWritten = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onWrite(async (change, context) => {
    const message = change.after.data();

    // Generate embedding
    const embedding = await openai.embeddings.create({
      model: "text-embedding-3-small",
      input: message.text
    });

    // Index in Pinecone
    await pinecone.upsert({
      id: context.params.messageId,
      values: embedding.data[0].embedding,
      metadata: {
        conversationId: context.params.conversationId,
        senderId: message.senderId,
        text: message.text,
        timestamp: message.timestamp
      }
    });
  });
```

**Performance:**
- Target: <500ms (background)
- Actual: 300-600ms

---

### Maintenance

#### 10. updateConversationMetadata

**Type:** Firestore Trigger (onCreate)
**Path:** `/conversations/{conversationId}/messages/{messageId}`

**Automatic Processing:**
Updates conversation metadata (last message, timestamp, unread counts).

**Trigger Logic:**
```javascript
exports.updateConversationMetadata = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const conversationRef = admin.firestore()
      .collection('conversations')
      .doc(context.params.conversationId);

    // Update last message info
    await conversationRef.update({
      lastMessage: message.text,
      lastMessageTimestamp: message.timestamp,
      lastMessageSenderId: message.senderId
    });

    // Increment unread counts for other participants
    const conversation = await conversationRef.get();
    const updates = {};
    conversation.data().participantIds
      .filter(id => id !== message.senderId)
      .forEach(id => {
        updates[`unreadCount.${id}`] = admin.firestore.FieldValue.increment(1);
      });

    await conversationRef.update(updates);
  });
```

---

#### 11. cleanupTypingIndicators

**Type:** Scheduled Function (Cron)
**Schedule:** Every 5 minutes

**Cleanup Logic:**
Removes stale typing indicators (>10 seconds old).

```javascript
exports.cleanupTypingIndicators = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const cutoff = Date.now() - 10000; // 10 seconds ago

    const conversationsSnapshot = await admin.firestore()
      .collection('conversations')
      .get();

    for (const convDoc of conversationsSnapshot.docs) {
      const typingSnapshot = await convDoc.ref
        .collection('typing')
        .where('timestamp', '<', cutoff)
        .get();

      const batch = admin.firestore().batch();
      typingSnapshot.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
    }
  });
```

---

## Request/Response Examples

### Example 1: Full AI Analysis

**Request (iOS):**
```swift
// Analyze conversation with all AI features
func analyzeConversation(id: String) async throws {
    // 1. Summarize
    let summary = try await functions
        .httpsCallable("summarizeConversation")
        .call(["conversationId": id])

    // 2. Extract action items
    let actions = try await functions
        .httpsCallable("extractActionItems")
        .call(["conversationId": id])

    // 3. Track decisions
    let decisions = try await functions
        .httpsCallable("extractDecisions")
        .call(["conversationId": id])

    print("Summary: \(summary)")
    print("Actions: \(actions)")
    print("Decisions: \(decisions)")
}
```

---

### Example 2: Natural Language Commands

**Request:**
```json
{"message": "What are my high priority tasks due today?"}
```

**Response:**
```json
{
  "action": "list_action_items",
  "response": "🔴 You have 2 high-priority tasks due today:\n\n1. Review PR #234 for API changes\n   From: #engineering-team\n   \n2. Fix production bug in payment flow\n   From: DM with Alice\n\nBoth require immediate attention!",
  "data": {
    "actionItems": [
      {
        "id": "action_1",
        "description": "Review PR #234 for API changes",
        "priority": "high",
        "deadline": "2025-10-25T17:00:00Z",
        "status": "pending"
      },
      {
        "id": "action_2",
        "description": "Fix production bug in payment flow",
        "priority": "high",
        "deadline": "2025-10-25T23:59:59Z",
        "status": "pending"
      }
    ]
  }
}
```

---

### Example 3: Proactive Assistant Flow

**Step 1: Detection (Automatic)**
```
User sends: "we need to schedule a meeting about the API redesign"
↓
Trigger: sendMessageNotification
↓
detectScheduling(message) → confidence: 0.85
↓
Create ProactiveSuggestion document
```

**Step 2: Time Finding (Background)**
```
generateTimeSlotsForSuggestion(suggestionId)
↓
Fetch timezones: alice (GMT), bob (PST), charlie (EST)
↓
Generate candidate slots → filter for working hours
↓
Update suggestion with top 3 time slots
```

**Step 3: User Confirmation (Manual)**
```swift
// User taps "Confirm" on suggested time
let result = try await functions
    .httpsCallable("confirmSuggestion")
    .call([
        "suggestionId": "sugg_123",
        "selectedSlotIndex": 0
    ])
```

**Step 4: Calendar Event (Automatic)**
```
Create calendar message in conversation:
"📅 Meeting scheduled: API Redesign Discussion
 🕐 Tomorrow 2 PM PST / 5 PM EST / 10 PM GMT (60 min)
 👥 @alice @bob @charlie"
```

---

## Error Codes

### HTTP Status Codes

Cloud Functions return standard Firebase Functions error codes:

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `ok` | 200 | Success |
| `cancelled` | 499 | Client cancelled request |
| `unknown` | 500 | Unknown server error |
| `invalid-argument` | 400 | Invalid request parameters |
| `deadline-exceeded` | 504 | Timeout |
| `not-found` | 404 | Resource not found |
| `already-exists` | 409 | Resource already exists |
| `permission-denied` | 403 | User lacks permission |
| `resource-exhausted` | 429 | Rate limit exceeded |
| `failed-precondition` | 400 | Precondition failed |
| `aborted` | 409 | Operation aborted |
| `out-of-range` | 400 | Invalid range |
| `unimplemented` | 501 | Not implemented |
| `internal` | 500 | Internal server error |
| `unavailable` | 503 | Service unavailable |
| `unauthenticated` | 401 | Authentication required |
| `data-loss` | 500 | Unrecoverable data loss |

### Custom Error Details

Functions may include additional error details:

```json
{
  "code": "invalid-argument",
  "message": "Invalid conversationId",
  "details": {
    "field": "conversationId",
    "value": "invalid-id-123",
    "expected": "Firestore document ID"
  }
}
```

---

## Best Practices

### 1. Retry Logic

```swift
func callWithRetry<T>(
    _ callable: HTTPSCallable,
    data: [String: Any],
    maxRetries: Int = 3
) async throws -> T {
    var lastError: Error?

    for attempt in 1...maxRetries {
        do {
            let result = try await callable.call(data)
            return result.data as! T
        } catch let error as NSError {
            lastError = error

            // Don't retry certain errors
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                if code == .invalidArgument ||
                   code == .permissionDenied ||
                   code == .unauthenticated {
                    throw error
                }
            }

            // Exponential backoff
            if attempt < maxRetries {
                let delay = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw lastError!
}
```

### 2. Timeout Handling

```swift
func callWithTimeout<T>(
    _ callable: HTTPSCallable,
    data: [String: Any],
    timeout: TimeInterval = 30
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            let result = try await callable.call(data)
            return result.data as! T
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw TimeoutError()
        }

        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

### 3. Caching

```swift
class AIService {
    private var cache: [String: (result: Any, timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes

    func smartSearch(query: String) async throws -> [SearchResult] {
        // Check cache
        if let cached = cache[query],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            return cached.result as! [SearchResult]
        }

        // Call API
        let results = try await callSmartSearch(query)

        // Update cache
        cache[query] = (results, Date())

        return results
    }
}
```

---

## Monitoring

### View Function Logs

```bash
# Real-time logs
firebase functions:log

# Filter by function
firebase functions:log --only summarizeConversation

# Tail logs
firebase functions:log --tail
```

### Metrics

**Firebase Console:**
- Invocations: Count of function calls
- Execution time: P50, P95, P99 latencies
- Errors: Error rate and types
- Memory usage: Peak and average

**Custom Metrics (in code):**
```javascript
const { logger } = require("firebase-functions");

logger.info("Summarization completed", {
  conversationId: data.conversationId,
  messageCount: messages.length,
  duration: Date.now() - startTime,
  userId: context.auth.uid
});
```

---

**Document Version:** 1.0
**Last Updated:** October 25, 2025
**Author:** Yohan Yi
**Status:** Production Deployed ✅
