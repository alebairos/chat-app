# Release Quick Start Guide

**TL;DR**: Complete dual-platform release in 5 commands.

## Prerequisites Check

```bash
✅ git checkout develop && git pull
✅ git status  # Should be clean
✅ flutter test  # Should pass
✅ firebase login  # For Android
```

---

## Release Commands

### 1️⃣ iOS Release (TestFlight)

```bash
# Choose one based on release type:
python3 scripts/release_testflight.py --version-bump patch   # Bug fixes
python3 scripts/release_testflight.py --version-bump minor   # New features
python3 scripts/release_testflight.py --version-bump major   # Breaking changes
```

**What it does:**
- Updates version in `pubspec.yaml`
- Creates git tag
- Builds and uploads to TestFlight
- Updates `CHANGELOG.md`

---

### 2️⃣ Android Release (Firebase)

```bash
make distribute-android
```

**What it does:**
- Prompts for release notes (type, then press `Ctrl+D`)
- Patches Android plugins
- Builds release APK
- Uploads to Firebase App Distribution

---

### 3️⃣ Push Changes

```bash
git push origin develop
git push origin --tags
```

---

## Complete Example

```bash
# Prepare
git checkout develop && git pull origin develop

# iOS (creates v2.2.0)
python3 scripts/release_testflight.py --version-bump minor

# Android (uses v2.2.0 from pubspec.yaml)
make distribute-android

# Push
git push origin develop && git push origin --tags
```

**Time estimate:** 10-15 minutes total
- iOS: ~5-10 minutes
- Android: ~2-3 minutes
- Push: ~30 seconds

---

## Version Bump Guide

| Type | Command | Example | Use For |
|------|---------|---------|---------|
| **Patch** | `--version-bump patch` | 2.1.0 → 2.1.1 | Bug fixes, hotfixes |
| **Minor** | `--version-bump minor` | 2.1.0 → 2.2.0 | New features |
| **Major** | `--version-bump major` | 2.1.0 → 3.0.0 | Breaking changes |

---

## Troubleshooting

### iOS Fails
```bash
# Verify setup
python3 scripts/release_testflight.py --verify

# Wrong branch?
git checkout develop

# Uncommitted changes?
git add . && git commit -m "Pre-release"
```

### Android Fails
```bash
# Not logged in?
firebase login

# Build issues?
flutter clean && make deps

# Namespace errors?
./scripts/patch_android_namespaces.sh
```

---

## Monitoring

- **iOS**: https://appstoreconnect.apple.com
- **Android**: https://console.firebase.google.com/project/ai-personas-app/appdistribution

---

## Full Documentation

See `docs/DUAL_PLATFORM_RELEASE_WORKFLOW.md` for complete details.

