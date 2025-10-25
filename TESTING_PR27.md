# Testing PR #27: Priority Message Detection

## Quick Test Guide

### Setup
1. Ensure Cloud Functions are deployed (already done ✅)
2. Build and run the iOS app on simulator or device
3. Sign in with two different accounts (or use two devices/simulators)

### Test Cases

#### Test 1: Critical Priority Messages 🔴
Send messages containing critical urgency keywords:

```
"URGENT: Production is DOWN! Database connection failing!"
"CRITICAL BUG: Users can't login, system is broken"
"EMERGENCY: Payment system is completely failing"
"Production server is offline - need immediate help!"
```

**Expected Results:**
- Message should appear with 🔴 emoji next to the bubble
- Conversation should jump to the top of the list
- Push notification should have "🔴 [Sender Name]" in the title
- FCM priority set to "high"

#### Test 2: High Priority Messages 🟡
Send messages with high priority indicators:

```
"This is URGENT - need your response ASAP"
"I'm BLOCKED on the API integration, can you help?"
"Need this immediately for the client demo"
"Important: Deadline is today at 5pm"
```

**Expected Results:**
- Message should appear with 🟡 emoji next to the bubble
- Conversation should appear near the top of the list
- Push notification should have "🟡 [Sender Name]" in the title

#### Test 3: Normal Priority Messages (no badge)
Send regular conversation messages:

```
"Hey, how are you doing?"
"Did you see the latest updates?"
"Let's schedule a meeting next week"
"Thanks for the help earlier!"
```

**Expected Results:**
- Message appears without any emoji badge
- Conversation sorted by timestamp (most recent)
- Normal push notification (no emoji prefix)

### Testing Real-time Classification

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/project/messagingai-75f21/firestore
   - Navigate to: `conversations/{conversationId}/messages`

2. **Send a test message from the app**

3. **Check Firestore immediately** (within 1-2 seconds)
   - The message document should have:
     - `priority: "critical"` or `"high"` or `"normal"`
     - `aiClassified: true`

4. **Check Cloud Functions logs**
   ```bash
   cd /Users/yohanyi/Desktop/GauntletAI/02_messageAI/backend/functions
   firebase functions:log
   ```

   Look for:
   - `🎯 Classifying priority for message: ...`
   - `✓ Priority: [critical/high/normal] (confidence: 0.XX)`
   - `✅ Priority updated in Firestore`

### Visual Testing Checklist

#### In Chat View:
- [ ] Critical messages show 🔴 next to bubble
- [ ] High priority messages show 🟡 next to bubble
- [ ] Normal messages have no badge
- [ ] Badges appear on correct side (left for received, right for sent)

#### In Conversations List:
- [ ] Last message priority emoji shows in conversation row
- [ ] Conversations with critical messages appear at the top
- [ ] Conversations with high priority messages appear above normal ones
- [ ] Normal priority conversations sorted by timestamp

#### Push Notifications:
- [ ] Critical message notifications have 🔴 prefix
- [ ] High priority message notifications have 🟡 prefix
- [ ] Notifications arrive even when app is open
- [ ] Tapping notification opens correct conversation

### Performance Testing

1. **Measure Classification Speed**
   - Send a message
   - Time from send to priority appearing in Firestore
   - Target: <1 second total (including network)

2. **Check Function Logs for Timing**
   ```bash
   firebase functions:log --only sendMessageNotification
   ```

   Look for classification completion time

### Edge Cases to Test

1. **Mixed Priority Conversation**
   - Send normal message, then critical, then normal
   - Verify conversation jumps to top on critical message
   - Verify it stays at top until another critical message arrives elsewhere

2. **Rapid Messages**
   - Send 5 messages quickly
   - All should get classified
   - No messages should be skipped

3. **Emoji and Special Characters**
   - Send: "🚨 URGENT: Need help now! 🆘"
   - Should still classify correctly

4. **Long Messages**
   - Send a long message (200+ words) with "URGENT" at the end
   - Should still detect priority

5. **AI Failure Scenario**
   - Temporarily disable OpenAI API (remove env var)
   - Messages should default to "normal" priority
   - App should continue functioning (graceful degradation)

## Quick Manual Test Script

Run this complete flow:

1. **Start fresh**
   - Reset simulator: `./reset-simulator.sh`
   - Or clear app data

2. **Create two accounts**
   - Account A: test1@example.com
   - Account B: test2@example.com

3. **Send test sequence** (from Account A to B):
   ```
   Message 1: "Hey, how's it going?" (normal)
   Message 2: "URGENT: Production is down!" (critical 🔴)
   Message 3: "Need help ASAP with deployment" (high 🟡)
   Message 4: "Never mind, fixed it" (normal)
   ```

4. **Verify on Account B**:
   - Conversation shows at top of list
   - Last message shows no badge (normal)
   - Open chat: see badges on messages 2 (🔴) and 3 (🟡)

5. **Check Firestore**:
   - All 4 messages should have `priority` field
   - Message 2: `priority: "critical"`
   - Message 3: `priority: "high"`
   - Messages 1 & 4: `priority: "normal"`

## Automated Test (Optional - Future Enhancement)

If you want to add Jest tests for the Cloud Function:

```bash
cd /Users/yohanyi/Desktop/GauntletAI/02_messageAI/backend/functions
npm test -- priority.test.js
```

Note: Tests not yet implemented, but the function is production-ready.

## Troubleshooting

### Priority not appearing?
1. Check OpenAI API key is set in `.env.local`
2. Check Cloud Functions logs for errors
3. Verify message actually reached Firestore

### Classification too slow?
1. Check Cloud Functions logs for timing
2. Verify GPT-4 Turbo is being used (not GPT-4)
3. Check network connection to Firebase

### Badges not showing in UI?
1. Pull to refresh conversations list
2. Close and reopen chat view
3. Check Message model has priority field
4. Verify MessagePriority enum is imported

### Notifications not showing priority emoji?
1. Check device notification settings
2. Verify FCM token is registered
3. Check Cloud Functions logs for notification send
4. Test with background app (not foreground)

## Success Criteria

✅ Critical messages get 🔴 badge within 1 second
✅ High priority messages get 🟡 badge within 1 second
✅ Conversations auto-sort by priority
✅ Push notifications include priority emoji
✅ No crashes or errors in normal operation
✅ Graceful degradation if AI fails
✅ **NEW:** Action items automatically extracted from priority messages

## Automatic Action Item Extraction (Bonus Feature)

### How It Works
When a **high** or **critical** priority message is detected, the system automatically:
1. Analyzes the message for actionable tasks
2. Extracts structured action items (description, assignee, deadline)
3. Saves them to Firestore root `actionItems` collection
4. Makes them visible in the Action Items tab

### Test This Feature

**Send a priority message with actionable content:**
```
"URGENT: Need to fix the login bug by tomorrow.
John should review the auth code and deploy the patch ASAP."
```

**Expected Result:**
- Message gets 🔴 or 🟡 badge (priority classification)
- Action items automatically created:
  - "Fix the login bug" - Assignee: Auto-detected, Deadline: tomorrow
  - "Review the auth code" - Assignee: John
  - "Deploy the patch" - Priority: high

**Check Action Items:**
1. Navigate to Action Items tab in the app
2. Should see newly created items from the priority message
3. Items should have `createdFrom: "priority-message"` metadata

**Check Firestore:**
- Go to: `actionItems` (root collection)
- New documents should appear with:
  - `conversationId`: Source conversation ID
  - `conversationName`: Display name of conversation
  - `description`: Task description
  - `assignee`: Detected from message or "unassigned"
  - `deadline`: Detected deadline or "none"
  - `priority`: "high", "medium", or "low"
  - `status`: "pending"
  - `sourceMessageId`: ID of the priority message
  - `createdFrom`: "priority-message"
  - `extractedBy`: "ai"

**Performance:**
- Action item extraction runs in background (non-blocking)
- Message sending is not delayed
- Extraction completes within 2-3 seconds

**Edge Cases:**
- If no action keywords found, extraction is skipped
- If extraction fails, message still works normally
- Only high/critical priority messages trigger auto-extraction
- Normal priority messages don't trigger automatic extraction
