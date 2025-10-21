#!/bin/bash

echo "🧹 COMPLETE APP & SIMULATOR RESET"
echo "================================="

# Kill all simulators
echo "1️⃣ Killing all simulators..."
killall Simulator 2>/dev/null || echo "   No simulators running"

# Kill Xcode
echo "2️⃣ Killing Xcode..."
killall Xcode 2>/dev/null || echo "   Xcode not running"

# Clean build
echo "3️⃣ Cleaning build folder..."
cd /Users/yohanyi/Desktop/GauntletAI/02_messageAI/messageAI
xcodebuild clean -project messageAI.xcodeproj -scheme messageAI

# Delete derived data
echo "4️⃣ Deleting DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/messageAI-*

# Erase all simulators
echo "5️⃣ Erasing all simulators..."
xcrun simctl shutdown all
xcrun simctl erase all

# Delete app from simulator
echo "6️⃣ Uninstalling app..."
xcrun simctl uninstall booted com.yohanyi.messageAI 2>/dev/null || echo "   App not installed"

echo ""
echo "✅ COMPLETE RESET DONE!"
echo ""
echo "📱 Now run the app from Xcode with a FRESH start"
echo "   It should work without crashes!"

