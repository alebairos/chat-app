#!/bin/bash
# FT-213: Firebase App Distribution for Android
# Similar to release_testflight.py but for Android

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Firebase App Distribution - Android${NC}"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found. Install with: npm install -g firebase-tools${NC}"
    exit 1
fi

# Check if logged in
if ! firebase projects:list &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Firebase. Run: firebase login${NC}"
    exit 1
fi

# Get version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
BUILD_NUMBER=$(grep "^version:" pubspec.yaml | sed 's/.*+//')

# Get Git metadata
GIT_HASH=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
GIT_SHORT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
BUILD_DATE=$(date '+%Y-%m-%d %H:%M')

echo -e "${BLUE}📦 Version: ${VERSION} (Build ${BUILD_NUMBER})${NC}"
echo -e "${BLUE}📋 Git: ${GIT_SHORT_HASH} @ ${GIT_BRANCH}${NC}"
if [ -n "$GIT_TAG" ]; then
    echo -e "${BLUE}🏷️  Tag: ${GIT_TAG}${NC}"
fi
echo ""

# Prompt for release notes
echo -e "${YELLOW}📝 Enter release notes (press Ctrl+D when done):${NC}"
USER_NOTES=$(cat)

if [ -z "$USER_NOTES" ]; then
    USER_NOTES="Android release v${VERSION} (${BUILD_NUMBER})"
fi

# Append Git metadata to release notes
TAG_INFO=""
if [ -n "$GIT_TAG" ]; then
    TAG_INFO=" (${GIT_TAG})"
fi

RELEASE_NOTES="${USER_NOTES}

---
Build Info:
Version ${VERSION} (Build ${BUILD_NUMBER})${TAG_INFO}
Git: ${GIT_SHORT_HASH} @ ${GIT_BRANCH}
Released: ${BUILD_DATE}"

# Save release notes to file
echo "$RELEASE_NOTES" > RELEASE_NOTES.txt
echo -e "${GREEN}✓ Release notes saved with Git metadata${NC}"
echo ""

# Apply Android namespace patches
echo -e "${BLUE}🔧 Applying Android namespace patches...${NC}"
./scripts/patch_android_namespaces.sh
echo ""

# Build release APK
echo -e "${BLUE}🏗️  Building release APK...${NC}"
flutter build apk --release

if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo -e "${RED}❌ Build failed - APK not found${NC}"
    exit 1
fi

APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
echo -e "${GREEN}✓ Build complete: ${APK_SIZE}${NC}"
echo ""

# Distribute via Firebase
echo -e "${BLUE}📤 Distributing to Firebase App Distribution...${NC}"
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app "1:807856535419:android:39a9db3b2fa8c010d52fde" \
  --groups "internal-testers" \
  --release-notes-file RELEASE_NOTES.txt

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Distribution successful!${NC}"
    echo -e "${GREEN}   Version: ${VERSION} (${BUILD_NUMBER})${TAG_INFO}${NC}"
    echo -e "${GREEN}   Git: ${GIT_SHORT_HASH} @ ${GIT_BRANCH}${NC}"
    echo -e "${GREEN}   APK Size: ${APK_SIZE}${NC}"
    echo -e "${GREEN}   Testers will receive email notifications${NC}"
    echo ""
    echo -e "${BLUE}📊 View distribution: https://console.firebase.google.com/project/ai-personas-app/appdistribution${NC}"
    echo ""
    echo -e "${BLUE}📝 Git metadata included in release notes:${NC}"
    echo -e "${BLUE}   Commit: ${GIT_HASH}${NC}"
    echo -e "${BLUE}   Short: ${GIT_SHORT_HASH}${NC}"
    echo -e "${BLUE}   Branch: ${GIT_BRANCH}${NC}"
else
    echo -e "${RED}❌ Distribution failed${NC}"
    exit 1
fi

# Clean up
rm -f RELEASE_NOTES.txt

