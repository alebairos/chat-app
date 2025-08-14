# FT-028: Simple Python TestFlight Automation

**Feature Type**: DevOps Automation  
**Priority**: High  
**Status**: Planning  
**Estimated Effort**: 1-2 hours  

## Problem Statement

Need a simple way to release the chat app to TestFlight for team distribution:

### Current Pain Points
1. **No team distribution**: App only runs on devices with Developer Mode
2. **Manual TestFlight process**: Complex Xcode archive/upload steps
3. **Time consuming**: 15-20 minutes of manual work per release
4. **Team barriers**: Technical setup prevents easy testing

### Desired Outcome
- **Single command**: `python scripts/deploy_testflight.py` → Team gets app
- **Professional distribution**: TestFlight like App Store experience
- **Zero technical barriers**: Team installs without Developer Mode

## Solution Overview

Create a **single Python script** that automates the entire TestFlight pipeline:

```
Python Script → Flutter Build → Xcode Archive → Upload → TestFlight → Team Notification
```

### Core Approach: Keep It Dead Simple
- ✅ **One script file**: `scripts/deploy_testflight.py`
- ✅ **Standard libraries only**: No complex dependencies
- ✅ **Command line tools**: Use existing `flutter`, `xcodebuild`, `xcrun`
- ✅ **Environment variables**: For secrets (API keys)
- ✅ **Progress feedback**: Clear terminal output

## Technical Requirements

### 1. Python Script Architecture

#### Single File Implementation
```python
# scripts/deploy_testflight.py
"""
Simple TestFlight deployment automation
Usage: python3 scripts/deploy_testflight.py [--notes "Release notes"]
"""

import subprocess
import os
import sys
import argparse
from datetime import datetime
```

#### Core Functions
```python
def build_flutter_ios():
    """Build Flutter iOS app"""
    
def create_xcode_archive():
    """Create Xcode archive"""
    
def upload_to_testflight():
    """Upload IPA to TestFlight using xcrun altool"""
    
def notify_team():
    """Send notification (optional)"""
    
def main():
    """Main deployment pipeline"""
```

### 2. Required Apple Account Info

You need these **4 pieces of information** from your Apple Developer account:

#### Required Credentials (.env file)
```bash
# .env file (not committed to git)
APPLE_ID=your.email@domain.com           # Your Apple ID email
APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx # Generated from appleid.apple.com
TEAM_ID=ABCD123456                       # 10-character team identifier  
BUNDLE_ID=com.yourcompany.chatapp        # App's bundle identifier
```

#### How to Get Each Credential:

**1. APPLE_ID**: Your Apple Developer account email

**2. APP_SPECIFIC_PASSWORD**:
- Go to https://appleid.apple.com
- Sign In → App-Specific Passwords → Generate
- Label: "TestFlight Upload"
- Copy the 16-character password (xxxx-xxxx-xxxx-xxxx)

**3. TEAM_ID**: 
- Go to https://developer.apple.com/account
- Membership tab → Team ID (10 characters like ABCD123456)

**4. BUNDLE_ID**:
- App Store Connect → Your App → App Information → Bundle ID
- Or create new one: `com.yourname.chatapp`

#### Required Tools (already installed)
- ✅ Flutter SDK
- ✅ Xcode command line tools
- ✅ xcrun (comes with Xcode)

### 3. Simple Implementation

#### Main Script Structure
```python
#!/usr/bin/env python3
# scripts/deploy_testflight.py

import subprocess
import os
import sys
import argparse
from datetime import datetime
from pathlib import Path

class TestFlightDeploy:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.build_dir = self.project_root / "build"
        self.load_env()
    
    def load_env(self):
        """Load environment variables from .env file"""
        env_file = self.project_root / ".env"
        if env_file.exists():
            with open(env_file) as f:
                for line in f:
                    if '=' in line and not line.startswith('#'):
                        key, value = line.strip().split('=', 1)
                        os.environ[key] = value
    
    def run_command(self, cmd, description):
        """Run shell command with progress feedback"""
        print(f"🔄 {description}...")
        try:
            result = subprocess.run(cmd, shell=True, check=True, 
                                  capture_output=True, text=True)
            print(f"✅ {description} completed")
            return result
        except subprocess.CalledProcessError as e:
            print(f"❌ {description} failed: {e}")
            print(f"Error output: {e.stderr}")
            sys.exit(1)
    
    def build_flutter(self):
        """Build Flutter iOS app"""
        self.run_command("flutter clean", "Cleaning Flutter project")
        self.run_command("flutter pub get", "Getting Flutter dependencies")
        self.run_command("flutter build ios --release", "Building Flutter iOS")
    
    def create_archive(self):
        """Create Xcode archive"""
        archive_path = self.build_dir / "ios" / "archive" / "Runner.xcarchive"
        cmd = f"""
        xcodebuild -workspace ios/Runner.xcworkspace \\
                   -scheme Runner \\
                   -configuration Release \\
                   -destination generic/platform=iOS \\
                   -archivePath {archive_path} \\
                   archive
        """
        self.run_command(cmd, "Creating Xcode archive")
        return archive_path
    
    def export_ipa(self, archive_path):
        """Export IPA for App Store distribution"""
        export_path = self.build_dir / "ios" / "ipa"
        cmd = f"""
        xcodebuild -exportArchive \\
                   -archivePath {archive_path} \\
                   -exportPath {export_path} \\
                   -exportOptionsPlist scripts/ExportOptions-AppStore.plist
        """
        self.run_command(cmd, "Exporting IPA")
        return export_path / "Runner.ipa"
    
    def upload_to_testflight(self, ipa_path):
        """Upload IPA to TestFlight"""
        apple_id = os.environ.get('APPLE_ID')
        password = os.environ.get('APP_SPECIFIC_PASSWORD')
        
        if not apple_id or not password:
            print("❌ Missing APPLE_ID or APP_SPECIFIC_PASSWORD in .env")
            sys.exit(1)
        
        cmd = f"""
        xcrun altool --upload-app \\
                     --type ios \\
                     --file {ipa_path} \\
                     --username {apple_id} \\
                     --password {password}
        """
        self.run_command(cmd, "Uploading to TestFlight")
    
    def deploy(self, release_notes=None):
        """Main deployment pipeline"""
        print("🚀 Starting TestFlight deployment...")
        print(f"📅 Build time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Build pipeline
        self.build_flutter()
        archive_path = self.create_archive()
        ipa_path = self.export_ipa(archive_path)
        self.upload_to_testflight(ipa_path)
        
        print("🎉 TestFlight deployment completed!")
        print("📱 Team will receive notification when processing completes (5-10 minutes)")
        
        if release_notes:
            print(f"📝 Release notes: {release_notes}")

def main():
    parser = argparse.ArgumentParser(description='Deploy to TestFlight')
    parser.add_argument('--notes', help='Release notes for this build')
    args = parser.parse_args()
    
    deployer = TestFlightDeploy()
    deployer.deploy(release_notes=args.notes)

if __name__ == '__main__':
    main()
```

#### Export Options Configuration
```xml
<!-- scripts/ExportOptions-AppStore.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>upload</string>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$(DEVELOPMENT_TEAM)</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

### 4. Setup Instructions

#### Setup Steps (30 minutes total)

**Step 1: Get Apple Credentials (10 minutes)**
1. **Apple ID**: Use your existing developer account email
2. **App-Specific Password**: Generate at https://appleid.apple.com
3. **Team ID**: Find at https://developer.apple.com/account
4. **Bundle ID**: Use existing or create new app in App Store Connect

**Step 2: Create App in App Store Connect (10 minutes)**
1. Go to https://appstoreconnect.apple.com
2. My Apps → + → New App
3. Fill basic info (name, bundle ID, SKU)
4. Save (don't need to complete everything)

**Step 3: Set Up TestFlight (10 minutes)**
1. In your app → TestFlight tab
2. Internal Testing → + → Create Group
3. Name: "Development Team"
4. Add team members by email
5. Save

**Step 4: Create .env File**
```bash
# Create .env in project root (don't commit to git)
echo "APPLE_ID=your.email@domain.com" > .env
echo "APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx" >> .env  
echo "TEAM_ID=ABCD123456" >> .env
echo "BUNDLE_ID=com.yourname.chatapp" >> .env
```

#### Git Ignore
```bash
# Add to .gitignore
.env
build/ios/ipa/
build/ios/archive/
```

## Usage Workflow

### For Developers (YOU) 
```bash
# Deploy to TestFlight (single command!)
python3 scripts/deploy_testflight.py

# With release notes for your team
python3 scripts/deploy_testflight.py --notes "Fixed login bug, added dark mode"

# That's it! Script handles: Build → Archive → Upload → TestFlight
# Takes ~10 minutes, team gets notification when ready
```

### For Team Members (AUTOMATIC)
```
1. Install TestFlight app from App Store (one-time)
2. Accept invitation email you send them (one-time)
3. Get automatic notification when new build ready 
4. Tap notification → Install → Use app (like App Store!)
5. No Developer Mode needed, no technical setup
```

## Implementation Plan

### Phase 1: Basic Script (30 minutes)
1. **Create Python script** with core functions
2. **Add export options plist** for App Store distribution  
3. **Test build pipeline** locally (without upload)

### Phase 2: Upload Integration (30 minutes)
1. **Configure Apple credentials** (App-Specific Password)
2. **Test upload to TestFlight** with xcrun altool
3. **Verify processing** in App Store Connect

### Phase 3: Team Setup (30 minutes)
1. **Create TestFlight testing group**
2. **Invite team members**
3. **Test end-to-end flow** with team installation

## Error Handling

### Common Issues & Solutions
```python
def handle_common_errors(self, error_output):
    """Provide helpful error messages"""
    if "No signing certificate" in error_output:
        print("💡 Fix: Open Xcode → Preferences → Accounts → Download Manual Profiles")
    
    elif "Invalid credentials" in error_output:
        print("💡 Fix: Check APPLE_ID and APP_SPECIFIC_PASSWORD in .env file")
    
    elif "No such provisioning profile" in error_output:
        print("💡 Fix: Refresh provisioning profiles in Xcode")
    
    else:
        print(f"❌ Unexpected error: {error_output}")
```

### Validation Checks
```python
def validate_environment(self):
    """Check prerequisites before starting"""
    errors = []
    
    # Check Flutter
    if not subprocess.run("flutter doctor", shell=True, capture_output=True).returncode == 0:
        errors.append("Flutter not properly installed")
    
    # Check Xcode
    if not subprocess.run("xcodebuild -version", shell=True, capture_output=True).returncode == 0:
        errors.append("Xcode command line tools not installed")
    
    # Check environment variables
    required_vars = ['APPLE_ID', 'APP_SPECIFIC_PASSWORD']
    for var in required_vars:
        if not os.environ.get(var):
            errors.append(f"Missing {var} in .env file")
    
    if errors:
        print("❌ Environment validation failed:")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)
    
    print("✅ Environment validation passed")
```

## Benefits

### Simplicity
- ✅ **Single command**: `python3 scripts/deploy_testflight.py`
- ✅ **No complex setup**: Uses existing tools
- ✅ **No external dependencies**: Standard Python libraries only
- ✅ **Clear output**: Progress feedback throughout

### Efficiency  
- ✅ **5-minute setup**: After Apple credentials configured
- ✅ **10-minute deployment**: Automated end-to-end
- ✅ **Zero manual steps**: Everything scripted
- ✅ **Reliable**: Same process every time

### Team Benefits
- ✅ **Professional distribution**: TestFlight like App Store
- ✅ **No Developer Mode**: Team members install normally
- ✅ **Automatic notifications**: TestFlight handles communication
- ✅ **Easy feedback**: Built-in TestFlight feedback system

## Cost Analysis

### Setup Cost
- **Time**: 1-2 hours one-time setup
- **Money**: $0 (uses existing Apple Developer Program)

### Ongoing Cost
- **Time per deployment**: ~2 minutes (vs 20 minutes manual)
- **Money**: $0 (TestFlight is free)
- **Maintenance**: Minimal (script handles edge cases)

### ROI Calculation
- **Time saved per deployment**: 18 minutes
- **Deployments per month**: 10
- **Total time saved**: 3 hours/month
- **Annual time savings**: 36 hours

## Risk Assessment

### Technical Risks
- **Apple credential changes**: App-Specific Passwords can expire
  - *Mitigation*: Clear error messages, documentation
- **Xcode updates**: Command line tools might change
  - *Mitigation*: Version checking, graceful degradation

### Process Risks
- **Build failures**: Broken builds block deployment
  - *Mitigation*: Validation checks before upload
- **TestFlight processing delays**: Apple's backend can be slow
  - *Mitigation*: Set expectations (5-10 minutes normal)

## Success Criteria

### Technical Success
- [x] Single Python command deploys to TestFlight
- [x] Build success rate > 95%
- [x] Upload completes in < 5 minutes
- [x] Team receives TestFlight notifications

### Process Success
- [x] Zero manual intervention required
- [x] Clear error messages for common issues
- [x] Team adoption: everyone uses TestFlight builds
- [x] Deployment frequency increases (easier = more frequent)

### Quality Success
- [x] Consistent build quality
- [x] Faster feedback cycles
- [x] Professional team experience
- [x] Reduced deployment friction

## Future Enhancements

### Advanced Features (Optional)
- **Slack notifications**: Send message when build ready
- **Version auto-increment**: Bump build numbers automatically
- **Git integration**: Tag releases, generate notes from commits
- **Build validation**: Run tests before upload

### Simple Additions
```python
# Optional: Slack notification
def notify_slack(self, webhook_url, message):
    """Send Slack notification"""
    import json
    import urllib.request
    
    payload = {"text": message}
    data = json.dumps(payload).encode()
    req = urllib.request.Request(webhook_url, data, 
                                {'Content-Type': 'application/json'})
    urllib.request.urlopen(req)

# Optional: Auto-increment version
def increment_build_number(self):
    """Auto-increment build number in Info.plist"""
    plist_path = "ios/Runner/Info.plist"
    # Read, increment, write back
```

## What You Need

### Already Have ✅
- Flutter SDK (already working)
- Xcode with command line tools (already installed)
- Apple Developer Program membership (you have this)
- Python 3 (comes with macOS)

### Need to Set Up (30 minutes)
- **Apple credentials**: 4 pieces of info for .env file
- **App Store Connect app**: Basic app listing 
- **TestFlight group**: Add your team members
- **Script**: The Python automation script

### Your Team Needs (5 minutes each)
- **TestFlight app**: Free download from App Store
- **Accept invitation**: Email you'll send them
- **That's it!**: No Developer Mode, no certificates, no Xcode

## Acceptance Criteria

1. **Script Functionality**
   - [ ] Single command deploys entire pipeline
   - [ ] Clear progress feedback throughout process
   - [ ] Handles common errors gracefully
   - [ ] Validates environment before starting

2. **Apple Integration**
   - [ ] Successfully uploads to TestFlight
   - [ ] App processes and becomes available
   - [ ] Team members receive notifications
   - [ ] Installation works without Developer Mode

3. **Developer Experience**
   - [ ] Setup time < 30 minutes after Apple credentials
   - [ ] Deployment time < 10 minutes end-to-end
   - [ ] Zero manual steps required
   - [ ] Works reliably across different machines

4. **Team Experience**
   - [ ] Professional installation experience
   - [ ] Automatic notifications
   - [ ] Easy feedback collection
   - [ ] No technical barriers

---

**Next Steps**: 
1. Create basic Python script structure
2. Configure Apple App-Specific Password
3. Test build pipeline without upload
4. Test upload to TestFlight
5. Set up team testing group and validate end-to-end flow
