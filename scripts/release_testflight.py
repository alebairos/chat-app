#!/usr/bin/env python3
"""
Simple TestFlight Release Script
Usage: 
  python3 scripts/release_testflight.py         # Release to TestFlight
  python3 scripts/release_testflight.py --verify # Verify setup only
"""

import subprocess
import os
import sys
import argparse
from pathlib import Path
from datetime import datetime

class TestFlightRelease:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.build_dir = self.project_root / "build"
        self.load_env()
        self.validate_environment()
    
    def load_env(self):
        """Load environment variables from .env file"""
        env_file = self.project_root / ".env"
        if not env_file.exists():
            print("❌ No .env file found. Create .env with Apple credentials.")
            print("See docs/features/ft_028_1_prd_simple_testflight_release.md for setup.")
            sys.exit(1)
        
        with open(env_file) as f:
            for line in f:
                if '=' in line and not line.startswith('#'):
                    key, value = line.strip().split('=', 1)
                    os.environ[key] = value.strip('"\'')
    
    def validate_environment(self):
        """Check that required credentials are available"""
        required = ['APPLE_ID', 'APP_SPECIFIC_PASSWORD', 'TEAM_ID', 'BUNDLE_ID']
        missing = [var for var in required if not os.environ.get(var)]
        
        if missing:
            print(f"❌ Missing required environment variables: {', '.join(missing)}")
            print("Add them to .env file. See setup docs for details.")
            sys.exit(1)
        
        print("✅ Environment validation passed")
    
    def verify_setup(self):
        """Verify all setup requirements for TestFlight release"""
        print("🔍 Verifying TestFlight setup...")
        print()
        
        checks_passed = 0
        total_checks = 5
        
        # Check 1: Credentials
        print("1. Checking credentials...")
        try:
            self.validate_environment()
            print("   ✅ All 4 credentials found in .env")
            checks_passed += 1
        except SystemExit:
            print("   ❌ Missing credentials")
        
        # Check 2: Flutter
        print("2. Checking Flutter...")
        try:
            result = subprocess.run("flutter --version", shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                print("   ✅ Flutter is installed and working")
                checks_passed += 1
            else:
                print("   ❌ Flutter not working")
        except:
            print("   ❌ Flutter not found")
        
        # Check 3: Xcode
        print("3. Checking Xcode tools...")
        try:
            result = subprocess.run("xcodebuild -version", shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                print("   ✅ Xcode command line tools available")
                checks_passed += 1
            else:
                print("   ❌ Xcode tools not working")
        except:
            print("   ❌ Xcode tools not found")
        
        # Check 4: Apple Authentication
        print("4. Checking Apple authentication...")
        try:
            apple_id = os.environ.get('APPLE_ID')
            password = os.environ.get('APP_SPECIFIC_PASSWORD')
            
            # Test auth with a simple altool command
            cmd = f'xcrun altool --list-apps --type ios --username {apple_id} --password {password}'
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                print("   ✅ Apple authentication successful")
                checks_passed += 1
            else:
                print("   ❌ Apple authentication failed")
                print(f"   Error: {result.stderr.strip()}")
        except:
            print("   ❌ Cannot test Apple authentication")
        
        # Check 5: Bundle ID
        print("5. Checking Bundle ID...")
        try:
            bundle_id = os.environ.get('BUNDLE_ID')
            project_file = self.project_root / "ios" / "Runner.xcodeproj" / "project.pbxproj"
            
            if project_file.exists():
                with open(project_file, 'r') as f:
                    project_content = f.read()
                    if f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};" in project_content:
                        print(f"   ✅ Bundle ID {bundle_id} matches iOS project")
                        checks_passed += 1
                    else:
                        print(f"   ❌ Bundle ID {bundle_id} not found in iOS project")
                        print("   Update ios/Runner.xcodeproj/project.pbxproj PRODUCT_BUNDLE_IDENTIFIER")
            else:
                print("   ❌ iOS project file not found")
        except:
            print("   ❌ Cannot verify Bundle ID")
        
        print()
        print(f"📊 Verification Results: {checks_passed}/{total_checks} checks passed")
        
        if checks_passed == total_checks:
            print("🎉 All checks passed! Ready for TestFlight release")
            print("Run: python3 scripts/release_testflight.py")
        else:
            print("❌ Some checks failed. Fix the issues above before releasing.")
            sys.exit(1)
    
    def run_command(self, cmd, description):
        """Run shell command with progress feedback"""
        print(f"🔄 {description}...")
        try:
            result = subprocess.run(
                cmd, 
                shell=True, 
                check=True, 
                capture_output=True, 
                text=True,
                cwd=self.project_root
            )
            print(f"✅ {description} completed")
            return result
        except subprocess.CalledProcessError as e:
            print(f"❌ {description} failed:")
            print(f"Command: {cmd}")
            print(f"Error: {e.stderr}")
            sys.exit(1)
    
    def build_flutter(self):
        """Build Flutter iOS app"""
        print("🏗️ Building Flutter iOS app...")
        
        self.run_command("flutter clean", "Cleaning Flutter project")
        self.run_command("flutter pub get", "Getting dependencies")
        self.run_command("flutter build ios --release", "Building iOS release")
    
    def create_archive(self):
        """Create Xcode archive"""
        print("📦 Creating Xcode archive...")
        
        archive_path = self.build_dir / "ios" / "archive" / "Runner.xcarchive"
        archive_path.parent.mkdir(parents=True, exist_ok=True)
        
        cmd = f"""
        xcodebuild -workspace ios/Runner.xcworkspace \
                   -scheme Runner \
                   -configuration Release \
                   -destination generic/platform=iOS \
                   -archivePath {archive_path} \
                   archive
        """
        
        self.run_command(cmd, "Creating archive")
        return archive_path
    
    def export_ipa(self, archive_path):
        """Export IPA for TestFlight upload"""
        print("📤 Exporting IPA...")
        
        export_path = self.build_dir / "ios" / "ipa"
        export_path.mkdir(parents=True, exist_ok=True)
        
        # Create export options plist
        export_options = self.project_root / "scripts" / "ExportOptions-AppStore.plist"
        self.create_export_options(export_options)
        
        cmd = f"""
        xcodebuild -exportArchive \
                   -archivePath {archive_path} \
                   -exportPath {export_path} \
                   -exportOptionsPlist {export_options}
        """
        
        self.run_command(cmd, "Exporting IPA")
        
        # Check if IPA was created
        ipa_files = list(export_path.glob("*.ipa"))
        if not ipa_files:
            print("❌ IPA file not found after export")
            sys.exit(1)
        
        ipa_path = ipa_files[0]  # Use the first IPA file found
        
        return ipa_path
    
    def create_export_options(self, plist_path):
        """Create export options plist for App Store distribution"""
        team_id = os.environ.get('TEAM_ID')
        
        plist_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>{team_id}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>'''
        
        plist_path.parent.mkdir(parents=True, exist_ok=True)
        with open(plist_path, 'w') as f:
            f.write(plist_content)
    
    def upload_to_testflight(self, ipa_path):
        """Upload IPA to TestFlight"""
        print("🚀 Uploading to TestFlight...")
        
        apple_id = os.environ.get('APPLE_ID')
        password = os.environ.get('APP_SPECIFIC_PASSWORD')
        
        cmd = f"""
        xcrun altool --upload-app \
                     --type ios \
                     --file {ipa_path} \
                     --username {apple_id} \
                     --password {password}
        """
        
        self.run_command(cmd, "Uploading to TestFlight")
    
    def release(self):
        """Main release pipeline"""
        print("🎯 Starting TestFlight Release")
        print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Execute pipeline
        self.build_flutter()
        archive_path = self.create_archive()
        ipa_path = self.export_ipa(archive_path)
        self.upload_to_testflight(ipa_path)
        
        print()
        print("🎉 TestFlight release completed!")
        print("📱 Your team will receive TestFlight notification when processing completes")
        print("⏱️  Processing usually takes 5-10 minutes")
        print("🔗 Check status: https://appstoreconnect.apple.com")

def main():
    parser = argparse.ArgumentParser(description='TestFlight Release Tool')
    parser.add_argument('--verify', action='store_true', 
                       help='Verify setup only (don\'t release)')
    args = parser.parse_args()
    
    try:
        releaser = TestFlightRelease()
        
        if args.verify:
            releaser.verify_setup()
        else:
            releaser.release()
            
    except KeyboardInterrupt:
        print("\n❌ Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
