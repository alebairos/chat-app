# FT-212: Android Build Support

**Priority**: High  
**Category**: Platform Support  
**Effort**: 2-4 hours  

## Problem Statement
The Flutter chat app currently only supports iOS builds. Android platform support is needed for cross-platform deployment and testing capabilities.

## Solution Overview
Add complete Android platform support with proper v2 embedding configuration and resolve plugin compatibility issues for successful APK builds.

## Functional Requirements

### FR-212.1: Android Project Structure
- Generate complete Android project structure via `flutter create --platforms android`
- Configure proper Android v2 embedding in AndroidManifest.xml
- Set up Gradle build files with correct namespace configuration

### FR-212.2: Plugin Compatibility
- Update Isar database plugin to v4.x for Android Gradle Plugin namespace compatibility
- Ensure all Flutter plugins support Android platform
- Resolve any plugin-specific Android configuration issues

### FR-212.3: Build Capabilities
- Support debug APK builds (`flutter build apk --debug`)
- Support release APK builds (`flutter build apk --release`)
- Enable Android emulator testing (`flutter run -d android`)

## Non-Functional Requirements

### NFR-212.1: Build Performance
- Android build time should complete within 5 minutes for debug builds
- Incremental builds should complete within 2 minutes

### NFR-212.2: Compatibility
- Support Android API level 21+ (Android 5.0+)
- Maintain existing iOS functionality without regression
- Ensure cross-platform feature parity

## Technical Implementation

### ✅ Implemented Solution: Local Plugin Patching

Due to plugin compatibility issues with Android Gradle Plugin 8.0+, we implemented an automated patching system:

**Automated Patching Tools** (Choose one):

1. **Makefile** (Recommended):
   ```bash
   make deps          # Replaces: flutter pub get
   make build-android # Build Android APK (debug)
   make test          # Run tests
   ```

2. **Shell Wrapper**:
   ```bash
   ./scripts/flutter_pub_get.sh  # Auto-patches after pub get
   ```

3. **Git Hook** (Automatic):
   - Runs automatically after `git checkout` when `pubspec.lock` changes
   - No manual action required

**What Gets Patched**:
- `isar_flutter_libs-3.1.0+1`: Adds `namespace "dev.isar.isar_flutter_libs"`
- `record-4.4.4`: Adds `namespace "com.llfbandit.record"`

### Android Configuration
- AndroidManifest.xml with `flutterEmbedding` value="2"
- MainActivity extending FlutterActivity (Kotlin)
- Proper namespace configuration in build.gradle.kts
- Automated namespace patching for incompatible plugins

## Acceptance Criteria

### AC-212.1: Successful Builds
- [x] `flutter build apk --debug` completes without errors ✅
- [ ] `flutter build apk --release` completes without errors
- [x] Generated APK installs and runs on Android device/emulator ✅

### AC-212.2: Testing Support
- [ ] `flutter test` passes on Android platform
- [x] `flutter run -d android` launches app successfully ✅
- [x] All existing features work on Android (chat, personas, audio) ✅

### AC-212.3: Development Workflow
- [x] `flutter doctor` shows no Android-related issues ✅
- [x] Automated patching system implemented (Makefile, wrapper, git hook) ✅
- [x] Android emulator can be launched via `flutter emulators` ✅
- [x] Hot reload works during Android development ✅

## Dependencies
- Android SDK properly configured
- Android licenses accepted
- Flutter 3.29.0+ with Android toolchain

## Risks & Mitigations
- **Risk**: Plugin compatibility issues with newer Android versions
- **Mitigation**: Update all plugins to latest versions, test thoroughly
- **Risk**: Performance differences between iOS and Android
- **Mitigation**: Platform-specific performance testing and optimization

## Definition of Done
- Android APK builds successfully without errors
- All existing tests pass on Android platform
- App functionality verified on Android device/emulator
- Documentation updated with Android build instructions
