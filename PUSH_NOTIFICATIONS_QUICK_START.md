# Push Notifications - Quick Start

## 5-Minute Setup Checklist

### 1. Apple Developer Portal (5 min)
```
□ Go to: https://developer.apple.com/account/resources/authkeys/list
□ Create new key: "MessageAI Push Notifications"
□ Enable: Apple Push Notifications service (APNs)
□ Download: AuthKey_XXXXXXXXXX.p8
□ Save: Key ID (10 chars) and Team ID (10 chars)
```

### 2. Firebase Console (3 min)
```
□ Go to: https://console.firebase.google.com/project/messagingai-75f21/settings/cloudmessaging
□ Click: Upload APNs Authentication Key
□ Upload: AuthKey_XXXXXXXXXX.p8
□ Enter: Key ID and Team ID
□ Verify: ✅ "APNs Authentication Key uploaded"
```

### 3. Xcode Configuration (3 min)
```
□ Open Xcode: messageAI.xcodeproj
□ Add file: messageAI.entitlements (already created for you)
□ Target → Signing & Capabilities → Add: Push Notifications
□ Target → Signing & Capabilities → Add: Background Modes
□ Enable: Remote notifications
```

### 4. Deploy Cloud Functions (2 min)
```bash
cd /Users/yohanyi/Desktop/GauntletAI/02_messageAI
firebase login
firebase deploy --only functions
```

### 5. Test (5 min)
```
□ Build on real iOS device (not simulator!)
□ Grant notification permission
□ Send message from another account
□ Verify: Notification appears
□ Tap notification
□ Verify: App opens to conversation
```

---

## Already Done For You ✅

- ✅ NotificationService.swift - Complete implementation
- ✅ Cloud Functions - Written and ready to deploy
- ✅ FCM token registration - Auto-registers on login
- ✅ Foreground notifications - Shows banners when app is open
- ✅ Navigation handling - Tapping notifications opens conversations
- ✅ Dependencies installed - Firebase packages ready
- ✅ Entitlements file - Created at messageAI/messageAI/messageAI.entitlements

---

## Quick Commands

```bash
# Deploy functions
firebase deploy --only functions

# Watch logs
firebase functions:log --only sendMessageNotification

# Test notification from Firebase Console
# https://console.firebase.google.com/project/messagingai-75f21/notification
```

---

## Common Issues & Quick Fixes

**Problem:** No notifications appearing
**Fix:** Check FCM token is saved in Firestore users/{userId}/fcmToken

**Problem:** Notifications work in foreground, not background
**Fix:** Enable Background Modes → Remote notifications in Xcode

**Problem:** Cloud Function not deploying
**Fix:** `firebase login` then retry deploy

**Problem:** APNs error
**Fix:** Verify Key ID and Team ID match Apple Developer Portal

---

## Test Checklist

- [ ] Foreground notification (app open)
- [ ] Background notification (app closed)
- [ ] Tap notification navigates to chat
- [ ] Multiple notifications (different chats)
- [ ] No notification when viewing that chat

---

## Full Documentation

See `PUSH_NOTIFICATIONS_SETUP.md` for complete details.

---

## Need Help?

1. Check PUSH_NOTIFICATIONS_SETUP.md troubleshooting section
2. View function logs: `firebase functions:log`
3. Verify FCM token in Firestore Database
4. Check Xcode console for error messages
