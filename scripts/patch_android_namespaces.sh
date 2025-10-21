#!/bin/bash
# FT-212: Temporary patch for Android namespace issues
# This script adds namespace declarations to plugins that lack them

set -e

echo "🔧 Patching Android plugins for namespace compatibility..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to patch a plugin
patch_plugin() {
    local plugin_path=$1
    local namespace=$2
    local line_number=$3
    
    if [ -f "$plugin_path/android/build.gradle" ]; then
        # Check if namespace already exists
        if grep -q "namespace" "$plugin_path/android/build.gradle"; then
            echo -e "${GREEN}✓${NC} $plugin_path already has namespace"
            return 0
        fi
        
        # Create backup
        cp "$plugin_path/android/build.gradle" "$plugin_path/android/build.gradle.backup"
        
        # Add namespace after 'android {' line
        sed -i '' "${line_number}a\\
    namespace \"$namespace\"
" "$plugin_path/android/build.gradle"
        
        echo -e "${GREEN}✓${NC} Patched $plugin_path"
        return 0
    else
        echo -e "${RED}✗${NC} Plugin not found: $plugin_path"
        return 1
    fi
}

# Get pub cache directory
PUB_CACHE="${HOME}/.pub-cache/hosted/pub.dev"

echo ""
echo "📦 Patching Isar Flutter Libs..."
patch_plugin "$PUB_CACHE/isar_flutter_libs-3.1.0+1" "dev.isar.isar_flutter_libs" "24"

echo ""
echo "📦 Patching Record Plugin..."
patch_plugin "$PUB_CACHE/record-4.4.4" "com.llfbandit.record" "25"

echo ""
echo -e "${YELLOW}⚠️  Note: These patches are temporary and will be lost if you run 'flutter pub get'${NC}"
echo -e "${YELLOW}⚠️  For a permanent solution, see: docs/features/ft_212_android_namespace_fix_investigation.md${NC}"
echo ""
echo -e "${GREEN}✅ Patching complete! You can now run: flutter build apk --debug${NC}"

