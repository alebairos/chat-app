#!/bin/bash
# Wrapper for flutter pub get that auto-patches Android namespaces

set -e

echo "📦 Running flutter pub get..."
flutter pub get

echo ""
echo "🔧 Applying Android namespace patches..."
./scripts/patch_android_namespaces.sh

echo ""
echo "✅ Dependencies updated and Android patches applied!"

