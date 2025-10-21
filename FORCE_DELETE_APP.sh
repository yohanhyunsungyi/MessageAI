#!/bin/bash

echo "🔥 FORCE DELETE APP FROM SIMULATOR"
echo "===================================="

# Find all booted simulators
BOOTED_DEVICES=$(xcrun simctl list devices | grep Booted | grep -o '[A-F0-9\-]\{36\}')

if [ -z "$BOOTED_DEVICES" ]; then
    echo "No booted simulators found. Starting iPhone 16..."
    xcrun simctl boot "iPhone 16"
    sleep 2
    BOOTED_DEVICES=$(xcrun simctl list devices | grep Booted | grep -o '[A-F0-9\-]\{36\}')
fi

echo "Booted devices: $BOOTED_DEVICES"

for DEVICE in $BOOTED_DEVICES; do
    echo ""
    echo "📱 Device: $DEVICE"
    echo "   Uninstalling app.messageAI.messageAI..."
    xcrun simctl uninstall "$DEVICE" app.messageAI.messageAI 2>&1 || echo "   App not found on this device"
    
    echo "   Uninstalling com.yohanyi.messageAI..."
    xcrun simctl uninstall "$DEVICE" com.yohanyi.messageAI 2>&1 || echo "   App not found on this device"
done

echo ""
echo "✅ App deleted from all booted simulators!"
echo ""
echo "🔄 Now do this:"
echo "   1. Stop the app in Xcode (⌘.)"
echo "   2. Clean Build Folder in Xcode (⇧⌘K)"
echo "   3. Build and Run (⌘R)"
echo ""
echo "✨ The app will launch with IN-MEMORY storage (no crashes!)"
