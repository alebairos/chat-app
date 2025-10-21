# FT-213: Firebase App Distribution Setup Guide

## Step-by-Step Setup Instructions

### Prerequisites
- ✅ Firebase CLI installed
- ✅ Google account with Firebase access
- ✅ Android build working (FT-212)

### Step 1: Firebase Console Setup

1. **Go to Firebase Console**: https://console.firebase.google.com

2. **Create or Select Project**:
   - Click "Add project" (or select existing)
   - Project name: `ai-personas-app` (or your preferred name)
   - Accept terms and click "Continue"
   - Disable Google Analytics (optional for testing)
   - Click "Create project"

3. **Add Android App**:
   - Click the Android icon (⚙️ Settings > Project settings)
   - Click "Add app" > Android
   - **Android package name**: `com.lyfeab.ai_personas_app`
     (Found in: `android/app/build.gradle.kts` - `applicationId`)
   - **App nickname**: "AI Personas Chat App"
   - Click "Register app"
   - Download `google-services.json` (optional for now)
   - Click "Continue" and "Continue to console"

4. **Get Firebase App ID**:
   - Go to Project Settings (⚙️ icon)
   - Scroll to "Your apps" section
   - Copy the **App ID** (format: `1:123456789:android:abc123def456`)
   - **Save this ID** - you'll need it for configuration

5. **Set Up App Distribution**:
   - In left sidebar, click "Release & Monitor" > "App Distribution"
   - Click "Get started"
   - You'll see the distribution dashboard

### Step 2: Local Firebase Configuration

1. **Login to Firebase CLI**:
   ```bash
   firebase login
   ```
   - Opens browser for Google authentication
   - Select your Google account
   - Grant permissions
   - Return to terminal

2. **List Your Projects**:
   ```bash
   firebase projects:list
   ```
   - Find your project ID from the list
   - Copy the **Project ID** (e.g., `ai-personas-app-12345`)

3. **Update Firebase Configuration Files**:

   **Edit `.firebaserc`**:
   ```json
   {
     "projects": {
       "default": "YOUR_PROJECT_ID_HERE"
     }
   }
   ```
   Replace `YOUR_PROJECT_ID_HERE` with your actual Project ID.

   **Edit `firebase.json`**:
   ```json
   {
     "appDistribution": {
       "app": "YOUR_FIREBASE_APP_ID_HERE",
       "releaseNotesFile": "RELEASE_NOTES.txt",
       "groups": ["internal-testers"]
     }
   }
   ```
   Replace `YOUR_FIREBASE_APP_ID_HERE` with your App ID from Step 1.4.

4. **Verify Configuration**:
   ```bash
   firebase use
   ```
   Should show: `Active Project: YOUR_PROJECT_ID (default)`

### Step 3: Create Tester Group

1. **In Firebase Console**:
   - Go to "App Distribution"
   - Click "Testers & Groups" tab
   - Click "Add group"
   - **Group name**: `internal-testers`
   - Click "Create group"

2. **Add Testers**:
   - Click on "internal-testers" group
   - Click "Add testers"
   - Enter email addresses (one per line)
   - Click "Add testers"

### Step 4: Test Distribution (Manual)

1. **Build Release APK**:
   ```bash
   make build-android-release
   # or
   flutter build apk --release
   ```

2. **Create Release Notes**:
   ```bash
   echo "Test distribution - Android build v1.0.0" > RELEASE_NOTES.txt
   ```

3. **Distribute Manually**:
   ```bash
   firebase appdistribution:distribute \
     build/app/outputs/flutter-apk/app-release.apk \
     --app YOUR_FIREBASE_APP_ID \
     --groups "internal-testers" \
     --release-notes-file RELEASE_NOTES.txt
   ```

4. **Check Distribution**:
   - Go to Firebase Console > App Distribution
   - You should see your release listed
   - Testers will receive email notifications

### Troubleshooting

#### Error: "App not found"
- Verify App ID in `firebase.json` matches Firebase Console
- Ensure you're using the correct project: `firebase use`

#### Error: "Permission denied"
- Run `firebase login` again
- Ensure your Google account has Owner/Editor role in Firebase project

#### Error: "Group not found"
- Create the group in Firebase Console first
- Group name must match exactly (case-sensitive)

#### APK not building
- Ensure Android signing is configured (see below)
- Run `make deps` to apply namespace patches
- Check `flutter doctor` for issues

### Next Steps

Once manual distribution works:
1. ✅ Automated distribution script (Step 2)
2. ✅ Release signing configuration (Step 3)
3. ✅ Makefile integration (Step 4)
4. ✅ Documentation (Step 5)

---

## Quick Reference

### Configuration Files
- `.firebaserc` - Project ID configuration
- `firebase.json` - App Distribution settings
- `RELEASE_NOTES.txt` - Release notes for each distribution

### Important IDs
- **Project ID**: Found in Firebase Console or `firebase projects:list`
- **App ID**: Found in Project Settings > Your apps
- **Package Name**: `com.lyfeab.ai_personas_app`

### Useful Commands
```bash
# Login
firebase login

# List projects
firebase projects:list

# Check current project
firebase use

# Switch project
firebase use PROJECT_ID

# Distribute APK
firebase appdistribution:distribute PATH_TO_APK \
  --app APP_ID \
  --groups "GROUP_NAME" \
  --release-notes-file RELEASE_NOTES.txt
```

---

## Status Checklist

- [ ] Firebase project created
- [ ] Android app registered in Firebase
- [ ] App ID obtained
- [ ] Firebase CLI authenticated
- [ ] `.firebaserc` configured with Project ID
- [ ] `firebase.json` configured with App ID
- [ ] Tester group created
- [ ] Testers added to group
- [ ] Manual distribution tested successfully

Once all items are checked, proceed to automated script implementation!

