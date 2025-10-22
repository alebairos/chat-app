# AI Chat App

A Flutter chat app with AI personas, voice features, and activity tracking.

## Features

- **AI Chat**: Claude-powered conversations with configurable personas
- **Voice**: Text-to-speech, audio recording, transcription
- **Personas**: Ari (Life Coach), Sergeant Oracle, I-There
- **Plan Tab**: Proactive planning system with calendar navigation and template replication
- **Stats**: Activity tracking analytics and insights
- **Storage**: Local message and audio storage
- **MCP Integration**: Local data processing with intelligent persona responses

## Quick Start

### Prerequisites

- **Flutter**: 3.27.0+ with iOS and Android toolchains
- **iOS Development**: Xcode 16.2+, Apple Developer account
- **Android Development**: Android Studio, Android SDK 35+
- **Firebase CLI**: For Android distribution (`npm install -g firebase-tools`)

### Installation

1. Clone the repository
2. Install dependencies (use one of these methods):
   ```bash
   # Recommended: Use Makefile (auto-patches Android)
   make deps
   
   # Alternative: Use wrapper script
   ./scripts/flutter_pub_get.sh
   
   # Manual: Standard Flutter command (requires manual patching for Android)
   flutter pub get && ./scripts/patch_android_namespaces.sh
   ```

3. Create `.env` with your API keys:
   ```
   ANTHROPIC_API_KEY=your_claude_key
   OPENAI_API_KEY=your_whisper_key
   ELEVEN_LABS_API_KEY=your_tts_key
   ```

**⚠️ Important for Android:**
Always use `make deps` instead of `flutter pub get` to ensure Android namespace patches are applied. These patches fix compatibility issues with older plugins (Isar, Record) that lack namespace declarations required by Android Gradle Plugin 8.0+.

### Running the App

```bash
# iOS
flutter run -d ios
# or
make run-ios

# Android
flutter run -d android
# or
make run-android
```

### Building

```bash
# Android Debug APK
make build-android

# Android Release APK
make build-android-release

# iOS
make build-ios
```

### Distribution

**📚 Complete Release Guides:**
- **Quick Start**: See `docs/RELEASE_QUICK_START.md` for 5-command dual-platform releases
- **Full Workflow**: See `docs/DUAL_PLATFORM_RELEASE_WORKFLOW.md` for detailed process

#### Android (Firebase App Distribution)

**One-Command Distribution:**
```bash
make distribute-android
```

**What happens:**
1. Prompts for release notes (type and press Ctrl+D)
2. Applies Android namespace patches automatically
3. Builds release APK (~2-3 minutes)
4. Uploads to Firebase App Distribution
5. Sends email notifications to testers

**Manual Distribution:**
```bash
# Build release APK
flutter build apk --release

# Distribute to Firebase
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app "1:807856535419:android:39a9db3b2fa8c010d52fde" \
  --groups "internal-testers" \
  --release-notes "Your release notes here"
```

**Testing Android Builds:**

1. **Receive Notification**: Testers get email: "New build available: AI Personas App"
2. **Download APK**: Click link in email or visit Firebase Console
3. **Install on Device**:
   - Enable "Install from Unknown Sources" in Android settings
   - Download and install APK
   - Grant necessary permissions

**Firebase Console:**
- View releases: https://console.firebase.google.com/project/ai-personas-app/appdistribution
- Manage testers: Add/remove testers in "Testers & Groups" tab
- Download APK: Direct download links available for each release

**Requirements:**
- Firebase CLI installed: `npm install -g firebase-tools`
- Logged in: `firebase login`
- Tester group created: `internal-testers` in Firebase Console

#### iOS (TestFlight)

**🚀 Protected Branch Release Workflow**

```bash
# 1. Ensure you're on develop branch
git checkout develop
git pull origin develop

# 2. Release with automatic version bumping
python3 scripts/release_testflight.py --version-bump patch    # Bug fixes
python3 scripts/release_testflight.py --version-bump minor   # New features  
python3 scripts/release_testflight.py --version-bump major   # Breaking changes

# 3. Preview changes without executing (dry run)
python3 scripts/release_testflight.py --dry-run --version-bump patch

# 4. Emergency releases (bypass branch validation)
python3 scripts/release_testflight.py --force-branch --version-bump patch
```

**What the script does automatically:**
- ✅ Validates you're on `develop` branch
- ✅ Checks working directory is clean
- ✅ Bumps version in `pubspec.yaml`
- ✅ Updates `CHANGELOG.md` with release notes
- ✅ Commits version changes to git
- ✅ Creates git tag (e.g., `v2.1.1`)
- ✅ Builds Flutter app for iOS
- ✅ Creates Xcode archive
- ✅ Exports IPA for App Store
- ✅ Uploads to TestFlight

**Setup Requirements:**
- Create `.env` file with Apple credentials (see setup docs)
- Ensure `develop` branch is up to date
- Clean working directory (no uncommitted changes)

**Testing iOS Builds:**
1. Install TestFlight app from App Store
2. Accept invitation email
3. Download and install builds directly from TestFlight app

### Development Commands

Use `make` for consistent builds with automatic Android patching:

```bash
make help           # Show all available commands
make deps           # Install dependencies + patch Android
make test           # Run all tests
make clean          # Clean build artifacts
make patch-android  # Apply Android namespace patches only
```

**Why use `make deps` instead of `flutter pub get`?**
- Automatically applies Android namespace patches for plugin compatibility
- Ensures successful Android builds without manual intervention
- Recommended for all developers working on this project

## API Keys

- **Claude**: Required for AI chat
- **Whisper**: Required for voice transcription  
- **ElevenLabs**: Optional for high-quality TTS

## Personas

- **Ari**: Concise life coaching with TARS-inspired brevity
- **Sergeant Oracle**: Energetic Roman gym coach
- **I-There**: AI clone with dimensional knowledge

## Recent Updates

### FT-212: Android Build Support ✅
- **Platform Expansion**: Full Android build support with automated plugin patching
- **Automated Tooling**: Makefile, wrapper script, and git hooks for seamless development
- **Plugin Compatibility**: Resolved namespace issues for Isar and Record plugins
- **Build Success**: Debug APK builds working (96MB, 95.6s build time)
- **Zero iOS Impact**: Android changes completely isolated, iOS builds unaffected

### FT-118: Oracle v3.0 Personas Implementation ✅
- **Oracle v3.0 Integration**: Successfully implemented Oracle v3.0 personas with full activity detection
- **JSON Configuration**: Generated missing `oracle_prompt_v3.json` for proper activity tracking
- **Persona Compatibility**: All Oracle personas (1.0, 2.0, 2.1, 3.0) now fully functional
- **Activity Detection Fix**: Resolved issue where 3.0 personas couldn't detect activities due to missing configuration

### FT-105: Plan Tab - Comprehensive Planning System 📝
- **Proactive Planning**: Transform from reactive stats to intentional daily planning
- **Calendar Navigation**: Swipeable days with today-focused interface
- **Template Intelligence**: Smart replication (weekdays from weekdays, weekends from weekends)
- **Personal Organization**: Custom labels, user notes, and drag-drop activity management
- **Seamless Integration**: Zero impact on detection system, auto-complete planned activities

### FT-104: JSON Command TTS Leak Fix ✅
- **TTS Contamination**: Prevent JSON commands from bleeding into spoken responses
- **Surgical Fix**: Enhanced response cleaning for both regular and two-pass conversations
- **User Experience**: Clean audio without technical artifacts

### FT-103: Intelligent Activity Detection Throttling ✅
- **Model-Driven Qualification**: AI determines when activity detection is needed
- **Rate Limit Protection**: Adaptive delays (5-15s) based on API usage patterns
- **Smart Processing**: Internal assessment tags prevent TTS contamination

### FT-102: Minimal Time Cache Fix ✅
- **Caching Strategy**: 30-second cache for `get_current_time` MCP calls
- **Rate Limit Prevention**: Reduces redundant API calls across services
- **System Efficiency**: Maintains accuracy while optimizing performance

### FT-100: Basic Temporal Query MCP Fix ✅
- **Enhanced Guidance**: Comprehensive prompt table for temporal query handling
- **Consistent Responses**: Always use MCP for "what time?", "what date?", "what day?"
- **Reliable Data**: Fix date inconsistencies in AI responses

## Troubleshooting

### Android Build Issues

**Error: "Namespace not specified"**
- **Solution**: Run `make deps` instead of `flutter pub get`
- **Why**: Applies necessary namespace patches to plugins

**Error: "resource android:attr/lStar not found"**
- **Solution**: Patches are applied automatically by `make deps`
- **Manual fix**: Run `./scripts/patch_android_namespaces.sh`
- **What it does**: Updates Isar plugin's compileSdkVersion from 30 to 35

**Release build fails but debug works**
- **Solution**: Already configured in `android/app/build.gradle.kts`
- **Settings**: `compileSdk = 35`, resource shrinking disabled
- **Clean build**: `flutter clean && make build-android-release`

**Firebase distribution fails**
- **Check**: Firebase CLI logged in (`firebase login`)
- **Check**: Tester group exists (`internal-testers`)
- **Check**: Project ID correct in `.firebaserc`

### iOS Build Issues

**TestFlight upload fails**
- **Check**: Apple Developer account active
- **Check**: Certificates and provisioning profiles valid
- **Verify setup**: `python3 scripts/release_testflight.py --verify`
- **Branch issue**: Ensure you're on `develop` branch or use `--force-branch`
- **Clean directory**: Commit or stash changes before releasing
- **Solution**: Run `python3 scripts/release_testflight.py --version-bump patch`

**Wrong branch error**
- **Error**: "Release must be from 'develop' branch"
- **Solution**: `git checkout develop` or use `--force-branch` for emergencies
- **Best practice**: Always release from protected `develop` branch

**Uncommitted changes error**  
- **Error**: "Working directory has uncommitted changes"
- **Solution**: `git add . && git commit -m "Pre-release changes"` or `git stash`
- **Override**: Use `--force-branch` to bypass (not recommended)

## Development

- **Tests**: 500+ tests with 95%+ pass rate
- **Architecture**: Clean Flutter with Isar database
- **Audio**: Provider-based TTS with emotional preprocessing
- **MCP**: Local Model Context Protocol for privacy-preserving data integration
- **Platforms**: iOS (TestFlight) and Android (Firebase App Distribution)

## Version

Current: v1.0.38

For detailed changelog and technical docs, see `docs/` directory.
