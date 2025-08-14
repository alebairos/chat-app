# FT-028: Simple TestFlight Release

**Goal**: One command releases app to TestFlight  
**Command**: `python scripts/release_testflight.py`  
**Time**: 10 minutes end-to-end  

## What It Does

```bash
python scripts/release_testflight.py
```

1. Builds Flutter iOS app **from current local code**
2. Creates Xcode archive  
3. Uploads IPA file directly to TestFlight
4. Team gets notification

## Rationale: Local Build + Direct Upload

**Why no git repository involved?**
- **Simplest possible**: No CI/CD, no cloud builds, no GitHub Actions
- **Immediate release**: Release exactly what you have locally right now
- **Zero infrastructure**: No need to configure Xcode Cloud, GitHub workflows, etc.
- **Developer control**: You decide when to release, from your current working directory

**The flow**: 
```
Your local code → Build locally → Upload IPA → TestFlight
```

**Not**:
```
Git push → Trigger CI → Cloud build → TestFlight
```

## Required Setup (.env file)

```bash
APPLE_ID=your.email@domain.com
APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx  
TEAM_ID=ABCD123456
BUNDLE_ID=com.yourname.chatapp
```

## How to Get Credentials

1. **APPLE_ID**: Your Apple Developer email
2. **APP_SPECIFIC_PASSWORD**: Generate at https://appleid.apple.com → App-Specific Passwords
3. **TEAM_ID**: https://developer.apple.com/account → Membership tab
4. **BUNDLE_ID**: Create app in App Store Connect, use its bundle ID

## Implementation

Single Python script that:
- **Verification mode**: `python scripts/release_testflight.py --verify`
- **Release mode**: `python scripts/release_testflight.py`
- Runs `flutter build ios --release`
- Runs `xcodebuild archive`  
- Runs `xcrun altool --upload-app`
- Shows progress, handles errors

## Verification Function

**Command**: `python scripts/release_testflight.py --verify`

**Checks**:
1. ✅ All 4 credentials exist in .env
2. ✅ Flutter is installed and working
3. ✅ Xcode command line tools available
4. ✅ Can authenticate with Apple (using altool --validate-app)
5. ✅ Bundle ID matches what's in iOS project

**Output**: Clear ✅ or ❌ for each check with helpful error messages

## Bundle ID Setup (if needed)

If verification shows "Bundle ID not found in iOS project":

**Step 1: Register Bundle ID in Apple Developer Portal**
1. Go to https://developer.apple.com/account
2. Certificates, Identifiers & Profiles → Identifiers → +
3. App IDs → App → Continue
4. Description: "Chat App", Bundle ID: your BUNDLE_ID from .env
5. Continue → Register

**Step 2: Update iOS Project**
1. Open `ios/Runner/Info.plist`
2. Find `<key>CFBundleIdentifier</key>`
3. Change the value to match your BUNDLE_ID from .env
4. Save file

**Step 3: Re-verify**
```bash
python3 scripts/release_testflight.py --verify
```

## Success Criteria

- [x] Single command deploys to TestFlight
- [x] Team receives TestFlight notification
- [x] No manual Xcode steps required
- [x] Verification checks all setup requirements

**That's it.**
