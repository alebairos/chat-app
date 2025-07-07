#!/bin/bash

# Build script for creating a standalone iOS demo build
# This creates an IPA file that can be installed on devices without Xcode

set -e  # Exit on any error

echo "🚀 Building Character AI Clone for Demo..."
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Error: Flutter is not installed or not in PATH.${NC}"
    exit 1
fi

# Check Flutter doctor
echo -e "${BLUE}🔍 Checking Flutter environment...${NC}"
flutter doctor --no-version-check

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Build iOS release
echo -e "${BLUE}📱 Building iOS release build...${NC}"
flutter build ios --release --no-codesign

# Create build directory
BUILD_DIR="build/demo"
mkdir -p "$BUILD_DIR"

# Create IPA using xcrun (requires Xcode Command Line Tools)
echo -e "${BLUE}📦 Creating IPA file...${NC}"
cd ios

# Archive the app
echo -e "${YELLOW}⚙️  Creating archive...${NC}"
xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -destination generic/platform=iOS \
    -archivePath "../$BUILD_DIR/Runner.xcarchive" \
    archive

# Export IPA
echo -e "${YELLOW}⚙️  Exporting IPA...${NC}"
cat > "../$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>REPLACE_WITH_YOUR_TEAM_ID</string>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "../$BUILD_DIR/Runner.xcarchive" \
    -exportPath "../$BUILD_DIR" \
    -exportOptionsPlist "../$BUILD_DIR/ExportOptions.plist"

cd ..

# Check if IPA was created
if [ -f "$BUILD_DIR/Runner.ipa" ]; then
    echo -e "${GREEN}✅ Success! IPA created at: $BUILD_DIR/Runner.ipa${NC}"
    echo -e "${GREEN}📱 File size: $(du -h "$BUILD_DIR/Runner.ipa" | cut -f1)${NC}"
    
    # Show installation instructions
    echo ""
    echo -e "${BLUE}📋 Installation Instructions:${NC}"
    echo "1. Connect your iPhone to your Mac"
    echo "2. Open Finder and select your iPhone"
    echo "3. Drag and drop the Runner.ipa file to your iPhone"
    echo "4. Or use: xcrun devicectl device install app --device <device-id> $BUILD_DIR/Runner.ipa"
    echo ""
    echo -e "${YELLOW}💡 Alternative methods:${NC}"
    echo "• Use Apple Configurator 2 to install the IPA"
    echo "• Upload to TestFlight for easier distribution"
    echo "• Use 3uTools or similar third-party tools"
    
else
    echo -e "${RED}❌ Error: IPA file was not created${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Demo build completed successfully!${NC}" 