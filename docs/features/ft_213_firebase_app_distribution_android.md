# FT-213: Firebase App Distribution for Android

**Priority**: High  
**Category**: Distribution & Testing  
**Effort**: 1-2 hours  
**Related**: FT-212 (Android Build Support)

## Problem Statement

With Android build support now functional (FT-212), we need a distribution method for testing similar to TestFlight for iOS. Manual APK distribution is inefficient and lacks tracking capabilities.

## Solution Overview

Implement Firebase App Distribution for quick Android testing with email-based invitations, automatic updates, and release notes support.

## Functional Requirements

### FR-213.1: Firebase Setup
- Configure Firebase project for the app
- Install Firebase CLI tools
- Initialize App Distribution in the project
- Configure tester groups

### FR-213.2: Build & Distribution Script
- Create automated build script for release APKs
- Integrate Firebase distribution command
- Support release notes input
- Mirror TestFlight workflow patterns

### FR-213.3: Tester Management
- Define tester groups (internal, beta, etc.)
- Email-based invitation system
- Track distribution history

## Non-Functional Requirements

### NFR-213.1: Distribution Speed
- Build and distribute within 5 minutes
- Testers receive notification immediately
- No manual file transfers required

### NFR-213.2: Workflow Consistency
- Similar command structure to TestFlight scripts
- Reuse existing versioning patterns
- Maintain release notes format

## Technical Implementation

### Firebase CLI Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize App Distribution
firebase init appdistribution
```

### Distribution Script
**Location**: `scripts/release_firebase_android.sh`

```bash
#!/bin/bash
# Build release APK
flutter build apk --release

# Distribute via Firebase
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "internal-testers" \
  --release-notes-file RELEASE_NOTES.txt
```

### Makefile Integration
```makefile
distribute-android: ## Build and distribute Android via Firebase
	@./scripts/release_firebase_android.sh
```

## Acceptance Criteria

### AC-213.1: Firebase Configuration
- [x] Firebase project configured
- [ ] Firebase CLI installed and authenticated
- [ ] App Distribution initialized
- [ ] Tester groups defined

### AC-213.2: Distribution Workflow
- [ ] Release APK builds successfully
- [ ] Distribution script executes without errors
- [ ] Testers receive email notifications
- [ ] APK installs on test devices

### AC-213.3: Documentation
- [ ] Distribution process documented
- [ ] Tester onboarding guide created
- [ ] Troubleshooting section added

## Dependencies

- FT-212: Android Build Support (completed)
- Firebase project access
- Release signing configuration
- Tester email list

## Comparison: TestFlight vs Firebase

| Feature | TestFlight (iOS) | Firebase (Android) |
|---------|------------------|-------------------|
| **Setup** | Apple Dev Account | Firebase (free) |
| **Distribution** | Automatic via App | Email link |
| **Max Testers** | 10,000 | Unlimited |
| **Review** | Yes (external) | No |
| **Speed** | Hours | Seconds |
| **Cost** | $99/year | Free |

## Risks & Mitigations

- **Risk**: Firebase configuration complexity
- **Mitigation**: Step-by-step setup guide with screenshots

- **Risk**: Release signing not configured
- **Mitigation**: Document signing setup process

## Definition of Done

- Firebase App Distribution configured and tested
- Distribution script creates and uploads release APK
- At least one test distribution successful
- Documentation complete with examples
- Makefile command available: `make distribute-android`

## Future Enhancements (Phase 2)

- Google Play Console integration
- Internal Testing track setup
- Closed Testing for beta users
- Production release automation

