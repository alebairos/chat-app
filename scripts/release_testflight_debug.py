#!/usr/bin/env python3
"""
TestFlight Release Script with Debug Logging
Usage: 
  python3 scripts/release_testflight_debug.py         # Release to TestFlight
  python3 scripts/release_testflight_debug.py --verify # Verify setup only
"""

import subprocess
import os
import sys
import argparse
import json
import logging
from pathlib import Path
from datetime import datetime

class TestFlightDebugRelease:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.build_dir = self.project_root / "build"
        self.logs_dir = self.project_root / "logs"
        self.logs_dir.mkdir(exist_ok=True)
        
        # Setup debug logging
        self.setup_logging()
        
        self.load_env()
        self.validate_environment()
    
    def setup_logging(self):
        """Setup comprehensive logging for debug purposes"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        log_file = self.logs_dir / f"testflight_debug_{timestamp}.log"
        
        # Configure logging
        logging.basicConfig(
            level=logging.DEBUG,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        
        self.logger = logging.getLogger(__name__)
        self.logger.info("🔍 TestFlight Debug Release Started")
        self.logger.info(f"📝 Debug log file: {log_file}")
        
    def load_env(self):
        """Load environment variables from .env file"""
        env_file = self.project_root / ".env"
        self.logger.debug(f"Loading environment from: {env_file}")
        
        if not env_file.exists():
            self.logger.error("❌ No .env file found. Create .env with Apple credentials.")
            print("See docs/features/ft_028_1_prd_simple_testflight_release.md for setup.")
            sys.exit(1)
        
        env_vars_loaded = 0
        with open(env_file) as f:
            for line_num, line in enumerate(f, 1):
                if '=' in line and not line.startswith('#'):
                    key, value = line.strip().split('=', 1)
                    # Don't log sensitive values
                    if 'PASSWORD' in key or 'SECRET' in key:
                        self.logger.debug(f"Line {line_num}: {key}=***HIDDEN***")
                    else:
                        self.logger.debug(f"Line {line_num}: {key}={value}")
                    os.environ[key] = value.strip('"\'')
                    env_vars_loaded += 1
        
        self.logger.info(f"✅ Loaded {env_vars_loaded} environment variables")
    
    def validate_environment(self):
        """Check that required credentials are available"""
        required = ['APPLE_ID', 'APP_SPECIFIC_PASSWORD', 'TEAM_ID', 'BUNDLE_ID']
        missing = []
        
        for var in required:
            value = os.environ.get(var)
            if not value:
                missing.append(var)
                self.logger.error(f"❌ Missing environment variable: {var}")
            else:
                # Log non-sensitive vars
                if 'PASSWORD' not in var:
                    self.logger.debug(f"✅ {var}={value}")
                else:
                    self.logger.debug(f"✅ {var}=***HIDDEN*** (length: {len(value)})")
        
        if missing:
            self.logger.error(f"❌ Missing required environment variables: {', '.join(missing)}")
            print("Add them to .env file. See setup docs for details.")
            sys.exit(1)
        
        self.logger.info("✅ Environment validation passed")
        print("✅ Environment validation passed")
    
    def verify_setup(self):
        """Verify all setup requirements for TestFlight release"""
        self.logger.info("🔍 Starting TestFlight setup verification")
        print("🔍 Verifying TestFlight setup...")
        print()
        
        checks_passed = 0
        total_checks = 5
        
        # Check 1: Credentials
        print("1. Checking credentials...")
        self.logger.debug("Verifying credentials...")
        try:
            self.validate_environment()
            print("   ✅ All 4 credentials found in .env")
            checks_passed += 1
        except SystemExit:
            print("   ❌ Missing credentials")
            self.logger.error("Credentials check failed")
        
        # Check 2: Flutter
        print("2. Checking Flutter...")
        self.logger.debug("Testing Flutter installation...")
        try:
            result = subprocess.run("flutter --version", shell=True, capture_output=True, text=True)
            self.logger.debug(f"Flutter command result: {result.returncode}")
            self.logger.debug(f"Flutter stdout: {result.stdout}")
            if result.stderr:
                self.logger.debug(f"Flutter stderr: {result.stderr}")
                
            if result.returncode == 0:
                print("   ✅ Flutter is installed and working")
                checks_passed += 1
            else:
                print("   ❌ Flutter not working")
        except Exception as e:
            print("   ❌ Flutter not found")
            self.logger.error(f"Flutter check exception: {e}")
        
        # Check 3: Xcode
        print("3. Checking Xcode tools...")
        self.logger.debug("Testing Xcode tools...")
        try:
            result = subprocess.run("xcodebuild -version", shell=True, capture_output=True, text=True)
            self.logger.debug(f"Xcode command result: {result.returncode}")
            self.logger.debug(f"Xcode stdout: {result.stdout}")
            if result.stderr:
                self.logger.debug(f"Xcode stderr: {result.stderr}")
                
            if result.returncode == 0:
                print("   ✅ Xcode command line tools available")
                checks_passed += 1
            else:
                print("   ❌ Xcode tools not working")
        except Exception as e:
            print("   ❌ Xcode tools not found")
            self.logger.error(f"Xcode check exception: {e}")
        
        # Check 4: Apple Authentication
        print("4. Checking Apple authentication...")
        self.logger.debug("Testing Apple authentication...")
        try:
            apple_id = os.environ.get('APPLE_ID')
            password = os.environ.get('APP_SPECIFIC_PASSWORD')
            
            self.logger.debug(f"Testing auth for Apple ID: {apple_id}")
            
            # Test auth with a simple altool command
            cmd = f'xcrun altool --list-apps --type ios --username {apple_id} --password {password}'
            self.logger.debug(f"Running auth test command: xcrun altool --list-apps --type ios --username {apple_id} --password ***")
            
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            self.logger.debug(f"Auth test result: {result.returncode}")
            self.logger.debug(f"Auth test stdout: {result.stdout}")
            if result.stderr:
                self.logger.debug(f"Auth test stderr: {result.stderr}")
            
            if result.returncode == 0:
                print("   ✅ Apple authentication successful")
                checks_passed += 1
                
                # Parse and log app information
                if "Retrieved" in result.stdout:
                    self.logger.info("📱 Found registered apps in Apple Developer account")
                    for line in result.stdout.split('\n'):
                        if 'Application:' in line or 'Bundle ID:' in line or 'Apple ID:' in line:
                            self.logger.debug(f"   {line.strip()}")
            else:
                print("   ❌ Apple authentication failed")
                print(f"   Error: {result.stderr.strip()}")
                self.logger.error(f"Apple authentication failed: {result.stderr}")
        except Exception as e:
            print("   ❌ Cannot test Apple authentication")
            self.logger.error(f"Apple auth check exception: {e}")
        
        # Check 5: Bundle ID
        print("5. Checking Bundle ID...")
        self.logger.debug("Verifying Bundle ID configuration...")
        try:
            bundle_id = os.environ.get('BUNDLE_ID')
            project_file = self.project_root / "ios" / "Runner.xcodeproj" / "project.pbxproj"
            
            self.logger.debug(f"Looking for Bundle ID: {bundle_id}")
            self.logger.debug(f"In project file: {project_file}")
            
            if project_file.exists():
                with open(project_file, 'r') as f:
                    project_content = f.read()
                    if f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};" in project_content:
                        print(f"   ✅ Bundle ID {bundle_id} matches iOS project")
                        checks_passed += 1
                        self.logger.debug("Bundle ID verification successful")
                    else:
                        print(f"   ❌ Bundle ID {bundle_id} not found in iOS project")
                        print("   Update ios/Runner.xcodeproj/project.pbxproj PRODUCT_BUNDLE_IDENTIFIER")
                        self.logger.error(f"Bundle ID {bundle_id} not found in project file")
            else:
                print("   ❌ iOS project file not found")
                self.logger.error(f"iOS project file not found: {project_file}")
        except Exception as e:
            print("   ❌ Cannot verify Bundle ID")
            self.logger.error(f"Bundle ID check exception: {e}")
        
        print()
        print(f"📊 Verification Results: {checks_passed}/{total_checks} checks passed")
        self.logger.info(f"Verification completed: {checks_passed}/{total_checks} checks passed")
        
        if checks_passed == total_checks:
            print("🎉 All checks passed! Ready for TestFlight release")
            print("Run: python3 scripts/release_testflight_debug.py")
            self.logger.info("✅ All verification checks passed")
        else:
            print("❌ Some checks failed. Fix the issues above before releasing.")
            self.logger.error("❌ Verification failed - some checks did not pass")
            sys.exit(1)
    
    def run_command_with_debug(self, cmd, description, capture_sensitive=False):
        """Run shell command with comprehensive debug logging"""
        self.logger.info(f"🔄 Starting: {description}")
        
        # Log command (hide sensitive parts)
        if capture_sensitive:
            self.logger.debug(f"Command: {cmd.replace(os.environ.get('APP_SPECIFIC_PASSWORD', ''), '***PASSWORD***')}")
        else:
            self.logger.debug(f"Command: {cmd}")
        
        try:
            # Log environment info
            self.logger.debug(f"Working directory: {self.project_root}")
            self.logger.debug(f"Current user: {os.getenv('USER', 'unknown')}")
            
            result = subprocess.run(
                cmd, 
                shell=True, 
                capture_output=True, 
                text=True,
                cwd=self.project_root
            )
            
            # Log detailed results
            self.logger.debug(f"Return code: {result.returncode}")
            
            if result.stdout:
                self.logger.debug("=== STDOUT ===")
                for i, line in enumerate(result.stdout.split('\n'), 1):
                    if line.strip():
                        self.logger.debug(f"OUT {i:3d}: {line}")
                self.logger.debug("=== END STDOUT ===")
            
            if result.stderr:
                self.logger.debug("=== STDERR ===")
                for i, line in enumerate(result.stderr.split('\n'), 1):
                    if line.strip():
                        self.logger.debug(f"ERR {i:3d}: {line}")
                self.logger.debug("=== END STDERR ===")
            
            if result.returncode == 0:
                print(f"✅ {description} completed")
                self.logger.info(f"✅ {description} completed successfully")
                return result
            else:
                print(f"❌ {description} failed:")
                print(f"Command: {cmd}")
                print(f"Error: {result.stderr}")
                self.logger.error(f"❌ {description} failed with return code {result.returncode}")
                sys.exit(1)
                
        except Exception as e:
            print(f"❌ {description} failed with exception:")
            print(f"Command: {cmd}")
            print(f"Exception: {e}")
            self.logger.error(f"❌ {description} failed with exception: {e}")
            sys.exit(1)
    
    def check_current_version(self):
        """Check current app version and build number"""
        self.logger.info("🔍 Checking current version information")
        
        pubspec_file = self.project_root / "pubspec.yaml"
        if pubspec_file.exists():
            with open(pubspec_file, 'r') as f:
                content = f.read()
                for line in content.split('\n'):
                    if line.startswith('version:'):
                        version_info = line.split(':', 1)[1].strip()
                        self.logger.info(f"📱 Current version in pubspec.yaml: {version_info}")
                        print(f"📱 Current version: {version_info}")
                        
                        if '+' in version_info:
                            version, build = version_info.split('+')
                            self.logger.debug(f"   Version: {version}")
                            self.logger.debug(f"   Build: {build}")
                        break
    
    def check_existing_builds(self):
        """Check what builds already exist on App Store Connect"""
        self.logger.info("🔍 Checking existing builds on App Store Connect")
        
        apple_id = os.environ.get('APPLE_ID')
        password = os.environ.get('APP_SPECIFIC_PASSWORD')
        
        cmd = f'xcrun altool --list-apps --type ios --username {apple_id} --password {password}'
        
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            self.logger.debug("=== APP STORE CONNECT APPS ===")
            if result.stdout:
                for line in result.stdout.split('\n'):
                    if line.strip():
                        self.logger.debug(f"ASC: {line}")
                        if 'Application:' in line or 'Version Number:' in line or 'Bundle ID:' in line:
                            print(f"   {line.strip()}")
            
            if result.stderr:
                self.logger.debug("=== ASC STDERR ===")
                for line in result.stderr.split('\n'):
                    if line.strip():
                        self.logger.debug(f"ASC ERR: {line}")
            
        except Exception as e:
            self.logger.error(f"Failed to check existing builds: {e}")
    
    def build_flutter(self):
        """Build Flutter iOS app with debug logging"""
        print("🏗️ Building Flutter iOS app...")
        self.logger.info("🏗️ Starting Flutter iOS build process")
        
        self.run_command_with_debug("flutter clean", "Cleaning Flutter project")
        self.run_command_with_debug("flutter pub get", "Getting dependencies")
        self.run_command_with_debug("flutter build ios --release", "Building iOS release")
    
    def create_archive(self):
        """Create Xcode archive with debug logging"""
        print("📦 Creating Xcode archive...")
        self.logger.info("📦 Starting Xcode archive creation")
        
        archive_path = self.build_dir / "ios" / "archive" / "Runner.xcarchive"
        archive_path.parent.mkdir(parents=True, exist_ok=True)
        
        self.logger.debug(f"Archive will be created at: {archive_path}")
        
        cmd = f"""
        xcodebuild -workspace ios/Runner.xcworkspace \
                   -scheme Runner \
                   -configuration Release \
                   -destination generic/platform=iOS \
                   -archivePath {archive_path} \
                   archive
        """
        
        self.run_command_with_debug(cmd, "Creating archive")
        
        # Verify archive was created
        if archive_path.exists():
            self.logger.info(f"✅ Archive created successfully: {archive_path}")
            
            # Log archive info
            info_plist = archive_path / "Info.plist"
            if info_plist.exists():
                self.logger.debug("Reading archive Info.plist...")
                result = subprocess.run(f"plutil -p {info_plist}", shell=True, capture_output=True, text=True)
                if result.returncode == 0:
                    self.logger.debug("=== ARCHIVE INFO ===")
                    for line in result.stdout.split('\n'):
                        if line.strip():
                            self.logger.debug(f"ARCH: {line}")
        else:
            self.logger.error(f"❌ Archive not found at expected path: {archive_path}")
            
        return archive_path
    
    def export_ipa(self, archive_path):
        """Export IPA for TestFlight upload with debug logging"""
        print("📤 Exporting IPA...")
        self.logger.info("📤 Starting IPA export process")
        
        export_path = self.build_dir / "ios" / "ipa"
        export_path.mkdir(parents=True, exist_ok=True)
        
        self.logger.debug(f"Export path: {export_path}")
        
        # Create export options plist
        export_options = self.project_root / "scripts" / "ExportOptions-AppStore.plist"
        self.create_export_options(export_options)
        
        cmd = f"""
        xcodebuild -exportArchive \
                   -archivePath {archive_path} \
                   -exportPath {export_path} \
                   -exportOptionsPlist {export_options}
        """
        
        self.run_command_with_debug(cmd, "Exporting IPA")
        
        # Check if IPA was created and log details
        ipa_files = list(export_path.glob("*.ipa"))
        self.logger.debug(f"Found {len(ipa_files)} IPA files in export directory")
        
        for ipa_file in ipa_files:
            size_mb = ipa_file.stat().st_size / (1024 * 1024)
            self.logger.debug(f"IPA file: {ipa_file.name} ({size_mb:.1f} MB)")
        
        if not ipa_files:
            print("❌ IPA file not found after export")
            self.logger.error("❌ No IPA files found after export")
            
            # List all files in export directory for debugging
            all_files = list(export_path.rglob("*"))
            self.logger.debug("Files in export directory:")
            for file in all_files:
                if file.is_file():
                    self.logger.debug(f"  {file.relative_to(export_path)}")
            
            sys.exit(1)
        
        ipa_path = ipa_files[0]  # Use the first IPA file found
        self.logger.info(f"✅ IPA exported successfully: {ipa_path}")
        
        return ipa_path
    
    def create_export_options(self, plist_path):
        """Create export options plist for App Store distribution"""
        team_id = os.environ.get('TEAM_ID')
        
        self.logger.debug(f"Creating export options plist: {plist_path}")
        self.logger.debug(f"Using Team ID: {team_id}")
        
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
        
        self.logger.debug("Export options plist created successfully")
    
    def upload_to_testflight(self, ipa_path):
        """Upload IPA to TestFlight with comprehensive debug logging"""
        print("🚀 Uploading to TestFlight...")
        self.logger.info("🚀 Starting TestFlight upload process")
        
        apple_id = os.environ.get('APPLE_ID')
        password = os.environ.get('APP_SPECIFIC_PASSWORD')
        
        # Log upload details (without sensitive info)
        self.logger.info(f"📱 Uploading IPA: {ipa_path}")
        self.logger.info(f"👤 Apple ID: {apple_id}")
        
        # Check IPA file details before upload
        if ipa_path.exists():
            size_mb = ipa_path.stat().st_size / (1024 * 1024)
            self.logger.info(f"📦 IPA size: {size_mb:.1f} MB")
            
            # Extract and examine IPA contents
            self.logger.debug("🔍 Examining IPA contents...")
            temp_extract = self.build_dir / "temp_ipa_extract"
            temp_extract.mkdir(exist_ok=True)
            
            try:
                # Extract IPA to examine contents
                extract_cmd = f"unzip -q {ipa_path} -d {temp_extract}"
                result = subprocess.run(extract_cmd, shell=True, capture_output=True, text=True)
                
                if result.returncode == 0:
                    # Check app bundle info
                    app_bundle = None
                    payload_dir = temp_extract / "Payload"
                    if payload_dir.exists():
                        app_bundles = list(payload_dir.glob("*.app"))
                        if app_bundles:
                            app_bundle = app_bundles[0]
                            self.logger.debug(f"Found app bundle: {app_bundle.name}")
                            
                            # Read Info.plist from app bundle
                            info_plist = app_bundle / "Info.plist"
                            if info_plist.exists():
                                plist_cmd = f"plutil -p {info_plist}"
                                plist_result = subprocess.run(plist_cmd, shell=True, capture_output=True, text=True)
                                if plist_result.returncode == 0:
                                    self.logger.debug("=== APP BUNDLE INFO.PLIST ===")
                                    for line in plist_result.stdout.split('\n'):
                                        if any(key in line for key in ['CFBundleShortVersionString', 'CFBundleVersion', 'CFBundleIdentifier']):
                                            self.logger.info(f"📋 {line.strip()}")
                
                # Clean up temp extraction
                import shutil
                shutil.rmtree(temp_extract, ignore_errors=True)
                
            except Exception as e:
                self.logger.debug(f"Could not examine IPA contents: {e}")
        
        cmd = f"""
        xcrun altool --upload-app \
                     --type ios \
                     --file {ipa_path} \
                     --username {apple_id} \
                     --password {password} \
                     --verbose
        """
        
        self.logger.info("🔄 Starting altool upload...")
        self.run_command_with_debug(cmd, "Uploading to TestFlight", capture_sensitive=True)
        
        self.logger.info("✅ TestFlight upload completed successfully")
    
    def release(self):
        """Main release pipeline with comprehensive debug logging"""
        print("🎯 Starting TestFlight Release")
        print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        self.logger.info("🎯 Starting TestFlight Release Pipeline")
        self.logger.info(f"📅 Timestamp: {datetime.now().isoformat()}")
        
        # Pre-flight checks
        self.check_current_version()
        self.check_existing_builds()
        
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
        
        self.logger.info("🎉 TestFlight release pipeline completed successfully")
        self.logger.info("📝 Check the debug log file for detailed information")

def main():
    parser = argparse.ArgumentParser(description='TestFlight Debug Release Tool')
    parser.add_argument('--verify', action='store_true', 
                       help='Verify setup only (don\'t release)')
    args = parser.parse_args()
    
    try:
        releaser = TestFlightDebugRelease()
        
        if args.verify:
            releaser.verify_setup()
        else:
            releaser.release()
            
    except KeyboardInterrupt:
        print("\n❌ Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        logging.error(f"Unexpected error: {e}", exc_info=True)
        sys.exit(1)

if __name__ == '__main__':
    main()
