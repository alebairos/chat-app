#!/usr/bin/env python3
"""
TestFlight Status Checker
Checks the status of uploaded builds using available APIs
"""

import subprocess
import os
import json
import sys
from datetime import datetime

class TestFlightStatusChecker:
    def __init__(self):
        self.load_env()
    
    def load_env(self):
        """Load environment variables from .env file"""
        env_path = '.env'
        if not os.path.exists(env_path):
            print("❌ .env file not found")
            sys.exit(1)
        
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value
        
        # Verify required variables
        required = ['APPLE_ID', 'APP_SPECIFIC_PASSWORD']
        for var in required:
            if var not in os.environ:
                print(f"❌ Missing required environment variable: {var}")
                sys.exit(1)
    
    def check_app_info(self):
        """Get basic app information"""
        print("🔍 Checking App Store Connect status...")
        print("=" * 50)
        
        try:
            cmd = [
                'xcrun', 'altool', '--list-apps',
                '-u', os.environ['APPLE_ID'],
                '-p', os.environ['APP_SPECIFIC_PASSWORD'],
                '--output-format', 'json'
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                try:
                    data = json.loads(result.stdout)
                    return data
                except json.JSONDecodeError:
                    # Fallback to normal format
                    print("📱 App Information (Raw):")
                    print(result.stdout)
                    return None
            else:
                print(f"❌ Error checking apps: {result.stderr}")
                return None
                
        except Exception as e:
            print(f"❌ Exception checking apps: {e}")
            return None
    
    def check_recent_uploads(self):
        """Check for recent upload activity"""
        print("\n📤 Recent Upload Activity:")
        print("=" * 30)
        
        # Check build directory for recent IPA files
        build_dir = "build/ios/ipa"
        if os.path.exists(build_dir):
            ipa_files = []
            for file in os.listdir(build_dir):
                if file.endswith('.ipa'):
                    file_path = os.path.join(build_dir, file)
                    stat = os.stat(file_path)
                    ipa_files.append({
                        'name': file,
                        'size': stat.st_size,
                        'modified': datetime.fromtimestamp(stat.st_mtime)
                    })
            
            if ipa_files:
                ipa_files.sort(key=lambda x: x['modified'], reverse=True)
                for ipa in ipa_files:
                    size_mb = ipa['size'] / (1024 * 1024)
                    print(f"📦 {ipa['name']}")
                    print(f"   📅 Modified: {ipa['modified'].strftime('%Y-%m-%d %H:%M:%S')}")
                    print(f"   📏 Size: {size_mb:.1f} MB")
                    print()
            else:
                print("❌ No IPA files found in build directory")
        else:
            print("❌ Build directory not found")
    
    def check_logs(self):
        """Check recent debug logs"""
        print("\n📋 Recent Debug Logs:")
        print("=" * 25)
        
        logs_dir = "logs"
        if os.path.exists(logs_dir):
            log_files = []
            for file in os.listdir(logs_dir):
                if file.startswith('testflight_debug_') and file.endswith('.log'):
                    file_path = os.path.join(logs_dir, file)
                    stat = os.stat(file_path)
                    log_files.append({
                        'name': file,
                        'modified': datetime.fromtimestamp(stat.st_mtime),
                        'path': file_path
                    })
            
            if log_files:
                log_files.sort(key=lambda x: x['modified'], reverse=True)
                latest_log = log_files[0]
                print(f"📄 Latest: {latest_log['name']}")
                print(f"📅 Modified: {latest_log['modified'].strftime('%Y-%m-%d %H:%M:%S')}")
                
                # Check for success/failure indicators in latest log
                try:
                    with open(latest_log['path'], 'r') as f:
                        content = f.read()
                        
                    if 'Successfully uploaded' in content:
                        print("✅ Latest log shows successful upload")
                    elif 'already been used' in content:
                        print("⚠️  Latest log shows version conflict (build already exists)")
                    elif 'ERROR' in content or 'Failed' in content:
                        print("❌ Latest log shows upload failure")
                    else:
                        print("ℹ️  Latest log status unclear")
                        
                except Exception as e:
                    print(f"❌ Error reading log: {e}")
            else:
                print("❌ No debug logs found")
        else:
            print("❌ Logs directory not found")
    
    def get_current_version(self):
        """Get current version from pubspec.yaml"""
        try:
            with open('pubspec.yaml', 'r') as f:
                for line in f:
                    if line.strip().startswith('version:'):
                        version = line.split(':', 1)[1].strip()
                        return version
        except Exception as e:
            print(f"❌ Error reading pubspec.yaml: {e}")
        return "Unknown"
    
    def check_app_store_connect_web(self):
        """Provide instructions for checking App Store Connect web interface"""
        print("\n🌐 App Store Connect Web Check:")
        print("=" * 35)
        print("1. Visit: https://appstoreconnect.apple.com")
        print("2. Go to 'My Apps' → 'AI Chat App'")
        print("3. Click 'TestFlight' tab")
        print("4. Look for 'iOS Builds' section")
        print("5. Check for version 1.1.0 with builds 9, 10")
        print("\n📧 Also check your email for Apple notifications")
    
    def run_status_check(self):
        """Run complete status check"""
        print("🚀 TestFlight Status Report")
        print("=" * 50)
        print(f"📅 Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"📱 Current Version: {self.get_current_version()}")
        print()
        
        # Check app info
        app_data = self.check_app_info()
        
        # Check recent uploads
        self.check_recent_uploads()
        
        # Check logs
        self.check_logs()
        
        # Web interface instructions
        self.check_app_store_connect_web()
        
        print("\n" + "=" * 50)
        print("✅ Status check complete!")

if __name__ == "__main__":
    checker = TestFlightStatusChecker()
    checker.run_status_check()
