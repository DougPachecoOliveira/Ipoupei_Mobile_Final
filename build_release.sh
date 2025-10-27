#!/bin/bash

echo "🚀 Building iOS Release with icon tree shaking disabled..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for iOS release with no tree shake icons
flutter build ios --release --no-tree-shake-icons

echo "✅ Build completed! You can now archive in Xcode."
echo "📱 Open Xcode: open ios/Runner.xcworkspace"