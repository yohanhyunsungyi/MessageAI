#!/bin/bash

echo "🔄 Resetting iOS Simulator Data..."

# Get the bundle ID
BUNDLE_ID="com.yohanyi.messageAI"

# Kill simulator
xcrun simctl shutdown all

# Uninstall app
xcrun simctl uninstall booted "$BUNDLE_ID" 2>/dev/null || echo "App not installed yet"

# Erase all content
echo "Erasing simulator..."
xcrun simctl erase all

echo "✅ Simulator reset complete!"
echo "📱 Now run the app from Xcode"
