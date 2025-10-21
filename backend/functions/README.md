# MessageAI Cloud Functions

Firebase Cloud Functions for handling push notifications and background tasks.

## Setup

### 1. Install Dependencies

```bash
cd backend/functions
npm install
```

### 2. Deploy Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:sendMessageNotification
```

### 3. Test Locally with Emulator

```bash
# From project root
firebase emulators:start

# Functions will be available at:
# http://localhost:5001/{project-id}/us-central1/sendMessageNotification
```

## Functions

### sendMessageNotification

**Trigger:** Firestore onCreate  
**Path:** `/conversations/{conversationId}/messages/{messageId}`

Automatically sends push notifications to all conversation participants (except the sender) when a new message is created.

**Features:**
- Fetches recipient FCM tokens from Firestore
- Sends notification with message content
- Cleans up invalid FCM tokens
- Logs success/failure for monitoring

**Payload:**
```json
{
  "notification": {
    "title": "Sender Name",
    "body": "Message text",
    "sound": "default"
  },
  "data": {
    "conversationId": "conv123",
    "messageId": "msg456",
    "type": "new_message",
    "senderId": "user789",
    "senderName": "John Doe"
  }
}
```

### cleanupTypingIndicators

**Trigger:** Cloud Scheduler (every 5 minutes)  
**Function:** Removes stale typing indicators

Cleans up typing indicator documents older than 5 seconds to prevent memory leaks.

### updateConversationMetadata

**Trigger:** Firestore onUpdate  
**Path:** `/conversations/{conversationId}`

Logs when conversation participants change. Can be extended to notify users about group changes.

## Monitoring

### View Logs

```bash
# Real-time logs
firebase functions:log

# Filter by function
firebase functions:log --only sendMessageNotification

# View in Firebase Console
https://console.firebase.google.com/project/{project-id}/functions/logs
```

### Performance Metrics

Monitor function performance in Firebase Console:
- Invocation count
- Execution time
- Error rate
- Memory usage

## Troubleshooting

### Function Not Triggering

1. Check Firestore path matches: `/conversations/{conversationId}/messages/{messageId}`
2. Verify function is deployed: `firebase functions:list`
3. Check logs for errors: `firebase functions:log`

### Notifications Not Received

1. Verify FCM tokens are stored in user documents
2. Check if tokens are valid (not empty strings)
3. Ensure iOS app has notification permissions enabled
4. Check if user's device is registered for remote notifications
5. Review function logs for send failures

### Invalid Tokens

The function automatically removes invalid FCM tokens. Check logs for:
- `messaging/invalid-registration-token`
- `messaging/registration-token-not-registered`

These tokens are cleaned up from Firestore automatically.

## Cost Optimization

- Functions run in `us-central1` by default (cheapest region)
- Use Cloud Scheduler sparingly (cleanupTypingIndicators)
- Monitor invocation counts to stay within free tier:
  - 2M invocations/month (free tier)
  - 125,000 invocations/month (Spark plan)

## Security

- Functions run with admin privileges (full access to Firestore)
- Only deployed functions can write to Firestore (via admin SDK)
- FCM tokens are private and only accessible to cloud functions
- No client-side code can send notifications directly

## Environment Variables (if needed)

```bash
# Set environment config
firebase functions:config:set someservice.key="THE API KEY"

# Get current config
firebase functions:config:get

# Use in code
functions.config().someservice.key
```

## Testing

### Unit Tests (optional)

```bash
npm test
```

### Integration Tests

1. Start emulators: `firebase emulators:start`
2. Create a test message in Firestore
3. Check if function triggers in emulator logs
4. Verify notification payload in logs

## Best Practices

1. **Always handle errors** - Functions should never throw
2. **Return a promise/value** - Signals function completion
3. **Use batch writes** - For multiple Firestore updates
4. **Log important events** - For debugging and monitoring
5. **Clean up listeners** - Prevent memory leaks
6. **Keep functions fast** - Aim for <1 second execution time

## Deployment Checklist

- [ ] Install dependencies: `npm install`
- [ ] Test locally with emulators
- [ ] Run linter: `npm run lint`
- [ ] Deploy: `firebase deploy --only functions`
- [ ] Verify deployment in Firebase Console
- [ ] Test with real messages
- [ ] Monitor logs for errors
- [ ] Check notification delivery

## Support

For Firebase Cloud Functions documentation:
- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Cloud Functions Samples](https://github.com/firebase/functions-samples)

