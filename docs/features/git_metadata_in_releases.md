# Git Metadata in Release Notes

**Feature**: Automatic Git metadata inclusion in iOS and Android release notes  
**Date**: 2025-10-25  
**Status**: ✅ Implemented

## Overview

Both iOS (TestFlight) and Android (Firebase) release scripts now automatically collect and include Git metadata in release notes, making it easy to identify the exact source code version for any build.

## What's Included

The following Git metadata is automatically collected and included:

- **Commit Hash**: Full SHA and short 7-character hash
- **Git Tag**: Version tag if the commit is tagged (e.g., `v2.3.1`)
- **Branch Name**: Source branch (typically `develop`)
- **Build Date/Time**: When the build was created

## Implementation

### iOS (TestFlight)

**File**: `scripts/release_testflight.py`

**Changes**:
1. Added `get_git_metadata()` method to collect Git information
2. Display Git metadata during build process
3. After upload completes, display formatted notes for TestFlight "What to Test" field

**Example Output**:
```
📋 Build Metadata
==================================================
Version: 2.3.1 (Build 30)
Git Commit: abc1234 (abc1234def567...)
Git Tag: v2.3.1
Git Branch: develop

🎉 TestFlight release completed!
📱 Your team will receive TestFlight notification when processing completes
⏱️  Processing usually takes 5-10 minutes
🔗 Check status: https://appstoreconnect.apple.com

📝 Add this to TestFlight 'What to Test' notes:
--------------------------------------------------
Version 2.3.1 (Build 30) (v2.3.1)
Git: abc1234 @ develop
Released: 2025-10-25 14:30
--------------------------------------------------
```

**Usage**:
1. Run release script as normal
2. After upload completes, copy the displayed notes
3. Go to App Store Connect → TestFlight → Build
4. Paste into "What to Test" field

### Android (Firebase)

**File**: `scripts/release_firebase_android.sh`

**Changes**:
1. Collect Git metadata at script start
2. Display Git info during build process
3. Automatically append Git metadata to user's release notes
4. Display full Git info in success message

**Example Output**:
```
🚀 Firebase App Distribution - Android

📦 Version: 2.3.1 (Build 30)
📋 Git: abc1234 @ develop
🏷️  Tag: v2.3.1

📝 Enter release notes (press Ctrl+D when done):
[User types their notes]

✅ Distribution successful!
   Version: 2.3.1 (Build 30) (v2.3.1)
   Git: abc1234 @ develop
   APK Size: 96M
   Testers will receive email notifications

📊 View distribution: https://console.firebase.google.com/...

📝 Git metadata included in release notes:
   Commit: abc1234def567890...
   Short: abc1234
   Branch: develop
```

**Release Notes Format**:
```
[User's release notes]

---
Build Info:
Version 2.3.1 (Build 30) (v2.3.1)
Git: abc1234 @ develop
Released: 2025-10-25 14:30
```

**Usage**:
1. Run `make distribute-android`
2. Enter your release notes
3. Git metadata is automatically appended
4. Testers see full info in Firebase console

## Benefits

### For Release Managers
- ✅ **Traceability**: Every build is linked to exact source code
- ✅ **Debugging**: Easy to check out the exact code for any build
- ✅ **Auditing**: Clear history of what code was released when

### For Testers
- ✅ **Context**: Know exactly which version they're testing
- ✅ **Reporting**: Can reference specific commits in bug reports
- ✅ **Clarity**: Understand which features/fixes are in each build

### For Developers
- ✅ **Reproducibility**: Can recreate exact build environment
- ✅ **Comparison**: Easy to diff between builds
- ✅ **Verification**: Confirm correct code was released

## Example Use Cases

### 1. Bug Report Investigation
Tester reports: "Issue in Build 30"
→ Check release notes: Git commit `abc1234`
→ `git checkout abc1234`
→ Investigate exact code that was released

### 2. Build Verification
Question: "Did the fix for FT-220 make it into Build 30?"
→ Check release notes: Git commit `abc1234`
→ `git log abc1234 --oneline | grep FT-220`
→ Confirm presence of fix

### 3. Rollback Decision
Issue found in production
→ Check previous build's Git commit
→ `git diff <previous> <current>`
→ Identify problematic changes

### 4. Release Coordination
Multiple builds in one day
→ Git metadata shows exact commit and time
→ Clear which build contains which changes

## Technical Details

### Git Commands Used

```bash
# Full commit hash
git rev-parse HEAD

# Short commit hash (7 chars)
git rev-parse --short HEAD

# Current tag (if on a tag)
git describe --tags --exact-match

# Current branch
git branch --show-current
```

### Error Handling

Both scripts gracefully handle cases where Git metadata cannot be retrieved:
- Missing Git repository → Uses "unknown" placeholders
- Not on a tag → Omits tag information
- Git command failures → Continues with available information

### Security

- No sensitive information is included in metadata
- Only public Git information (commit hash, branch, tag)
- Safe to share with external testers

## Future Enhancements

Potential improvements for future consideration:

1. **In-App Display**: Add "About" screen showing Git metadata
2. **Structured Metadata**: Add to build artifacts (Info.plist, AndroidManifest.xml)
3. **Build Comparison**: Tool to compare Git diffs between builds
4. **Automated Changelog**: Generate release notes from Git commits
5. **CI/CD Integration**: Automatic metadata injection in CI pipelines

## Documentation

Updated documentation:
- ✅ `README.md`: Added Git metadata section
- ✅ `docs/RELEASE_QUICK_START.md`: (Should be updated)
- ✅ `docs/DUAL_PLATFORM_RELEASE_WORKFLOW.md`: (Should be updated)

## Testing

Tested scenarios:
- ✅ Python script syntax validation
- ✅ Bash script syntax validation
- ⏳ Actual iOS release (pending)
- ⏳ Actual Android release (pending)

## References

- iOS Release Script: `scripts/release_testflight.py`
- Android Release Script: `scripts/release_firebase_android.sh`
- Main Documentation: `README.md`

