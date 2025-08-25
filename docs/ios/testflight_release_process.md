# iOS TestFlight Release Process

This guide covers the complete process for releasing the AI Personas App to TestFlight using Xcode.

## Prerequisites

- ✅ iOS project structure intact (`ios/` directory)
- ✅ Bundle ID consistency fixed across all platforms
- ✅ Apple Developer account with team ID: `2MMHAK3LLN`
- ✅ Current version: `1.1.0+10` (check `pubspec.yaml`)

## Current Project Status

### Bundle Configuration
- **Bundle ID**: `com.lyfeab.chatapp`
- **Display Name**: "AI Personas App"
- **App Name**: `ai_personas_app`

### Code Signing Status
```bash
# Check current certificates
security find-identity -v -p codesigning
```

Expected output should include:
- ✅ Apple Development: Alexandre Bairos de Medeiros (52JLUM2Z2Y)
- ⚠️ **Missing**: Apple Distribution certificate (required for TestFlight)

## Step-by-Step Release Process

### Step 1: Open Xcode Project

```bash
open ios/Runner.xcworkspace
```

**Important**: Always open the `.xcworkspace` file, not the `.xcodeproj` file.

### Step 2: Install Distribution Certificate

**In Xcode:**

1. **Xcode Menu** → **Preferences** (or **Settings** in newer Xcode versions)
2. **Accounts Tab**
3. **Select your Apple ID** (should show your developer account)
4. **Click "Manage Certificates..."**
5. **Click the "+" button**
6. **Select "Apple Distribution"**
7. **Click "Done"**

**Verify Installation:**
```bash
security find-identity -v -p codesigning | grep Distribution
```

Should show: `Apple Distribution: Alexandre Bairos de Medeiros`

### Step 3: Configure Project Signing

**In Xcode:**

1. **Click on "Runner"** (blue project icon at the top of the navigator)
2. **Select "Runner" target** (under TARGETS section)
3. **Go to "Signing & Capabilities" tab**
4. **Configure the following:**
   - ✅ **Check "Automatically manage signing"**
   - ✅ **Team**: Select your team (`2MMHAK3LLN`)
   - ✅ **Bundle Identifier**: Verify shows `com.lyfeab.chatapp`
   - ✅ **Display Name**: Verify shows "AI Personas App"

**Expected Result**: No signing errors should appear.

### Step 4: Build for Device

**In Xcode:**

1. **Change destination** (top toolbar dropdown) from Simulator to **"Any iOS Device (arm64)"**
2. **Product Menu** → **Clean Build Folder** (⇧⌘K)
3. **Product Menu** → **Build** (⌘B)

**Wait for build completion**. Check for any compilation errors in the Issue Navigator.

### Step 5: Create Archive

**Once build succeeds:**

1. **Product Menu** → **Archive**
2. **Wait for archive process** (this creates the release build for distribution)
3. **Xcode Organizer** should open automatically

**Note**: The archive process may take several minutes.

### Step 6: Upload to TestFlight

**In Xcode Organizer:**

1. **Select your new archive** (should appear at the top of the list)
2. **Click "Distribute App"**
3. **Select "App Store Connect"** → **Next**
4. **Select "Upload"** → **Next**
5. **Keep default options** (Include bitcode, Upload symbols) → **Next**
6. **Review summary** and **click "Upload"**

**Upload Process**: This may take 10-15 minutes depending on your internet connection.

### Step 7: Verify Upload Success

**In Xcode Organizer:**
- Look for "Upload Successful" message
- Note the build number that was uploaded

**In App Store Connect:**
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → **AI Personas App** → **TestFlight**
3. **Wait 5-10 minutes** for build processing
4. **Verify build appears** in the builds list

## Troubleshooting

### Common Issues

#### 1. Missing Distribution Certificate
**Error**: "No signing certificate 'iOS Distribution' found"

**Solution**: Follow Step 2 to install the Apple Distribution certificate.

#### 2. Bundle ID Mismatch
**Error**: Bundle identifier doesn't match App Store Connect

**Solution**: Verify bundle ID is `com.lyfeab.chatapp` in Signing & Capabilities.

#### 3. Build Failures
**Error**: Compilation errors during build

**Solution**: 
```bash
flutter clean
flutter pub get
flutter build ios --release --no-pub
```

#### 4. Archive Upload Fails
**Error**: Upload to App Store Connect fails

**Solutions**:
- Check internet connection
- Verify Apple Developer account status
- Try uploading again (temporary server issues)

#### 5. Build Not Appearing in TestFlight
**Issue**: Build uploaded but not visible in App Store Connect

**Solutions**:
- Wait 10-15 minutes for processing
- Check for email notifications from Apple
- Verify build wasn't rejected (check App Store Connect notifications)

### Version Management

#### Bumping Version for New Releases

**In `pubspec.yaml`:**
```yaml
version: 1.1.0+11  # Increment build number (+11, +12, etc.)
```

**For major updates:**
```yaml
version: 1.2.0+1   # Increment version number, reset build to 1
```

**After version change:**
```bash
flutter clean
flutter pub get
```

### Alternative: Command Line Upload

If Xcode Organizer upload fails, you can use command line:

```bash
# Build IPA
flutter build ipa --release

# Upload using altool (requires App Store Connect API key)
xcrun altool --upload-app --type ios \
  -f build/ios/ipa/ai_personas_app.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

## Verification Checklist

Before each release, verify:

- [ ] Version number incremented in `pubspec.yaml`
- [ ] All tests passing: `flutter test`
- [ ] iOS build successful: `flutter build ios --release`
- [ ] Distribution certificate installed
- [ ] Bundle ID matches App Store Connect: `com.lyfeab.chatapp`
- [ ] App name correct: "AI Personas App"

## Post-Release

After successful upload:

1. **Tag the release** in Git:
   ```bash
   git tag v1.1.0+10
   git push origin v1.1.0+10
   ```

2. **Monitor App Store Connect** for build processing status

3. **Test the build** once it appears in TestFlight

4. **Distribute to testers** via TestFlight when ready

## File Locations

- **iOS Project**: `ios/Runner.xcworkspace`
- **Bundle Configuration**: `ios/Runner/Info.plist`
- **Signing Configuration**: Managed by Xcode in project settings
- **Version Info**: `pubspec.yaml`

## Support

For issues with this process:
1. Check the troubleshooting section above
2. Verify all prerequisites are met
3. Consult Apple Developer documentation
4. Check Xcode and Flutter versions compatibility

---

**Last Updated**: January 2025  
**Flutter Version**: 3.x  
**Xcode Version**: 15.x+
