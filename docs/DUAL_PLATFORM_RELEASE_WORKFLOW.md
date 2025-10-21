# Dual-Platform Release Workflow

Complete guide for releasing iOS and Android builds from the `develop` branch.

## Overview

This project uses a protected branch workflow:
- **`develop`**: Active development and release branch
- **`main`**: Stable production branch (optional merge after release)
- **iOS**: TestFlight via automated script
- **Android**: Firebase App Distribution via Makefile

---

## Prerequisites

### iOS (TestFlight)
- ✅ Apple Developer account active
- ✅ Xcode 16.2+ installed
- ✅ `.env` file with Apple credentials configured
- ✅ Certificates and provisioning profiles valid

### Android (Firebase App Distribution)
- ✅ Firebase CLI installed: `npm install -g firebase-tools`
- ✅ Logged in: `firebase login`
- ✅ Tester group `internal-testers` created in Firebase Console
- ✅ `.firebaserc` and `firebase.json` configured

### General
- ✅ Clean working directory (no uncommitted changes)
- ✅ On `develop` branch
- ✅ All tests passing: `flutter test`

---

## Release Process

### Step 1: Prepare for Release

```bash
# Ensure you're on develop branch
git checkout develop

# Pull latest changes
git pull origin develop

# Verify working directory is clean
git status

# Run tests to ensure everything works
flutter test

# If there are uncommitted changes, commit them first
git add .
git commit -m "chore: Pre-release cleanup"
```

---

### Step 2: iOS Release (TestFlight)

**Automated Release with Version Bumping:**

```bash
# For bug fixes (2.1.0 → 2.1.1)
python3 scripts/release_testflight.py --version-bump patch

# For new features (2.1.0 → 2.2.0)
python3 scripts/release_testflight.py --version-bump minor

# For breaking changes (2.1.0 → 3.0.0)
python3 scripts/release_testflight.py --version-bump major
```

**What the script does automatically:**
1. ✅ Validates you're on `develop` branch
2. ✅ Checks working directory is clean
3. ✅ Bumps version in `pubspec.yaml`
4. ✅ Updates `CHANGELOG.md` with release notes
5. ✅ Commits version changes to git
6. ✅ Creates git tag (e.g., `v2.1.1`)
7. ✅ Builds Flutter app for iOS
8. ✅ Creates Xcode archive
9. ✅ Exports IPA for App Store
10. ✅ Uploads to TestFlight

**Preview before executing (dry run):**
```bash
python3 scripts/release_testflight.py --dry-run --version-bump patch
```

**Emergency releases (bypass branch validation):**
```bash
python3 scripts/release_testflight.py --force-branch --version-bump patch
```

**Verify setup:**
```bash
python3 scripts/release_testflight.py --verify
```

---

### Step 3: Android Release (Firebase App Distribution)

**One-Command Distribution:**

```bash
make distribute-android
```

**What happens:**
1. Prompts for release notes (type and press `Ctrl+D` when done)
2. Applies Android namespace patches automatically
3. Builds release APK (~2-3 minutes)
4. Uploads to Firebase App Distribution
5. Sends email notifications to testers

**Manual Distribution (if needed):**

```bash
# 1. Apply Android patches
./scripts/patch_android_namespaces.sh

# 2. Build release APK
flutter build apk --release

# 3. Distribute to Firebase
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app "1:807856535419:android:39a9db3b2fa8c010d52fde" \
  --groups "internal-testers" \
  --release-notes "Your release notes here"
```

---

### Step 4: Push Changes to Remote

After both releases are complete:

```bash
# Push develop branch with new version tags
git push origin develop

# Push tags
git push origin --tags
```

---

### Step 5: Notify Testers

**iOS (TestFlight):**
- Testers automatically receive push notification via TestFlight app
- Email notification: "New build available for testing"
- Testers can install directly from TestFlight app

**Android (Firebase App Distribution):**
- Testers receive email: "New build available: AI Personas App"
- Email contains download link
- Testers download APK and install (requires "Unknown Sources" enabled)

---

## Version Numbering Strategy

Follow semantic versioning: `MAJOR.MINOR.PATCH`

- **PATCH** (`--version-bump patch`): Bug fixes, minor improvements
  - Example: `2.1.0` → `2.1.1`
  - Use for: Hotfixes, performance improvements, small UI tweaks

- **MINOR** (`--version-bump minor`): New features, non-breaking changes
  - Example: `2.1.0` → `2.2.0`
  - Use for: New features, significant improvements, new personas

- **MAJOR** (`--version-bump major`): Breaking changes, major releases
  - Example: `2.1.0` → `3.0.0`
  - Use for: Complete redesigns, breaking API changes, platform expansion

**Build Numbers:**
- Automatically incremented by iOS script
- Shared between iOS and Android in `pubspec.yaml`
- Format: `version: 2.1.0+42` (version+build)

---

## Complete Release Example

Here's a complete release workflow for a minor version bump:

```bash
# 1. Prepare
git checkout develop
git pull origin develop
git status  # Should be clean
flutter test  # Should pass

# 2. iOS Release (creates v2.2.0 tag and commits)
python3 scripts/release_testflight.py --version-bump minor
# Enter release notes when prompted
# Wait for build and upload (~5-10 minutes)

# 3. Android Release (uses same version from pubspec.yaml)
make distribute-android
# Enter release notes when prompted (can be same as iOS)
# Wait for build and upload (~2-3 minutes)

# 4. Push everything
git push origin develop
git push origin --tags

# 5. Verify
# - Check TestFlight: https://appstoreconnect.apple.com
# - Check Firebase: https://console.firebase.google.com/project/ai-personas-app/appdistribution
```

---

## Troubleshooting

### iOS Issues

**"Release must be from 'develop' branch"**
```bash
git checkout develop
# or use --force-branch for emergencies
```

**"Working directory has uncommitted changes"**
```bash
git add . && git commit -m "Pre-release changes"
# or
git stash
```

**TestFlight upload fails**
```bash
# Verify setup
python3 scripts/release_testflight.py --verify

# Check certificates
open ~/Library/MobileDevice/Provisioning\ Profiles/

# Check Apple Developer account status
```

### Android Issues

**"Namespace not specified" error**
```bash
# Solution: Always use make deps
make deps
```

**"resource android:attr/lStar not found"**
```bash
# Clean and rebuild
flutter clean
make build-android-release
```

**Firebase distribution fails**
```bash
# Check login
firebase login

# Check project
firebase projects:list

# Check tester group exists in Firebase Console
```

### Version Conflicts

**iOS and Android versions out of sync**
- Both platforms read from `pubspec.yaml`
- iOS script updates version automatically
- Android uses the updated version from iOS release
- **Solution**: Always run iOS release first (it updates `pubspec.yaml`)

---

## Best Practices

1. **Always release from `develop`**: Ensures consistency and traceability
2. **Run iOS first**: The script updates `pubspec.yaml` version
3. **Use same release notes**: Keep messaging consistent across platforms
4. **Test before release**: Run `flutter test` to catch issues early
5. **Clean working directory**: Commit or stash changes before releasing
6. **Verify uploads**: Check both TestFlight and Firebase consoles
7. **Tag releases**: Git tags are created automatically by iOS script
8. **Document changes**: Update `CHANGELOG.md` (iOS script does this)

---

## Quick Reference

### iOS Commands
```bash
# Bug fix release
python3 scripts/release_testflight.py --version-bump patch

# Feature release
python3 scripts/release_testflight.py --version-bump minor

# Major release
python3 scripts/release_testflight.py --version-bump major

# Dry run (preview)
python3 scripts/release_testflight.py --dry-run --version-bump patch

# Verify setup
python3 scripts/release_testflight.py --verify
```

### Android Commands
```bash
# One-command distribution
make distribute-android

# Manual build
flutter build apk --release

# Manual distribution
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app "1:807856535419:android:39a9db3b2fa8c010d52fde" \
  --groups "internal-testers"
```

### Git Commands
```bash
# Prepare
git checkout develop
git pull origin develop

# After release
git push origin develop
git push origin --tags

# View tags
git tag -l
```

---

## Monitoring

### iOS (TestFlight)
- **Console**: https://appstoreconnect.apple.com
- **Section**: TestFlight → Builds
- **Metrics**: Install rate, crash reports, feedback

### Android (Firebase App Distribution)
- **Console**: https://console.firebase.google.com/project/ai-personas-app/appdistribution
- **Section**: App Distribution → Releases
- **Metrics**: Download count, tester feedback

---

## Support

- **iOS Issues**: See `docs/features/ft_214_protected_branch_release_workflow.md`
- **Android Issues**: See `docs/features/ft_212_android_build_support.md`
- **Firebase Setup**: See `docs/features/ft_213_firebase_setup_guide.md`
- **General Help**: `make help`

