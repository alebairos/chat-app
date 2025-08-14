#!/bin/bash
# Simple IPA builder for direct installation

set -e

echo "🏗️  Building simple IPA for direct installation..."

# Clean and build
flutter clean
flutter pub get

# Build archive
echo "📱 Building iOS archive..."
flutter build ios --release --no-codesign

# Archive with Xcode
echo "📦 Creating Xcode archive..."
xcodebuild -workspace ios/Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -destination generic/platform=iOS \
           -archivePath build/ios/archive/Runner.xcarchive \
           archive

# Export IPA for development/ad-hoc distribution
echo "📤 Exporting IPA..."
xcodebuild -exportArchive \
           -archivePath build/ios/archive/Runner.xcarchive \
           -exportPath build/ios/ipa \
           -exportOptionsPlist scripts/ExportOptions-AdHoc.plist

echo "✅ IPA built successfully!"
echo "📁 Location: build/ios/ipa/Runner.ipa"
echo ""
echo "📋 Installation options:"
echo "   1. Install via Xcode Devices window"
echo "   2. Use Apple Configurator 2"  
echo "   3. Use third-party tools like 3uTools"
echo "   4. Upload to Diawi.com for easy team distribution"
