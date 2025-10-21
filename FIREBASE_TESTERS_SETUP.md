# Firebase App Distribution - Tester Setup

## Quick Setup (Do This Now)

### 1. Create Tester Group

1. Go to: https://console.firebase.google.com/project/ai-personas-app/appdistribution
2. Click **"Testers & Groups"** tab
3. Click **"Add group"** button
4. **Group name**: `internal-testers` (must match exactly)
5. Click **"Create group"**

### 2. Add Testers

1. Click on the **"internal-testers"** group you just created
2. Click **"Add testers"** button
3. Enter email addresses (one per line):
   ```
   your.email@example.com
   tester1@example.com
   tester2@example.com
   ```
4. Click **"Add testers"**

### 3. Verify Setup

- You should see the testers listed in the group
- Each tester will receive an invitation email
- Testers need to accept the invitation before receiving builds

---

## First Distribution Test

Once the group is created, run:

```bash
make distribute-android
```

Or directly:

```bash
./scripts/release_firebase_android.sh
```

### What Happens:

1. Script prompts for release notes
2. Applies Android namespace patches
3. Builds release APK
4. Uploads to Firebase App Distribution
5. Sends email notifications to testers

### Expected Output:

```
🚀 Firebase App Distribution - Android
📦 Version: 2.1.0 (Build 1)
📝 Enter release notes (press Ctrl+D when done):
✓ Release notes saved
🔧 Applying Android namespace patches...
🏗️  Building release APK...
✓ Build complete: 96MB
📤 Distributing to Firebase App Distribution...
✅ Distribution successful!
```

---

## Tester Experience

### 1. Invitation Email
Testers receive: "You've been invited to test AI Personas App"

### 2. Accept Invitation
- Click link in email
- Sign in with Google account
- Accept invitation

### 3. Receive Builds
- Email notification for each new release
- Download APK directly from email or Firebase web portal
- Install on Android device

### 4. Install APK
- Enable "Install from Unknown Sources" on Android
- Download and install APK
- App updates automatically when new versions are distributed

---

## Troubleshooting

### Error: "Group not found"
- Ensure group name is exactly `internal-testers` (case-sensitive)
- Refresh Firebase Console and verify group exists

### Error: "No testers in group"
- Add at least one tester email to the group
- Testers must accept invitation first

### Testers not receiving emails
- Check spam folder
- Verify email addresses are correct
- Ensure testers have accepted invitation

---

## Quick Commands

```bash
# Build and distribute
make distribute-android

# Just build (no distribution)
make build-android

# Check Firebase project
firebase use

# List Firebase projects
firebase projects:list

# View distribution history
# Go to: https://console.firebase.google.com/project/ai-personas-app/appdistribution
```

---

## Next Steps

1. ✅ Create `internal-testers` group in Firebase Console
2. ✅ Add your email as a tester
3. ✅ Run `make distribute-android` to test
4. ✅ Check your email for the distribution notification
5. ✅ Download and install the APK on an Android device

**Ready to test once the group is created!** 🚀

