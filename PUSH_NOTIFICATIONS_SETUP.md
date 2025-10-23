# Push Notifications Setup Guide - Firebase Cloud Messaging (FCM)

**Project:** MessageAI
**Date:** 2025-10-23
**Platform:** iOS with Firebase Cloud Messaging

---

## Overview

This guide will help you set up push notifications for MessageAI using Firebase Cloud Messaging (FCM) and Apple Push Notification service (APNs).

**What's Already Done:** ✅
- NotificationService implemented in iOS app
- Cloud Functions written for sending notifications
- FCM token registration code implemented
- Foreground notification handling configured

**What You Need to Do:**
1. Configure APNs certificates in Firebase Console
2. Add entitlements file to Xcode project
3. Deploy Cloud Functions to Firebase
4. Test push notifications

---

## Prerequisites

### Required Accounts
- ✅ Apple Developer Account (for APNs certificates)
- ✅ Firebase Project: `messagingai-75f21`
- ✅ Xcode 16.0+
- ✅ iOS Device (push notifications don't work on simulator)

### Required Tools
```bash
# Check if Firebase CLI is installed
firebase --version

# If not installed:
npm install -g firebase-tools

# Login to Firebase
firebase login
```

---

## Part 1: Apple Push Notification Configuration

### Step 1: Create APNs Authentication Key (Recommended Method)

**Why:** APNs keys are easier to manage and don't expire like certificates.

1. **Go to Apple Developer Portal:**
   - Visit: https://developer.apple.com/account/resources/authkeys/list
   - Sign in with your Apple Developer account

2. **Create a New Key:**
   - Click the **+** button
   - Key Name: `MessageAI Push Notifications`
   - Enable: **Apple Push Notifications service (APNs)**
   - Click **Continue**, then **Register**

3. **Download the Key:**
   - Click **Download** (you can only download once!)
   - Save as: `AuthKey_XXXXXXXXXX.p8`
   - **IMPORTANT:** Note the **Key ID** (10 characters)
   - **IMPORTANT:** Note your **Team ID** (find in top right of developer portal)

4. **Keep These Values Safe:**
   ```
   Key ID: __________ (10 characters)
   Team ID: __________ (10 characters)
   Key File: AuthKey_XXXXXXXXXX.p8
   ```

### Alternative: APNs Certificate (Legacy Method)

<details>
<summary>Click to expand legacy certificate method</summary>

1. **Create Certificate Signing Request (CSR):**
   - Open **Keychain Access** on Mac
   - Menu: Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
   - Email: your@email.com
   - Common Name: MessageAI Push Cert
   - Request: **Saved to disk**
   - Click **Continue**, save as `CertificateSigningRequest.certSigningRequest`

2. **Create APNs Certificate:**
   - Go to: https://developer.apple.com/account/resources/certificates/list
   - Click **+** button
   - Select: **Apple Push Notification service SSL (Sandbox & Production)**
   - Choose your App ID: `app.messageAI.messageAI`
   - Upload the CSR file
   - Download the certificate: `aps.cer`

3. **Convert to .p12:**
   ```bash
   # Double-click aps.cer to add to Keychain
   # Open Keychain Access
   # Find "Apple Push Services" certificate
   # Right-click → Export
   # Save as: messageai-push.p12
   # Set a password (remember this!)
   ```

</details>

---

## Part 2: Firebase Console Configuration

### Step 1: Upload APNs Key to Firebase

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/project/messagingai-75f21/settings/cloudmessaging
   - Navigate to: **Project Settings** → **Cloud Messaging** tab

2. **Scroll to Apple app configuration section**

3. **Upload APNs Authentication Key:**
   - Click **Upload** under "APNs Authentication Key"
   - Select your `AuthKey_XXXXXXXXXX.p8` file
   - Enter **Key ID** (from Apple Developer Portal)
   - Enter **Team ID** (from Apple Developer Portal)
   - Click **Upload**

4. **Verify Configuration:**
   - You should see: ✅ "APNs Authentication Key uploaded"

### Step 2: Verify iOS App Configuration

1. **In Firebase Console → Cloud Messaging:**
   - Verify your iOS app is registered
   - Bundle ID should be: `app.messageAI.messageAI`

2. **Check GoogleService-Info.plist:**
   ```bash
   # Verify file exists in your project
   ls -la messageAI/messageAI/GoogleService-Info.plist
   ```

   If missing:
   - Download from Firebase Console → Project Settings → Your apps
   - Add to Xcode project (drag into project navigator)

---

## Part 3: Xcode Project Configuration

### Step 1: Add Entitlements File

I've already created the entitlements file at:
```
messageAI/messageAI/messageAI.entitlements
```

Now add it to your Xcode project:

1. **Open Xcode:**
   ```bash
   open messageAI/messageAI.xcodeproj
   ```

2. **Add Entitlements File:**
   - In Xcode Project Navigator, right-click on `messageAI` folder
   - Select "Add Files to messageAI..."
   - Navigate to and select `messageAI.entitlements`
   - ✅ Check "Copy items if needed"
   - ✅ Check your target (messageAI)
   - Click **Add**

3. **Link Entitlements to Target:**
   - Select your project in Project Navigator
   - Select **messageAI** target
   - Go to **Build Settings** tab
   - Search for: "Code Signing Entitlements"
   - Set value to: `messageAI/messageAI.entitlements`

### Step 2: Enable Push Notifications Capability

1. **In Xcode:**
   - Select your project → Target: **messageAI**
   - Go to **Signing & Capabilities** tab

2. **Add Push Notifications:**
   - Click **+ Capability**
   - Search for and add: **Push Notifications**
   - You should see it listed under capabilities

3. **Add Background Modes:**
   - Click **+ Capability** again
   - Add: **Background Modes**
   - Enable: ✅ **Remote notifications**

### Step 3: Update Info.plist (If Needed)

Check if `Info.plist` has Firebase configuration:

```bash
# Check for Firebase app delegate swizzling
cat messageAI/messageAI/Info.plist | grep -A 1 "FirebaseAppDelegateProxyEnabled"
```

If not present, add to `Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

---

## Part 4: Deploy Cloud Functions

### Step 1: Verify Cloud Functions

Your Cloud Functions are already written in `backend/functions/index.js`.

**Key Function:**
- `sendMessageNotification` - Triggers when new message is created
- Sends push notification to all recipients
- Cleans up invalid FCM tokens

### Step 2: Deploy to Firebase

```bash
# Navigate to project root
cd /Users/yohanyi/Desktop/GauntletAI/02_messageAI

# Login to Firebase (if not already)
firebase login

# Deploy Cloud Functions
firebase deploy --only functions

# Expected output:
# ✔  functions[sendMessageNotification(us-central1)]: Successful create operation.
# ✔  functions[cleanupTypingIndicators(us-central1)]: Successful create operation.
# ✔  Deploy complete!
```

### Step 3: Verify Deployment

```bash
# List deployed functions
firebase functions:list

# Check function logs
firebase functions:log
```

---

## Part 5: Testing Push Notifications

### Test 1: Foreground Notifications (In-App)

1. **Build and Run on iOS Device:**
   ```bash
   # Must use real device, not simulator
   # Connect iPhone via USB
   ```

2. **In Xcode:**
   - Select your iPhone as destination
   - Product → Run (⌘R)

3. **Grant Notification Permission:**
   - App will request permission on first launch
   - Tap **Allow**

4. **Test In-App:**
   - Have a friend send you a message
   - Or use another device/account
   - **Expected:** Banner notification appears while app is open

### Test 2: Background Notifications (Push)

1. **Send a Test from Firebase Console:**
   - Go to: https://console.firebase.google.com/project/messagingai-75f21/notification
   - Click **Send your first message**
   - Notification title: "Test Notification"
   - Notification text: "Testing push notifications"
   - Under **Target**, select your iOS app
   - Click **Send test message**
   - Enter your FCM token (get from app logs)

2. **Get FCM Token from App:**
   ```swift
   // Already implemented in NotificationService.swift:247
   // Check Xcode console for:
   // 📱 FCM token received: <token>
   ```

3. **Test Real Message Flow:**
   - Close the app completely (swipe up in app switcher)
   - Have friend send message
   - **Expected:** Push notification appears on lock screen
   - Tap notification → App opens to that conversation

### Test 3: Verify Cloud Function Execution

```bash
# Watch function logs in real-time
firebase functions:log --only sendMessageNotification

# Send a message in the app
# You should see:
# 📬 New message created in conversation: xxx
# 👥 Notifying 1 recipient(s)
# 📤 Sending notifications to 1 device(s)
# ✅ Notification sent successfully
```

---

## Troubleshooting

### Problem: "No valid FCM tokens found"

**Cause:** FCM token not registered in Firestore

**Solution:**
1. Check `users/{userId}` document has `fcmToken` field
2. Verify `NotificationService.registerToken()` is called after login
3. Check Xcode console for: "✅ FCM token registered"

**Verify in Firebase Console:**
```
Firestore Database → users → {your-user-id} → fcmToken: "xxx"
```

### Problem: "APNs delivery failed"

**Cause:** APNs certificate/key not properly configured

**Solution:**
1. Verify APNs key uploaded in Firebase Console
2. Check Key ID and Team ID are correct
3. Ensure entitlements file is linked in Xcode
4. Rebuild app after adding entitlements

### Problem: Notifications work in foreground but not background

**Cause:** Background modes not enabled

**Solution:**
1. Xcode → Target → Signing & Capabilities
2. Add **Background Modes** capability
3. Enable ✅ **Remote notifications**
4. Rebuild and reinstall app

### Problem: "Error: Could not reach Cloud Messaging backend"

**Cause:** Internet connectivity or Firebase configuration

**Solution:**
1. Check device has internet connection
2. Verify `GoogleService-Info.plist` is in project
3. Check Firebase project settings match bundle ID
4. Try restarting app

### Problem: Cloud Function not triggering

**Cause:** Function not deployed or Firestore trigger not working

**Solution:**
```bash
# Check deployed functions
firebase functions:list

# Redeploy
firebase deploy --only functions

# Check function logs for errors
firebase functions:log
```

### Problem: Token registered but notifications still not received

**Cause:** APNs environment mismatch

**Solution:**
1. Development builds use **Sandbox** APNs
2. TestFlight/App Store use **Production** APNs
3. Verify entitlements file has correct environment:
   - Development: `<string>development</string>`
   - Production: `<string>production</string>`

---

## Production Checklist

Before releasing to App Store:

- [ ] Change entitlements environment to `production`
  ```xml
  <key>aps-environment</key>
  <string>production</string>
  ```

- [ ] Upload production APNs certificate/key to Firebase
- [ ] Test with TestFlight build
- [ ] Verify push notifications work on multiple devices
- [ ] Test notification permissions flow
- [ ] Test notification tap navigation
- [ ] Verify Cloud Functions are deployed
- [ ] Check Firebase billing plan (Spark vs Blaze)
- [ ] Monitor function execution logs
- [ ] Set up error alerting for failed notifications

---

## Quick Reference Commands

```bash
# Deploy Cloud Functions
firebase deploy --only functions

# Watch function logs
firebase functions:log --only sendMessageNotification

# Test Firestore rules
firebase emulators:start

# List active functions
firebase functions:list

# Delete a function
firebase functions:delete sendMessageNotification
```

---

## Architecture Overview

```
User sends message
    ↓
MessageService.sendMessage()
    ↓
Saves to Firestore: /conversations/{id}/messages/{msgId}
    ↓
Cloud Function Triggered: sendMessageNotification
    ↓
Function fetches conversation participants
    ↓
Function queries user FCM tokens
    ↓
Function sends to FCM
    ↓
FCM → APNs → User's iPhone
    ↓
If app in foreground:
    ├─ UNUserNotificationCenterDelegate.willPresent()
    └─ Shows banner notification
If app in background:
    └─ System shows notification on lock screen
User taps notification:
    ├─ UNUserNotificationCenterDelegate.didReceive()
    ├─ Posts to NotificationCenter
    ├─ ConversationsListView receives
    └─ Navigates to conversation
```

---

## Security Notes

### APNs Key Security
- ⚠️ **NEVER commit .p8 files to git**
- Store in secure location (1Password, etc.)
- One key per Apple Developer team
- Can be revoked in developer portal

### FCM Security
- Tokens are scoped to specific devices
- Invalid tokens automatically cleaned up by Cloud Function
- Tokens expire/refresh automatically
- Users can only receive notifications for their own conversations

### Firestore Rules
Ensure your `firestore.rules` properly secure the `fcmToken` field:
```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;

  // Only user can update their own FCM token
  allow update: if request.auth.uid == userId
                && request.resource.data.diff(resource.data).affectedKeys()
                   .hasOnly(['fcmToken', 'isOnline', 'lastSeen']);
}
```

---

## Monitoring & Analytics

### Firebase Console Dashboards

1. **Cloud Messaging:**
   - https://console.firebase.google.com/project/messagingai-75f21/notification
   - View sent notifications
   - Check delivery success/failure rates

2. **Cloud Functions:**
   - https://console.firebase.google.com/project/messagingai-75f21/functions
   - Monitor function executions
   - View error rates and latency

3. **Crashlytics (Optional):**
   - Add Firebase Crashlytics to catch notification-related crashes
   - Track notification tap conversion rates

### Metrics to Monitor

- FCM token registration success rate
- Push notification delivery rate
- Notification tap-through rate
- Cloud Function execution time
- Failed token cleanup frequency

---

## Next Steps

1. ✅ **Complete this setup guide**
2. 🔄 **Deploy Cloud Functions**
3. 📱 **Test on real iOS device**
4. ✅ **Verify all notification flows work**
5. 📊 **Monitor for one week**
6. 🚀 **Deploy to TestFlight**
7. 🎯 **Gather user feedback**
8. 🏆 **Release to App Store**

---

## Support Resources

- **Firebase Documentation:** https://firebase.google.com/docs/cloud-messaging/ios/client
- **APNs Documentation:** https://developer.apple.com/documentation/usernotifications
- **Firebase Support:** https://firebase.google.com/support
- **Stack Overflow:** Tag questions with `firebase-cloud-messaging` and `ios`

---

## Changelog

**2025-10-23:**
- Initial setup guide created
- Cloud Functions dependencies installed
- Entitlements file created
- Ready for deployment

---

**Need Help?** Check the troubleshooting section or Firebase documentation.

**Ready to Deploy?** Follow Part 4 to deploy your Cloud Functions!
