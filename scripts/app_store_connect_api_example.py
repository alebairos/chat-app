#!/usr/bin/env python3
"""
App Store Connect API Example
More comprehensive way to check TestFlight status using the official API

To use this, you need:
1. App Store Connect API Key (AuthKey_XXXXXXXXXX.p8 file)
2. Key ID and Issuer ID from App Store Connect

Setup:
1. Go to App Store Connect → Users and Access → Keys
2. Create an API Key with "Developer" role
3. Download the .p8 file
4. Add to .env:
   ASC_API_KEY_ID=XXXXXXXXXX
   ASC_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ASC_API_KEY_PATH=path/to/AuthKey_XXXXXXXXXX.p8
"""

import jwt
import time
import requests
import json
import os
from datetime import datetime, timedelta

class AppStoreConnectAPI:
    def __init__(self):
        self.base_url = "https://api.appstoreconnect.apple.com/v1"
        self.load_credentials()
    
    def load_credentials(self):
        """Load API credentials from environment"""
        self.key_id = os.getenv('ASC_API_KEY_ID')
        self.issuer_id = os.getenv('ASC_API_ISSUER_ID') 
        self.key_path = os.getenv('ASC_API_KEY_PATH')
        
        if not all([self.key_id, self.issuer_id, self.key_path]):
            print("⚠️  App Store Connect API credentials not configured")
            print("   Add to .env file:")
            print("   ASC_API_KEY_ID=your_key_id")
            print("   ASC_API_ISSUER_ID=your_issuer_id")
            print("   ASC_API_KEY_PATH=path/to/AuthKey_XXXXXXXXXX.p8")
            return False
        
        if not os.path.exists(self.key_path):
            print(f"❌ API key file not found: {self.key_path}")
            return False
            
        return True
    
    def generate_token(self):
        """Generate JWT token for API authentication"""
        try:
            with open(self.key_path, 'r') as f:
                private_key = f.read()
            
            # Token expires in 20 minutes (max allowed)
            exp_time = int(time.time()) + 1200
            
            payload = {
                'iss': self.issuer_id,
                'exp': exp_time,
                'aud': 'appstoreconnect-v1'
            }
            
            headers = {
                'kid': self.key_id,
                'typ': 'JWT',
                'alg': 'ES256'
            }
            
            token = jwt.encode(payload, private_key, algorithm='ES256', headers=headers)
            return token
            
        except Exception as e:
            print(f"❌ Error generating token: {e}")
            return None
    
    def make_request(self, endpoint):
        """Make authenticated request to App Store Connect API"""
        token = self.generate_token()
        if not token:
            return None
        
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        
        try:
            response = requests.get(f"{self.base_url}{endpoint}", headers=headers)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"❌ API request failed: {e}")
            return None
    
    def get_apps(self):
        """Get list of apps"""
        return self.make_request("/apps")
    
    def get_builds(self, app_id):
        """Get builds for specific app"""
        return self.make_request(f"/builds?filter[app]={app_id}")
    
    def get_build_details(self, build_id):
        """Get detailed build information"""
        return self.make_request(f"/builds/{build_id}")
    
    def check_testflight_status(self):
        """Check TestFlight status using API"""
        print("🔗 App Store Connect API Status Check")
        print("=" * 40)
        
        if not self.load_credentials():
            return
        
        # Get apps
        apps_data = self.get_apps()
        if not apps_data:
            return
        
        # Find our app
        target_bundle_id = "com.lyfeab.chatapp"
        app_id = None
        
        for app in apps_data.get('data', []):
            if app['attributes']['bundleId'] == target_bundle_id:
                app_id = app['id']
                print(f"📱 Found app: {app['attributes']['name']}")
                print(f"🆔 App ID: {app_id}")
                break
        
        if not app_id:
            print(f"❌ App with bundle ID {target_bundle_id} not found")
            return
        
        # Get builds
        builds_data = self.get_builds(app_id)
        if not builds_data:
            return
        
        print(f"\n📦 Recent Builds:")
        print("-" * 20)
        
        builds = builds_data.get('data', [])
        if not builds:
            print("❌ No builds found")
            return
        
        # Sort by upload date
        builds.sort(key=lambda x: x['attributes']['uploadedDate'], reverse=True)
        
        for build in builds[:5]:  # Show last 5 builds
            attrs = build['attributes']
            upload_date = datetime.fromisoformat(attrs['uploadedDate'].replace('Z', '+00:00'))
            
            print(f"🔢 Build {attrs['version']} ({attrs['buildNumber']})")
            print(f"📅 Uploaded: {upload_date.strftime('%Y-%m-%d %H:%M:%S UTC')}")
            print(f"📊 Status: {attrs.get('processingState', 'Unknown')}")
            
            if 'expirationDate' in attrs and attrs['expirationDate']:
                exp_date = datetime.fromisoformat(attrs['expirationDate'].replace('Z', '+00:00'))
                print(f"⏰ Expires: {exp_date.strftime('%Y-%m-%d %H:%M:%S UTC')}")
            
            print()

def main():
    """Main function to demonstrate API usage"""
    print("📋 TestFlight Status Check Options")
    print("=" * 50)
    
    # Option 1: Basic altool check (always available)
    print("1️⃣  Basic Status (altool):")
    print("   python3 scripts/check_testflight_status.py")
    print()
    
    # Option 2: App Store Connect API (requires setup)
    print("2️⃣  Advanced Status (App Store Connect API):")
    api = AppStoreConnectAPI()
    api.check_testflight_status()
    
    print("\n🌐 Web Interface:")
    print("   https://appstoreconnect.apple.com")
    print("   → My Apps → AI Chat App → TestFlight")

if __name__ == "__main__":
    main()
