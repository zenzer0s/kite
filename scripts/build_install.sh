#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Release Build for arm64-v8a..."

# Run the build
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    echo "✅ Build successful! Path: $APK_PATH"
    
    # Check if a device is connected
    DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device" | wc -l)
    
    if [ "$DEVICE_COUNT" -gt 0 ]; then
        echo "📲 Installing to device..."
        adb install -r "$APK_PATH"
        echo "✨ Installation complete! Launching app..."
        adb shell am start -n com.zenzer0s.kite/com.zenzer0s.kite.MainActivity
    else
        echo "❌ No Android device found via ADB. Please connect a device to install."
    fi
else
    echo "❌ APK not found at $APK_PATH. Build might have failed."
    exit 1
fi
