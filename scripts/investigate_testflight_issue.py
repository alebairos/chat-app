#!/usr/bin/env python3
"""
TestFlight Issue Investigation
Systematic investigation when builds don't appear after upload
"""

import subprocess
import os
import json
import sys
from datetime import datetime

class TestFlightInvestigator:
    def __init__(self):
        self.load_env()
        self.issues_found = []
    
    def load_env(self):
        """Load environment variables"""
        env_path = '.env'
        if os.path.exists(env_path):
            with open(env_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        os.environ[key] = value
    
    def check_bundle_id_mismatch(self):
        """Check for bundle ID mismatches"""
        print("🔍 1. BUNDLE ID VERIFICATION")
        print("=" * 40)
        
        # Check pubspec.yaml
        try:
            with open('pubspec.yaml', 'r') as f:
                content = f.read()
                if 'name: ai_personas_app' in content:
                    print("✅ pubspec.yaml: ai_personas_app")
                else:
                    print("❌ pubspec.yaml: unexpected name")
                    self.issues_found.append("pubspec.yaml name mismatch")
        except Exception as e:
            print(f"❌ Error reading pubspec.yaml: {e}")
        
        # Check iOS Info.plist
        try:
            with open('ios/Runner/Info.plist', 'r') as f:
                content = f.read()
                if 'AI Personas App' in content:
                    print("✅ iOS Info.plist: AI Personas App")
                else:
                    print("❌ iOS Info.plist: name mismatch")
                    self.issues_found.append("iOS Info.plist name mismatch")
        except Exception as e:
            print(f"❌ Error reading iOS Info.plist: {e}")
        
        # Check iOS project bundle ID
        try:
            result = subprocess.run([
                'grep', '-r', 'PRODUCT_BUNDLE_IDENTIFIER', 'ios/Runner.xcodeproj/'
            ], capture_output=True, text=True)
            
            if 'com.lyfeab.chatapp' in result.stdout:
                print("✅ iOS Project: com.lyfeab.chatapp")
            else:
                print("❌ iOS Project: bundle ID mismatch")
                print(f"   Found: {result.stdout.strip()}")
                self.issues_found.append("iOS project bundle ID mismatch")
        except Exception as e:
            print(f"❌ Error checking iOS project: {e}")
        
        print()
    
    def check_app_store_connect_app(self):
        """Verify the app exists in App Store Connect"""
        print("🔍 2. APP STORE CONNECT VERIFICATION")
        print("=" * 45)
        
        try:
            cmd = [
                'xcrun', 'altool', '--list-apps',
                '-u', os.environ.get('APPLE_ID', ''),
                '-p', os.environ.get('APP_SPECIFIC_PASSWORD', ''),
                '--output-format', 'json'
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                try:
                    data = json.loads(result.stdout)
                    
                    # Look for our app
                    found_app = False
                    for app_key, app_id in data.get('applications', {}).items():
                        if 'AI Chat App' in app_key or 'com.lyfeab.chatapp' in app_key:
                            print(f"✅ Found app: {app_key}")
                            print(f"   Apple ID: {app_id}")
                            found_app = True
                            break
                    
                    if not found_app:
                        print("❌ App not found in App Store Connect")
                        print("   Available apps:")
                        for app_key, app_id in data.get('applications', {}).items():
                            print(f"   - {app_key}: {app_id}")
                        self.issues_found.append("App not found in App Store Connect")
                    
                except json.JSONDecodeError:
                    print("⚠️  JSON parsing failed, trying raw output...")
                    # Fallback to raw output
                    if 'AI Chat App' in result.stdout:
                        print("✅ Found app in raw output")
                    else:
                        print("❌ App not found in raw output")
                        self.issues_found.append("App not found in altool output")
            else:
                print(f"❌ altool failed: {result.stderr}")
                self.issues_found.append("altool authentication failed")
        
        except Exception as e:
            print(f"❌ Error checking App Store Connect: {e}")
        
        print()
    
    def check_signing_certificates(self):
        """Check code signing certificates"""
        print("🔍 3. CODE SIGNING VERIFICATION")
        print("=" * 40)
        
        try:
            result = subprocess.run([
                'security', 'find-identity', '-v', '-p', 'codesigning'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                identities = result.stdout.strip().split('\n')
                dev_certs = [line for line in identities if 'Apple Development' in line]
                dist_certs = [line for line in identities if 'Apple Distribution' in line or 'iOS Distribution' in line]
                
                print(f"📱 Development certificates: {len(dev_certs)}")
                for cert in dev_certs:
                    print(f"   {cert.strip()}")
                
                print(f"🏪 Distribution certificates: {len(dist_certs)}")
                for cert in dist_certs:
                    print(f"   {cert.strip()}")
                
                if not dist_certs:
                    print("⚠️  No distribution certificates found")
                    print("   This might explain TestFlight upload issues")
                    self.issues_found.append("No distribution certificates")
            else:
                print(f"❌ Error checking certificates: {result.stderr}")
        
        except Exception as e:
            print(f"❌ Error checking signing: {e}")
        
        print()
    
    def check_team_id_consistency(self):
        """Check team ID consistency"""
        print("🔍 4. TEAM ID VERIFICATION")
        print("=" * 35)
        
        env_team_id = os.environ.get('TEAM_ID', '')
        print(f"📝 .env TEAM_ID: {env_team_id}")
        
        # Check iOS project team ID
        try:
            result = subprocess.run([
                'grep', '-r', 'DEVELOPMENT_TEAM', 'ios/Runner.xcodeproj/'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                team_ids = set()
                for line in lines:
                    if 'DEVELOPMENT_TEAM' in line and '=' in line:
                        team_id = line.split('=')[1].strip().strip(';').strip('"')
                        if team_id:
                            team_ids.add(team_id)
                
                print(f"📱 iOS Project Team IDs: {list(team_ids)}")
                
                if env_team_id not in team_ids:
                    print("⚠️  Team ID mismatch between .env and iOS project")
                    self.issues_found.append("Team ID mismatch")
                else:
                    print("✅ Team ID consistent")
            else:
                print("❌ Could not find team ID in iOS project")
        
        except Exception as e:
            print(f"❌ Error checking team ID: {e}")
        
        print()
    
    def check_recent_build_artifacts(self):
        """Check build artifacts and their properties"""
        print("🔍 5. BUILD ARTIFACTS ANALYSIS")
        print("=" * 40)
        
        # Check IPA file
        ipa_path = "build/ios/ipa/ai_personas_app.ipa"
        if os.path.exists(ipa_path):
            stat = os.stat(ipa_path)
            size_mb = stat.st_size / (1024 * 1024)
            mod_time = datetime.fromtimestamp(stat.st_mtime)
            
            print(f"📦 IPA File: {ipa_path}")
            print(f"   Size: {size_mb:.1f} MB")
            print(f"   Modified: {mod_time.strftime('%Y-%m-%d %H:%M:%S')}")
            
            # Extract and check Info.plist from IPA
            try:
                # Create temp directory and extract
                import tempfile
                import zipfile
                
                with tempfile.TemporaryDirectory() as temp_dir:
                    with zipfile.ZipFile(ipa_path, 'r') as zip_ref:
                        zip_ref.extractall(temp_dir)
                    
                    # Find Info.plist
                    info_plist_path = None
                    for root, dirs, files in os.walk(temp_dir):
                        if 'Info.plist' in files and 'Payload' in root:
                            info_plist_path = os.path.join(root, 'Info.plist')
                            break
                    
                    if info_plist_path:
                        result = subprocess.run([
                            'plutil', '-p', info_plist_path
                        ], capture_output=True, text=True)
                        
                        if result.returncode == 0:
                            plist_content = result.stdout
                            
                            # Extract key values
                            bundle_id = None
                            version = None
                            build = None
                            display_name = None
                            
                            for line in plist_content.split('\n'):
                                if 'CFBundleIdentifier' in line:
                                    bundle_id = line.split('"')[1] if '"' in line else None
                                elif 'CFBundleShortVersionString' in line:
                                    version = line.split('"')[1] if '"' in line else None
                                elif 'CFBundleVersion' in line:
                                    build = line.split('"')[1] if '"' in line else None
                                elif 'CFBundleDisplayName' in line:
                                    display_name = line.split('"')[1] if '"' in line else None
                            
                            print(f"   Bundle ID: {bundle_id}")
                            print(f"   Version: {version}")
                            print(f"   Build: {build}")
                            print(f"   Display Name: {display_name}")
                            
                            # Check for issues
                            if bundle_id != 'com.lyfeab.chatapp':
                                print(f"   ⚠️  Bundle ID mismatch: expected com.lyfeab.chatapp")
                                self.issues_found.append(f"IPA bundle ID mismatch: {bundle_id}")
                            
                            if version != '1.1.0':
                                print(f"   ⚠️  Version mismatch: expected 1.1.0")
                                self.issues_found.append(f"IPA version mismatch: {version}")
                        
                        else:
                            print("   ❌ Could not read Info.plist from IPA")
                    else:
                        print("   ❌ Info.plist not found in IPA")
            
            except Exception as e:
                print(f"   ❌ Error analyzing IPA: {e}")
        else:
            print("❌ No IPA file found")
            self.issues_found.append("No IPA file found")
        
        print()
    
    def check_upload_logs_for_errors(self):
        """Analyze upload logs for specific error patterns"""
        print("🔍 6. UPLOAD LOG ANALYSIS")
        print("=" * 35)
        
        logs_dir = "logs"
        if os.path.exists(logs_dir):
            log_files = []
            for file in os.listdir(logs_dir):
                if file.startswith('testflight_debug_') and file.endswith('.log'):
                    file_path = os.path.join(logs_dir, file)
                    stat = os.stat(file_path)
                    log_files.append({
                        'name': file,
                        'path': file_path,
                        'modified': datetime.fromtimestamp(stat.st_mtime)
                    })
            
            if log_files:
                # Check the most recent log
                log_files.sort(key=lambda x: x['modified'], reverse=True)
                latest_log = log_files[0]
                
                print(f"📄 Analyzing: {latest_log['name']}")
                
                try:
                    with open(latest_log['path'], 'r') as f:
                        content = f.read()
                    
                    # Look for specific error patterns
                    error_patterns = [
                        ('Bundle ID mismatch', 'bundle.*identifier.*mismatch'),
                        ('Invalid signature', 'signature.*invalid|codesign.*error'),
                        ('Team ID issue', 'team.*id.*invalid|team.*not.*found'),
                        ('Certificate issue', 'certificate.*not.*found|certificate.*invalid'),
                        ('Network timeout', 'timeout|network.*error'),
                        ('Authentication failed', 'authentication.*failed|unauthorized'),
                        ('App not found', 'app.*not.*found|application.*not.*found'),
                        ('Version conflict', 'version.*conflict|already.*used'),
                    ]
                    
                    import re
                    
                    found_errors = []
                    for error_name, pattern in error_patterns:
                        if re.search(pattern, content, re.IGNORECASE):
                            found_errors.append(error_name)
                    
                    if found_errors:
                        print("⚠️  Potential issues found:")
                        for error in found_errors:
                            print(f"   - {error}")
                            self.issues_found.append(f"Log analysis: {error}")
                    else:
                        print("✅ No obvious error patterns found")
                    
                    # Check for success indicators
                    if 'successfully uploaded' in content.lower():
                        print("✅ Log indicates successful upload")
                    elif 'upload completed' in content.lower():
                        print("✅ Log indicates upload completion")
                    else:
                        print("⚠️  No clear success indicator found")
                
                except Exception as e:
                    print(f"❌ Error reading log: {e}")
            else:
                print("❌ No debug logs found")
        else:
            print("❌ Logs directory not found")
        
        print()
    
    def suggest_solutions(self):
        """Suggest solutions based on found issues"""
        print("💡 SUGGESTED SOLUTIONS")
        print("=" * 30)
        
        if not self.issues_found:
            print("🤔 No obvious issues found. Possible causes:")
            print("1. App Store Connect sync delay (rare but possible)")
            print("2. Apple server issues")
            print("3. Account permissions issue")
            print("4. App was uploaded to wrong Apple ID")
            print()
            print("🔧 Try these steps:")
            print("1. Double-check you're logged into correct Apple ID")
            print("2. Check 'Activity' tab in App Store Connect")
            print("3. Try uploading with Xcode directly")
            print("4. Contact Apple Developer Support")
        else:
            print("🚨 Issues found:")
            for i, issue in enumerate(self.issues_found, 1):
                print(f"{i}. {issue}")
            
            print("\n🔧 Recommended fixes:")
            
            if any('bundle id' in issue.lower() for issue in self.issues_found):
                print("- Fix bundle ID consistency across all config files")
            
            if any('certificate' in issue.lower() for issue in self.issues_found):
                print("- Install proper distribution certificates")
                print("- Check Apple Developer account status")
            
            if any('team id' in issue.lower() for issue in self.issues_found):
                print("- Update team ID in iOS project settings")
            
            if any('app not found' in issue.lower() for issue in self.issues_found):
                print("- Verify app exists in App Store Connect")
                print("- Check you're using correct Apple ID")
        
        print()
    
    def run_investigation(self):
        """Run complete investigation"""
        print("🕵️  TestFlight Upload Investigation")
        print("=" * 50)
        print(f"📅 Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        self.check_bundle_id_mismatch()
        self.check_app_store_connect_app()
        self.check_signing_certificates()
        self.check_team_id_consistency()
        self.check_recent_build_artifacts()
        self.check_upload_logs_for_errors()
        
        self.suggest_solutions()
        
        print("=" * 50)
        print("🔍 Investigation complete!")

if __name__ == "__main__":
    investigator = TestFlightInvestigator()
    investigator.run_investigation()
