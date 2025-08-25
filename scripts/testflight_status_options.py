#!/usr/bin/env python3
"""
TestFlight Status Checking Options
Shows all available methods to check upload status
"""

import subprocess
import os
import json

def check_with_altool():
    """Method 1: Using altool (basic, always available)"""
    print("1️⃣  ALTOOL METHOD (Basic)")
    print("=" * 30)
    print("✅ Always available")
    print("✅ No additional setup required")
    print("❌ Limited information")
    print()
    
    print("Commands:")
    print("  # List all apps")
    print("  xcrun altool --list-apps -u $APPLE_ID -p $APP_PASSWORD")
    print()
    print("  # JSON format")
    print("  xcrun altool --list-apps -u $APPLE_ID -p $APP_PASSWORD --output-format json")
    print()

def check_app_store_connect_api():
    """Method 2: App Store Connect API (comprehensive)"""
    print("2️⃣  APP STORE CONNECT API (Advanced)")
    print("=" * 40)
    print("✅ Comprehensive build information")
    print("✅ Processing status details")
    print("✅ Expiration dates")
    print("❌ Requires API key setup")
    print()
    
    print("Setup Required:")
    print("1. Go to App Store Connect → Users and Access → Keys")
    print("2. Create API Key with 'Developer' role")
    print("3. Download AuthKey_XXXXXXXXXX.p8 file")
    print("4. Add to .env:")
    print("   ASC_API_KEY_ID=your_key_id")
    print("   ASC_API_ISSUER_ID=your_issuer_id")
    print("   ASC_API_KEY_PATH=path/to/AuthKey_XXXXXXXXXX.p8")
    print()
    
    print("Install dependencies:")
    print("  pip install PyJWT requests")
    print()

def check_web_interface():
    """Method 3: Web interface (manual but reliable)"""
    print("3️⃣  WEB INTERFACE (Manual)")
    print("=" * 30)
    print("✅ Most reliable and up-to-date")
    print("✅ Visual interface")
    print("✅ Complete build details")
    print("❌ Manual process")
    print()
    
    print("Steps:")
    print("1. Visit: https://appstoreconnect.apple.com")
    print("2. Sign in with your Apple ID")
    print("3. Go to 'My Apps'")
    print("4. Select 'AI Chat App'")
    print("5. Click 'TestFlight' tab")
    print("6. Check 'iOS Builds' section")
    print("7. Look for version 1.1.0 builds")
    print()

def check_email_notifications():
    """Method 4: Email notifications"""
    print("4️⃣  EMAIL NOTIFICATIONS")
    print("=" * 25)
    print("✅ Automatic notifications")
    print("✅ Processing status updates")
    print("❌ Passive (wait for emails)")
    print()
    
    print("What to look for:")
    print("📧 'Your iOS app has been processed'")
    print("📧 'TestFlight build is ready'")
    print("📧 Processing error notifications")
    print()

def current_status_summary():
    """Show current status based on our investigation"""
    print("🎯 CURRENT STATUS SUMMARY")
    print("=" * 30)
    print("Based on debug logs analysis:")
    print()
    print("✅ Build 9 (1.1.0+9): Successfully uploaded at 19:15")
    print("✅ Build 10 (1.1.0+10): Successfully uploaded at 19:22")
    print("❌ Build 10 (retry): Failed at 19:32 - already exists")
    print()
    print("🔍 Evidence:")
    print("- Error messages confirm builds exist on Apple servers")
    print("- 'bundle version must be higher than previously uploaded version'")
    print("- This only happens AFTER successful upload")
    print()
    print("⏳ Likely Status:")
    print("- Builds are uploaded but still processing")
    print("- Apple processing can take 5-30 minutes")
    print("- Check App Store Connect web interface")
    print()

def main():
    print("📊 TestFlight Status Checking Guide")
    print("=" * 50)
    print()
    
    current_status_summary()
    print()
    
    check_with_altool()
    print()
    
    check_app_store_connect_api()
    print()
    
    check_web_interface()
    print()
    
    check_email_notifications()
    print()
    
    print("🚀 RECOMMENDED NEXT STEPS:")
    print("=" * 30)
    print("1. Check App Store Connect web interface (most reliable)")
    print("2. Check your email for Apple notifications")
    print("3. Wait 10-15 more minutes if still processing")
    print("4. Use our status checker: python3 scripts/check_testflight_status.py")

if __name__ == "__main__":
    main()
