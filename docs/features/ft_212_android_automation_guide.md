# FT-212: Android Build Automation Guide

**Quick Reference for Developers**

## TL;DR

**Use `make deps` instead of `flutter pub get`** to automatically patch Android plugins.

## Why Automation is Needed

The project uses plugins (`isar_flutter_libs`, `record`) that lack `namespace` declarations required by Android Gradle Plugin 8.0+. Without patches, Android builds fail with:

```
Namespace not specified. Specify a namespace in the module's build file
```

## Three Automation Options

### 1. Makefile (Recommended) ⭐

**Best for**: Daily development workflow

```bash
# Common commands
make deps           # Install dependencies + patch Android
make build-android  # Build Android debug APK
make test           # Run tests
make clean          # Clean build artifacts
make help           # Show all commands
```

**Advantages**:
- Shortest commands
- Professional standard
- Clear, self-documenting
- Works across team

### 2. Shell Wrapper

**Best for**: One-off dependency updates

```bash
./scripts/flutter_pub_get.sh
```

**Advantages**:
- Explicit about what it does
- Good for scripts/CI
- Standalone executable

### 3. Git Hook (Automatic)

**Best for**: Seamless background automation

- **Location**: `.git/hooks/post-checkout`
- **Trigger**: Runs after `git checkout` when `pubspec.lock` changes
- **Action**: Automatically applies patches

**Advantages**:
- Zero manual intervention
- Catches dependency changes from branch switches
- Team consistency

## What Gets Patched

The automation adds `namespace` declarations to:

1. **isar_flutter_libs-3.1.0+1**
   ```gradle
   android {
       namespace "dev.isar.isar_flutter_libs"
       // ... rest of config
   }
   ```

2. **record-4.4.4**
   ```gradle
   android {
       namespace "com.llfbandit.record"
       // ... rest of config
   }
   ```

## Verification

Check if patches are applied:

```bash
# Isar
grep -n "namespace" ~/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android/build.gradle

# Record
grep -n "namespace" ~/.pub-cache/hosted/pub.dev/record-4.4.4/android/build.gradle
```

Expected output: Line showing `namespace "..."` declaration

## Testing the Build

After patching:

```bash
# Debug build
make build-android
# or
flutter build apk --debug

# Release build
make build-android-release
# or
flutter build apk --release
```

## Troubleshooting

### "Namespace not specified" error

**Cause**: Patches not applied or lost after `flutter pub get`

**Fix**:
```bash
./scripts/patch_android_namespaces.sh
```

### Patches don't persist

**Cause**: Running `flutter pub get` directly re-downloads plugins

**Fix**: Always use `make deps` or `./scripts/flutter_pub_get.sh`

### Git hook not running

**Check executable permissions**:
```bash
ls -la .git/hooks/post-checkout
```

**Should show**: `-rwxr-xr-x` (executable)

**Fix if needed**:
```bash
chmod +x .git/hooks/post-checkout
```

## iOS Impact

**None.** All patches are Android-specific:
- Modify `android/build.gradle` files only
- iOS uses separate CocoaPods configuration
- No shared code affected

## Long-term Solution

Current patches are **temporary**. For production stability, consider:

1. **Plugin Migration**: Update to namespace-compatible versions
   - Isar v4.x (when stable)
   - Record v6.x (latest)

2. **Alternative Plugins**:
   - Drift (instead of Isar)
   - Flutter Sound (instead of Record)

See `ft_212_android_namespace_fix_investigation.md` for detailed analysis.

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Install dependencies
  run: make deps

- name: Build Android APK
  run: make build-android
```

### Manual CI Setup

```bash
flutter pub get
./scripts/patch_android_namespaces.sh
flutter build apk --debug
```

## Team Onboarding

**New developer setup**:

1. Clone repository
2. Run `make deps` (not `flutter pub get`)
3. Build: `make build-android` or `make build-ios`
4. Done! Git hook will handle future updates

**Key message**: "Use `make deps` instead of `flutter pub get`"

## Summary

| Method | Command | When to Use |
|--------|---------|-------------|
| **Makefile** | `make deps` | Daily development (recommended) |
| **Wrapper** | `./scripts/flutter_pub_get.sh` | Scripts, CI/CD |
| **Git Hook** | Automatic | Background consistency |
| **Manual** | `./scripts/patch_android_namespaces.sh` | Emergency fix |

**Remember**: Android patches are temporary. Plan migration to namespace-compatible plugins for v2.2.0+.

