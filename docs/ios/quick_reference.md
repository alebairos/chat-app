# iOS TestFlight - Quick Reference

## 🚀 Quick Release Commands

```bash
# 1. Open Xcode
open ios/Runner.xcworkspace

# 2. Check certificates
security find-identity -v -p codesigning

# 3. Verify version
grep "version:" pubspec.yaml

# 4. Clean build (if needed)
flutter clean && flutter pub get
```

## 📋 Xcode Checklist

### Before Archive:
- [ ] **Destination**: "Any iOS Device (arm64)"
- [ ] **Signing**: Automatically manage signing ✅
- [ ] **Team**: 2MMHAK3LLN selected
- [ ] **Bundle ID**: com.lyfeab.chatapp
- [ ] **Build**: Product → Build (⌘B) succeeds

### Archive Process:
- [ ] **Product** → **Archive**
- [ ] **Organizer** opens automatically
- [ ] **Distribute App** → **App Store Connect** → **Upload**

## ⚡ Emergency Commands

```bash
# Fix build issues
flutter clean
flutter pub get
flutter build ios --release --no-pub

# Check bundle ID consistency
grep -r "com.lyfeab.chatapp" ios/

# Bump version quickly
# Edit pubspec.yaml: version: 1.1.0+11
```

## 🔍 Verification

```bash
# After upload, check App Store Connect:
# https://appstoreconnect.apple.com
# My Apps → AI Personas App → TestFlight
```

## 📱 Current Config

- **Bundle ID**: `com.lyfeab.chatapp`
- **App Name**: "AI Personas App"
- **Team**: `2MMHAK3LLN`
- **Current Version**: `1.1.0+10`
