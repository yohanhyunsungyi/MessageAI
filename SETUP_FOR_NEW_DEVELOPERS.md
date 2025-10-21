# Setup Guide for New Developers

This guide will help new developers get the MessageAI project running on their local machine.

## 🚨 Important: Missing GoogleService-Info.plist

**The repository does NOT include `GoogleService-Info.plist` for security reasons.**

You need to obtain this file before the app will work. Follow the instructions below.

---

## Prerequisites

1. **macOS** with Xcode 16.0+
2. **Firebase account** with access to project `messagingai-75f21`
3. **Git** installed
4. **Firebase CLI** (optional, for emulators)

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/yohanhyunsungyi/MessageAI.git
cd MessageAI
```

---

## Step 2: Get GoogleService-Info.plist

### Option A: From Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/project/messagingai-75f21)
2. Click on Project Settings (gear icon)
3. Scroll down to "Your apps"
4. Find the iOS app with bundle ID: `app.messageAI.messageAI`
5. Click "Download GoogleService-Info.plist"
6. Save the file

### Option B: From Project Owner

Contact the project owner to share the `GoogleService-Info.plist` file securely.

---

## Step 3: Add GoogleService-Info.plist to Project

```bash
# Copy the downloaded file to the correct location
cp ~/Downloads/GoogleService-Info.plist messageAI/messageAI/GoogleService-Info.plist
```

**Important:** The file should be at: `messageAI/messageAI/GoogleService-Info.plist`

---

## Step 4: Open in Xcode

```bash
open messageAI/messageAI.xcodeproj
```

In Xcode:
1. Select your Development Team in Signing & Capabilities
2. Build the project (⌘B)
3. Run on simulator (⌘R)

---

## Step 5: Verify Setup

### Build Success
- The app should compile without errors
- You should see "BUILD SUCCEEDED" in Xcode

### Firebase Connection
- Check Xcode console for: "✅ Firebase configured"
- No error messages about missing GoogleService-Info.plist

---

## Optional: Firebase Emulators for Testing

If you want to run integration tests:

### Install Firebase CLI

```bash
npm install -g firebase-tools
```

### Login to Firebase

```bash
firebase login
```

### Start Emulators

```bash
cd MessageAI
firebase emulators:start
```

**Emulator URLs:**
- Auth: `http://localhost:9099`
- Firestore: `http://localhost:8080`
- UI: `http://localhost:4000`

See [TESTING_NOTES.md](TESTING_NOTES.md) for detailed testing instructions.

---

## Troubleshooting

### Issue: "GoogleService-Info.plist not found"

**Solution:**
1. Verify file is at: `messageAI/messageAI/GoogleService-Info.plist`
2. In Xcode, check File Inspector (⌥⌘1)
3. Make sure "Target Membership" includes `messageAI`

### Issue: "Bundle ID mismatch"

**Solution:**
- Bundle ID in Xcode must be: `app.messageAI.messageAI`
- Bundle ID in GoogleService-Info.plist must match

### Issue: "No such module 'FirebaseCore'"

**Solution:**
1. File → Packages → Resolve Package Versions
2. Clean build folder: Shift + ⌘K
3. Build again: ⌘B

### Issue: Build fails with "Multiple commands produce Info.plist"

**Solution:**
- This should be fixed in the project
- If it happens, check Build Phases → Copy Bundle Resources
- Remove Info.plist if present there

---

## Project Structure

```
MessageAI/
├── messageAI/
│   ├── messageAI.xcodeproj
│   └── messageAI/
│       ├── messageAIApp.swift       # App entry point
│       ├── GoogleService-Info.plist # ⚠️ YOU NEED TO ADD THIS
│       └── Info.plist               # App configuration
├── firebase.json                     # Firebase configuration
├── firestore.rules                   # Security rules
└── README.md                         # Main documentation
```

---

## Next Steps

1. ✅ Verify build succeeds
2. ✅ Run app on simulator
3. ✅ Try signing up with email
4. ✅ Check Firebase Console for new user
5. 📚 Read [PRD.md](PRD.md) for features overview
6. 📚 Read [Architecture.md](Architecture.md) for system design
7. 📚 Read [Tasks.md](Tasks.md) for development roadmap

---

## Need Help?

- Check [README.md](README.md) for general information
- Check [TESTING_NOTES.md](TESTING_NOTES.md) for testing
- Open an issue on GitHub
- Contact project owner

---

## Security Note

**Never commit GoogleService-Info.plist to git!**

This file contains:
- API keys
- Project IDs
- OAuth client IDs
- Other sensitive information

It's in `.gitignore` to prevent accidental commits.

---

**Last Updated:** October 20, 2025  
**Status:** Initial setup guide created

