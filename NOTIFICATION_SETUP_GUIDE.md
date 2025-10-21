# Push Notifications Setup Guide

Complete guide to enable push notifications in MessageAI using Firebase Cloud Messaging.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Notification Flow                         │
└─────────────────────────────────────────────────────────────┘

1. User A sends message
   ↓
2. Message saved to Firestore: /conversations/{id}/messages/{id}
   ↓
3. Cloud Function triggered: sendMessageNotification
   ↓
4. Function fetches User B's FCM token from /users/{userId}
   ↓
5. Function sends notification via FCM
   ↓
6. User B's device receives notification
   ↓
7. If app is in foreground: Show banner notification
   If app is in background: Show lock screen notification
```

## Prerequisites

- ✅ Firebase project created
- ✅ iOS app registered in Firebase Console
- ✅ GoogleService-Info.plist added to project
- ✅ APNs certificate uploaded to Firebase (for production)
- ✅ Node.js 18+ installed
- ✅ Firebase CLI installed

## Step 1: iOS Setup (Already Done)

The iOS app is already configured with:
- ✅ Firebase Cloud Messaging SDK
- ✅ NotificationService for handling FCM
- ✅ Permission requests
- ✅ Token registration
- ✅ Foreground notification display

## Step 2: Deploy Cloud Functions

### Install Dependencies

```bash
cd backend/functions
npm install
```

### Deploy Functions to Firebase

```bash
# Login to Firebase (if not already logged in)
firebase login

# Select your project
firebase use messagingai-75f21

# Deploy functions
firebase deploy --only functions
```

Expected output:
```
✔  functions: Finished running predeploy script.
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX KB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: creating Node.js 18 function sendMessageNotification...
✔  functions[sendMessageNotification]: Successful create operation.
Function URL: https://us-central1-messagingai-75f21.cloudfunctions.net/sendMessageNotification

✨  Deploy complete!
```

### Verify Deployment

```bash
# List deployed functions
firebase functions:list

# Expected output:
# sendMessageNotification (Firestore onCreate)
# cleanupTypingIndicators (Cloud Scheduler)
# updateConversationMetadata (Firestore onUpdate)
```

## Step 3: APNs Setup (Production Only)

For production push notifications, you need an APNs certificate:

### Option A: APNs Authentication Key (Recommended)

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Create new key with "Apple Push Notifications service (APNs)"
3. Download the `.p8` file
4. In Firebase Console:
   - Project Settings → Cloud Messaging → iOS app
   - Upload APNs Authentication Key
   - Enter Key ID and Team ID

### Option B: APNs Certificate

1. Create CSR in Keychain Access
2. Upload to Apple Developer Portal
3. Download `.p12` certificate
4. Upload to Firebase Console

**Note:** For development/testing with simulators, APNs is not required.

## Step 4: Test Notifications

### Method 1: Test with Two Physical Devices

1. **Device A:**
   ```
   - Sign in as User A
   - Check FCM token is registered
   - Go to conversations list
   ```

2. **Device B:**
   ```
   - Sign in as User B
   - Open chat with User A
   - Send a message
   ```

3. **Verify:**
   - Device A should receive notification banner
   - Tap notification → Opens conversation
   - Message appears in chat

### Method 2: Test with Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Send test notification:
   ```
   Title: Test Message
   Body: Hello from Firebase!
   Target: FCM Registration Token
   Token: <paste user's FCM token from Firestore>
   ```

3. Additional options:
   - Data payload: `{ "conversationId": "test123" }`
   - Sound: default
   - Badge: 1

### Method 3: Test Cloud Function Locally

```bash
# Start emulators
firebase emulators:start

# In another terminal, create a test message
firebase firestore:write conversations/test123/messages/msg456 '{
  "senderId": "user1",
  "senderName": "Test User",
  "text": "Hello World!",
  "timestamp": {"_seconds": 1234567890, "_nanoseconds": 0},
  "status": "sent"
}'

# Check emulator logs for function execution
```

## Step 5: Verify Setup

### Check FCM Token Registration

```bash
# Open Firestore in Firebase Console
# Navigate to: users/{userId}
# Verify field exists: fcmToken: "dXxX..."
```

### Check Cloud Function Logs

```bash
# Real-time logs
firebase functions:log

# Should see logs like:
# 📬 New message created in conversation: conv123
# 👥 Notifying 1 recipient(s)
# ✓ Token found for user: user456
# 📤 Sending notifications to 1 device(s)
# ✅ Notification sent successfully
# Success count: 1
# Failure count: 0
```

### Debug Checklist

- [ ] FCM token saved in Firestore `/users/{userId}/fcmToken`
- [ ] Token is not empty string
- [ ] Cloud Function deployed successfully
- [ ] Function has correct permissions (Firebase Admin)
- [ ] iOS app requests notification permissions
- [ ] iOS app registered for remote notifications
- [ ] APNs certificate uploaded (production only)
- [ ] Device is connected to internet
- [ ] App has notification permissions enabled in Settings

## Common Issues & Solutions

### Issue 1: No Notification Received

**Symptoms:** Cloud Function executes but device doesn't receive notification

**Solutions:**
1. Check if FCM token is valid:
   ```bash
   # Test with Firebase Console
   Cloud Messaging → Send test message → Use FCM token
   ```

2. Verify iOS app has notification permissions:
   ```swift
   // In iOS Settings → MessageAI → Notifications
   // Ensure "Allow Notifications" is ON
   ```

3. Check APNs certificate (production):
   - Expired certificate
   - Wrong bundle ID
   - Incorrect Team ID

4. Review Cloud Function logs:
   ```bash
   firebase functions:log --only sendMessageNotification
   ```

### Issue 2: Token Not Registered

**Symptoms:** `fcmToken` field is empty in Firestore

**Solutions:**
1. Check app logs for token registration:
   ```
   📱 FCM token received: dXxX...
   ✅ FCM token auto-registered
   ```

2. Ensure user is authenticated before token registration
3. Call `registerToken()` after sign in
4. Check network connectivity

### Issue 3: Notification Shows for Active Chat

**Symptoms:** User sees notification for message in currently open chat

**Solution:** This is now fixed! The code checks `currentConversationId` and skips notifications for the active conversation.

Verify in logs:
```
📱 User is viewing conversation conv123 - skipping notification
```

### Issue 4: Invalid Token Errors

**Symptoms:** Function logs show:
```
❌ Failed to send to token 0: messaging/invalid-registration-token
```

**Solution:** 
- The function automatically removes invalid tokens
- User needs to sign in again to get new token
- Check if app was uninstalled/reinstalled

### Issue 5: Function Not Triggering

**Symptoms:** No logs appear when message is created

**Solutions:**
1. Verify function deployment:
   ```bash
   firebase functions:list
   ```

2. Check Firestore path matches exactly:
   ```
   /conversations/{conversationId}/messages/{messageId}
   ```

3. Ensure billing is enabled (Cloud Functions requires Blaze plan for production)

4. Check function quotas:
   ```
   Firebase Console → Functions → Usage
   ```

## Monitoring

### View Real-Time Logs

```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only sendMessageNotification

# With timestamps
firebase functions:log --lines 100
```

### Firebase Console Monitoring

1. Go to Firebase Console → Functions
2. View metrics:
   - Invocation count
   - Execution time
   - Error rate
   - Memory usage

### Set Up Alerts (Optional)

1. Firebase Console → Functions → Alerts
2. Create alert for:
   - High error rate (>1%)
   - Slow execution time (>5 seconds)
   - Memory limit exceeded

## Performance Optimization

### Current Setup

- **Function Region:** us-central1 (cheapest)
- **Memory:** 256MB (default)
- **Timeout:** 60s (default)
- **Runtime:** Node.js 18

### Optimization Tips

1. **Reduce Cold Starts:**
   ```javascript
   // Keep admin initialized globally
   admin.initializeApp();
   ```

2. **Batch Operations:**
   ```javascript
   // Send to multiple tokens at once
   await admin.messaging().sendToDevice(tokens, payload);
   ```

3. **Clean Up Invalid Tokens:**
   - Already implemented in function
   - Prevents wasted API calls

4. **Monitor Costs:**
   ```bash
   # Free tier limits:
   # - 2M invocations/month
   # - 400,000 GB-seconds
   # - 200,000 CPU-seconds
   ```

## Production Deployment

### Pre-Deployment Checklist

- [ ] Test with emulators
- [ ] Test with physical devices
- [ ] Verify APNs certificate uploaded
- [ ] Enable billing (Blaze plan)
- [ ] Set up monitoring and alerts
- [ ] Document FCM server key securely
- [ ] Review security rules
- [ ] Test error scenarios
- [ ] Verify function timeouts
- [ ] Check function quotas

### Deploy Commands

```bash
# Deploy everything
firebase deploy

# Deploy functions only
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:sendMessageNotification

# Deploy with force flag (if function already exists)
firebase deploy --only functions --force
```

### Post-Deployment

1. Monitor logs for first hour
2. Send test messages
3. Check notification delivery
4. Verify invalid token cleanup
5. Monitor costs in Firebase Console

## Troubleshooting Commands

```bash
# Check Firebase project
firebase projects:list

# Check current project
firebase use

# Check function status
firebase functions:list

# Delete function (if needed)
firebase functions:delete sendMessageNotification

# View detailed logs
firebase functions:log --only sendMessageNotification --lines 100

# Check function config
firebase functions:config:get
```

## Security Best Practices

1. **FCM Tokens:**
   - Never expose in client logs
   - Store securely in Firestore
   - Clean up invalid tokens
   - Rotate regularly

2. **Cloud Functions:**
   - Use Firebase Admin SDK (not client SDK)
   - Validate all inputs
   - Handle errors gracefully
   - Log security events

3. **Notifications:**
   - Don't include sensitive data in payload
   - Use data-only messages for sensitive info
   - Validate conversationId before sending
   - Rate limit if needed

## Next Steps

1. ✅ Deploy Cloud Functions
2. ✅ Test with two devices
3. ✅ Monitor function logs
4. ✅ Upload APNs certificate (production)
5. ⏭️ Add notification actions (Reply, Mark as Read)
6. ⏭️ Add notification sounds
7. ⏭️ Add notification grouping
8. ⏭️ Add badge count tracking

## Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [APNs Setup Guide](https://developer.apple.com/documentation/usernotifications)
- [FCM HTTP v1 API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
- [Firebase Console](https://console.firebase.google.com)

---

**Status:** Ready for deployment ✅  
**Last Updated:** October 21, 2025  
**Next PR:** PR #19 - Offline Support & Error Handling

