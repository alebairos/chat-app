# Development Deployment PRD

## Overview

This document outlines the requirements and procedures for deploying the Character AI Clone chat application to development devices for team testing and collaboration purposes.

## Product Requirements

### Objective
Enable team members to install and run the chat application on their development devices (iOS/Android) through a streamlined process that supports:
- Easy onboarding for new team members
- Consistent development environment setup
- Secure distribution of development builds
- Efficient iteration and testing cycles

### Target Audience
- **Primary**: Development team members with Git access
- **Secondary**: QA testers and stakeholders requiring app access
- **Tertiary**: Product managers and designers for feature validation

## Current State Analysis

### App Configuration
- **App Name**: Character AI Clone
- **Bundle ID**: `com.example.characterAiClone`
- **Current Version**: 1.0.0+1
- **Minimum iOS Version**: 12.0
- **Target Platforms**: iOS (primary), Android (secondary)

### Dependencies
- Flutter SDK (>=3.0.0 <4.0.0)
- Native dependencies via CocoaPods (iOS)
- External services: Claude API, ElevenLabs TTS
- Database: Isar (local storage)

### Current Issues
- Generic bundle identifier needs customization
- No automated deployment pipeline
- Manual device registration required
- Environment configuration scattered across files

## Technical Requirements

### 1. Development Environment Setup

#### Prerequisites
- **Flutter SDK**: Version 3.0.0 or higher
- **Xcode**: Latest stable version (for iOS)
- **Android Studio**: Latest stable version (for Android)
- **Git**: Access to project repository
- **Developer Account**: Apple Developer Program membership (for iOS)

#### Required Tools
```bash
# Flutter installation verification
flutter doctor

# Required Flutter plugins
flutter pub get

# iOS-specific setup
cd ios && pod install && cd ..

# Build verification
flutter build ios --debug
flutter build apk --debug
```

### 2. Configuration Management

#### Environment Variables
Create a standardized `.env` file template:
```env
# API Configuration
CLAUDE_API_KEY=your_claude_api_key_here
ELEVENLABS_API_KEY=your_elevenlabs_api_key_here

# App Configuration
APP_ENVIRONMENT=development
DEBUG_MODE=true
ENABLE_LOGGING=true
```

#### Bundle Identifier Strategy
- **Development**: `com.yourcompany.characterai.dev`
- **Staging**: `com.yourcompany.characterai.staging`
- **Production**: `com.yourcompany.characterai`

### 3. iOS Development Deployment

#### Code Signing Setup
1. **Apple Developer Account Requirements**:
   - Team membership for all developers
   - Device registration in Apple Developer Portal
   - Development certificates and provisioning profiles

2. **Automatic Code Signing**:
   - Enable automatic signing in Xcode
   - Configure team selection in project settings
   - Ensure device registration for team members

#### Distribution Methods

**Option A: Direct Installation via Xcode**
- Requires physical device connection
- Immediate installation and debugging
- Best for active development

**Option B: Ad Hoc Distribution**
- Build signed IPA files
- Distribute via TestFlight or direct download
- Supports up to 100 devices per year

**Option C: Enterprise Distribution** (if applicable)
- Internal distribution without App Store
- Requires Enterprise Developer Program
- Unlimited internal device installation

### 4. Android Development Deployment

#### Keystore Management
- Development keystore for debug builds
- Shared keystore for team consistency
- Secure keystore storage and distribution

#### Distribution Methods
- **Direct APK**: Build and share APK files
- **Firebase App Distribution**: Automated distribution
- **Google Play Internal Testing**: Managed testing tracks

### 5. Automated Build Pipeline

#### CI/CD Requirements
```yaml
# Proposed GitHub Actions workflow
name: Development Build
on:
  push:
    branches: [develop, feature/*]
  pull_request:
    branches: [develop]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Install dependencies
        run: flutter pub get
      - name: Run tests
        run: flutter test
      - name: Build iOS
        run: flutter build ios --debug --no-codesign
      - name: Build Android
        run: flutter build apk --debug
```

## Implementation Plan

### Phase 1: Environment Standardization (Week 1)
- [ ] Update bundle identifiers for development
- [ ] Create environment configuration template
- [ ] Document development setup process
- [ ] Test installation on 2-3 team devices

### Phase 2: Distribution Setup (Week 2)
- [ ] Configure Apple Developer Portal
- [ ] Set up device registration process
- [ ] Create signed build process
- [ ] Test distribution methods

### Phase 3: Automation (Week 3)
- [ ] Implement CI/CD pipeline
- [ ] Automate build generation
- [ ] Set up notification system
- [ ] Create deployment documentation

### Phase 4: Team Onboarding (Week 4)
- [ ] Create onboarding checklist
- [ ] Conduct team training sessions
- [ ] Establish support process
- [ ] Gather feedback and iterate

## User Stories

### As a Developer
- I want to clone the repository and run the app locally within 30 minutes
- I want to receive automatic notifications when new builds are available
- I want to easily switch between development and staging environments
- I want to debug issues directly on my device

### As a QA Tester
- I want to install the latest development build without technical setup
- I want to test features as soon as they're merged to develop branch
- I want to report bugs with build version information
- I want to access different app configurations for testing

### As a Product Manager
- I want to preview features before release
- I want to share builds with stakeholders for feedback
- I want to track which features are in which build
- I want to understand the deployment timeline

## Security Considerations

### Code Protection
- Repository access control via GitHub permissions
- API key management through environment variables
- Secure keystore and certificate storage
- VPN requirements for sensitive builds

### Distribution Security
- Encrypted build distribution
- Device registration verification
- Time-limited development certificates
- Audit trail for build access

## Success Metrics

### Technical Metrics
- **Setup Time**: < 30 minutes from clone to running app
- **Build Success Rate**: > 95% automated builds pass
- **Distribution Speed**: < 15 minutes from merge to available build
- **Device Compatibility**: 100% of registered devices can install

### Team Metrics
- **Onboarding Efficiency**: New team members productive within 1 day
- **Feedback Cycle**: < 24 hours from feature completion to stakeholder review
- **Bug Detection**: 50% reduction in production bugs through dev testing
- **Team Satisfaction**: > 4.5/5 rating on deployment process

## Risk Assessment

### High Risk
- **Apple Developer Account Issues**: Suspended account blocks all iOS development
- **Certificate Expiration**: Expired certificates prevent installation
- **API Key Exposure**: Compromised keys require immediate rotation

### Medium Risk
- **Build Failures**: Broken builds delay feature testing
- **Device Compatibility**: New iOS versions break existing builds
- **Storage Limits**: Large build files consume significant storage

### Low Risk
- **Network Issues**: Slow downloads affect distribution speed
- **Version Conflicts**: Different Flutter versions cause minor issues
- **Documentation Gaps**: Missing steps slow onboarding

## Appendices

### Appendix A: Installation Checklist
```markdown
## Development Setup Checklist

### Prerequisites
- [ ] Flutter SDK installed and configured
- [ ] Xcode installed (for iOS development)
- [ ] Git access to repository
- [ ] Apple Developer account access

### Setup Steps
1. [ ] Clone repository: `git clone <repo-url>`
2. [ ] Install dependencies: `flutter pub get`
3. [ ] Configure environment: Copy `.env.example` to `.env`
4. [ ] Add API keys to `.env` file
5. [ ] Run iOS setup: `cd ios && pod install && cd ..`
6. [ ] Connect device and enable developer mode
7. [ ] Build and run: `flutter run`

### Verification
- [ ] App launches successfully
- [ ] Audio recording works
- [ ] TTS playback functions
- [ ] Character selection available
- [ ] Chat functionality operational
```

### Appendix B: Troubleshooting Guide
```markdown
## Common Issues and Solutions

### Build Failures
- **Pod install fails**: Delete `ios/Pods` and `ios/Podfile.lock`, then re-run
- **Certificate issues**: Check Xcode signing settings and team selection
- **Flutter version**: Ensure Flutter SDK version matches requirements

### Runtime Issues
- **Audio not working**: Check device permissions and microphone access
- **TTS failures**: Verify ElevenLabs API key configuration
- **Database errors**: Clear app data and restart

### Distribution Problems
- **TestFlight upload fails**: Check bundle identifier and certificates
- **Device installation fails**: Verify device registration in Developer Portal
- **Build size too large**: Enable code shrinking and asset optimization
```

### Appendix C: Build Scripts
```bash
#!/bin/bash
# build_development.sh

echo "Building Character AI Clone for Development"

# Clean previous builds
flutter clean
flutter pub get

# iOS Build
echo "Building iOS..."
cd ios
pod install
cd ..
flutter build ios --debug --flavor development

# Android Build
echo "Building Android..."
flutter build apk --debug --flavor development

echo "Build completed successfully!"
```

## Conclusion

This PRD provides a comprehensive framework for establishing a robust development deployment process for the Character AI Clone application. By following these guidelines, the team can ensure consistent, secure, and efficient distribution of development builds while maintaining high code quality and team productivity.

The success of this deployment strategy depends on proper implementation of security measures, automation pipelines, and team training. Regular review and updates of this process will ensure it continues to meet the evolving needs of the development team. 