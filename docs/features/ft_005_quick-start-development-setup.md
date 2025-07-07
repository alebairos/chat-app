# Quick Start: Development Setup Guide

## 🚀 Get Running in 30 Minutes

This guide will get you from zero to running the Character AI Clone app on your device in under 30 minutes.

## Prerequisites Check

Before starting, ensure you have:
- [ ] **Flutter SDK** (3.0.0+) - [Install here](https://flutter.dev/docs/get-started/install)
- [ ] **Xcode** (latest) - Available on Mac App Store
- [ ] **Git** access to this repository
- [ ] **Apple Developer Account** (for iOS deployment)

### Verify Your Setup
```bash
flutter doctor
# Should show no critical issues
```

## Step 1: Clone and Setup (5 minutes)

```bash
# Clone the repository
git clone https://github.com/your-org/chat_app.git
cd chat_app

# Install Flutter dependencies
flutter pub get

# Setup iOS dependencies
cd ios
pod install
cd ..
```

## Step 2: Environment Configuration (5 minutes)

### Create Environment File
```bash
# Copy the example environment file
cp .env.example .env
```

### Edit `.env` file with your credentials:
```env
# API Configuration - Get these from team lead
CLAUDE_API_KEY=your_claude_api_key_here
ELEVENLABS_API_KEY=your_elevenlabs_api_key_here

# App Configuration
APP_ENVIRONMENT=development
DEBUG_MODE=true
ENABLE_LOGGING=true
```

> **🔑 Getting API Keys**: Contact your team lead for the development API keys. Never commit real keys to Git!

## Step 3: iOS Device Setup (10 minutes)

### Enable Developer Mode on iPhone
1. Open **Settings** → **Privacy & Security**
2. Scroll to **Developer Mode** (appears after first Xcode build)
3. Toggle **Developer Mode** ON
4. Restart your device when prompted

### Configure Xcode Signing
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project in navigator
3. Go to **Signing & Capabilities** tab
4. Check **Automatically manage signing**
5. Select your **Development Team**
6. Ensure **Bundle Identifier** is unique (e.g., `com.yourname.characterai.dev`)

### Trust Developer Certificate
1. After first build, go to **Settings** → **General** → **VPN & Device Management**
2. Find your developer certificate
3. Tap **Trust "Your Name"**
4. Confirm trust

## Step 4: Build and Run (10 minutes)

### Option A: Using Flutter Command Line
```bash
# List available devices
flutter devices

# Run on connected iOS device
flutter run -d "Your iPhone Name"

# Or run on iOS simulator
flutter run -d "iPhone 14 Pro"
```

### Option B: Using Xcode
1. Open `ios/Runner.xcworkspace`
2. Select your device from the scheme dropdown
3. Click **Run** (▶️) button

## Step 5: Verify Installation

Once the app launches, verify these features work:
- [ ] App opens to character selection screen
- [ ] Can select "Sergeant Oracle" character
- [ ] Chat interface loads properly
- [ ] Microphone permission granted
- [ ] Audio recording works (tap and hold record button)
- [ ] TTS playback functions (send a message)

## Common Issues & Quick Fixes

### Build Fails with Pod Errors
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### "No Development Team" Error
1. Open Xcode → **Preferences** → **Accounts**
2. Add your Apple ID
3. Download certificates
4. Retry build

### Device Not Recognized
1. Unplug and replug device
2. Trust computer on device
3. Run `flutter devices` to verify

### App Crashes on Launch
1. Check console logs: `flutter logs`
2. Verify `.env` file exists and has correct format
3. Ensure API keys are valid

## Next Steps

### For Active Development
- Set up hot reload: `flutter run` keeps running for instant updates
- Use `flutter logs` to see real-time debugging output
- Install Flutter extension for VS Code or Android Studio

### For Testing Features
- Switch between characters to test persona system
- Test audio recording and playback
- Try different conversation flows
- Report bugs with device info and logs

## Team Resources

### Getting Help
- **Slack**: #mobile-dev channel
- **Documentation**: Check `/docs` folder for detailed guides
- **Issues**: Create GitHub issues for bugs
- **Team Lead**: Contact @[team-lead] for access issues

### Development Workflow
1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and test on device
3. Run tests: `flutter test`
4. Create pull request
5. Deploy to staging for team testing

## Advanced Setup (Optional)

### Multiple Environment Support
```bash
# Run with different flavors (when implemented)
flutter run --flavor development
flutter run --flavor staging
```

### Performance Profiling
```bash
# Run with performance overlay
flutter run --profile
```

### Database Inspection
- Use Isar Inspector link shown in console
- View local database contents
- Debug data persistence issues

## Troubleshooting Checklist

If you're stuck, go through this checklist:

### Environment Issues
- [ ] Flutter doctor shows no critical errors
- [ ] Xcode is latest version
- [ ] iOS deployment target is 12.0+
- [ ] Device is registered in Apple Developer Portal

### Build Issues
- [ ] `flutter clean` and `flutter pub get` completed
- [ ] `pod install` ran successfully
- [ ] No conflicting Flutter versions
- [ ] Sufficient disk space available

### Runtime Issues
- [ ] `.env` file exists and is formatted correctly
- [ ] API keys are valid and not expired
- [ ] Device has internet connection
- [ ] Microphone permissions granted
- [ ] Developer mode enabled on device

### Still Having Issues?
1. Check the full [Development Deployment PRD](./development-deployment-prd.md)
2. Search existing GitHub issues
3. Ask in team Slack channel
4. Contact team lead with error logs

---

**🎉 Success!** You should now have the Character AI Clone running on your device. Welcome to the team! 