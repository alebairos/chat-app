#!/bin/bash

# Quick install script for demo purposes
# Builds and installs directly to connected iPhone

set -e

echo "📱 Quick Install to iPhone"
echo "========================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Clean and build
echo -e "${BLUE}🧹 Preparing build...${NC}"
flutter clean
flutter pub get

# Check for connected devices
echo -e "${BLUE}🔍 Checking for connected devices...${NC}"
flutter devices

# Build and install release version
echo -e "${BLUE}📱 Building and installing release version...${NC}"
flutter build ios --release

echo -e "${YELLOW}⚙️  Installing to device...${NC}"
flutter install --release

echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${GREEN}🎉 The app should now be on your iPhone home screen${NC}"
echo ""
echo -e "${YELLOW}💡 Note: You may need to trust the developer certificate in:${NC}"
echo "Settings > General > VPN & Device Management > Developer App" 