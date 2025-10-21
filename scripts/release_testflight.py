#!/usr/bin/env python3
"""
Enhanced TestFlight Release Script with Protected Branch Workflow
Usage: 
  python3 scripts/release_testflight.py --version-bump patch    # Bug fixes (2.1.0 → 2.1.1)
  python3 scripts/release_testflight.py --version-bump minor   # New features (2.1.0 → 2.2.0)  
  python3 scripts/release_testflight.py --version-bump major   # Breaking changes (2.1.0 → 3.0.0)
  python3 scripts/release_testflight.py --verify              # Verify setup only
  python3 scripts/release_testflight.py --dry-run --version-bump patch  # Preview changes
  python3 scripts/release_testflight.py --force-branch --version-bump patch  # Emergency override

Features:
  - ✅ Branch validation (must be on 'develop')
  - ✅ Automatic version bumping in pubspec.yaml
  - ✅ CHANGELOG.md updates with release notes
  - ✅ Git commits and tagging
  - ✅ Complete TestFlight build and upload pipeline
  - ✅ Dry run mode for safe testing
"""

import subprocess
import os
import sys
import argparse
from pathlib import Path
from datetime import datetime

class TestFlightRelease:
    def __init__(self, force_branch=False, version_bump=None, dry_run=False):
        self.project_root = Path(__file__).parent.parent
        self.build_dir = self.project_root / "build"
        self.force_branch = force_branch
        self.version_bump = version_bump
        self.dry_run = dry_run
        self.load_env()
        self.validate_environment()
        if not force_branch:
            self.validate_branch()
    
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
    
    def validate_branch(self):
        """Ensure we're on the develop branch for releases"""
        try:
            result = subprocess.run(
                "git branch --show-current", 
                shell=True, 
                capture_output=True, 
                text=True
            )
            
            if result.returncode != 0:
                print("⚠️  Could not determine current git branch")
                return
            
            current_branch = result.stdout.strip()
            
            if current_branch != "develop":
                print(f"❌ Release must be from 'develop' branch")
                print(f"   Currently on: '{current_branch}'")
                print(f"   Switch to develop: git checkout develop")
                print(f"   Or use --force-branch to override")
                sys.exit(1)
            
            print(f"✅ On develop branch - ready for release")
            
        except Exception as e:
            print(f"⚠️  Could not verify git branch: {e}")
            if not self.force_branch:
                print("   Use --force-branch to skip branch validation")
                sys.exit(1)
    
    def validate_git_status(self):
        """Ensure working directory is clean"""
        try:
            result = subprocess.run(
                "git status --porcelain", 
                shell=True, 
                capture_output=True, 
                text=True
            )
            
            if result.returncode != 0:
                print("⚠️  Could not check git status")
                return
            
            if result.stdout.strip():
                print("❌ Working directory has uncommitted changes")
                print("   Commit or stash changes before releasing")
                print("   Or use --force-branch to override")
                if not self.force_branch:
                    sys.exit(1)
            else:
                print("✅ Working directory is clean")
                
        except Exception as e:
            print(f"⚠️  Could not verify git status: {e}")
    
    def get_current_version(self):
        """Parse current version from pubspec.yaml"""
        pubspec_file = self.project_root / "pubspec.yaml"
        
        if not pubspec_file.exists():
            raise FileNotFoundError("pubspec.yaml not found")
        
        with open(pubspec_file, 'r') as f:
            for line in f:
                if line.startswith('version:'):
                    # Extract version like "2.1.0+26"
                    version_line = line.split(':', 1)[1].strip()
                    return version_line
        
        raise ValueError("Version not found in pubspec.yaml")
    
    def parse_version(self, version_string):
        """Parse version string into components"""
        if '+' not in version_string:
            raise ValueError(f"Invalid version format: {version_string}")
        
        version_part, build_part = version_string.split('+')
        major, minor, patch = map(int, version_part.split('.'))
        build = int(build_part)
        
        return {
            'major': major,
            'minor': minor, 
            'patch': patch,
            'build': build,
            'version': version_part,
            'full': version_string
        }
    
    def bump_version(self, bump_type):
        """Increment version based on type and update pubspec.yaml"""
        if self.dry_run:
            print(f"🔍 DRY RUN: Would bump version ({bump_type})")
        
        current_version = self.get_current_version()
        parsed = self.parse_version(current_version)
        
        print(f"📋 Current version: {current_version}")
        
        # Increment version components
        if bump_type == 'patch':
            parsed['patch'] += 1
        elif bump_type == 'minor':
            parsed['minor'] += 1
            parsed['patch'] = 0
        elif bump_type == 'major':
            parsed['major'] += 1
            parsed['minor'] = 0
            parsed['patch'] = 0
        
        # Always increment build number
        parsed['build'] += 1
        
        # Create new version string
        new_version = f"{parsed['major']}.{parsed['minor']}.{parsed['patch']}"
        new_full_version = f"{new_version}+{parsed['build']}"
        
        print(f"📈 New version: {new_full_version}")
        
        if not self.dry_run:
            self.update_pubspec_version(new_full_version)
            self.update_changelog(new_version, bump_type)
            self.commit_version_changes(new_version, bump_type)
            self.create_git_tag(f"v{new_version}")
        else:
            print(f"🔍 DRY RUN: Would update CHANGELOG.md with version {new_version}")
            print(f"🔍 DRY RUN: Would commit version changes")
            print(f"🔍 DRY RUN: Would create git tag v{new_version}")
        
        return {
            'version': new_version,
            'full': new_full_version,
            'build': parsed['build']
        }
    
    def update_pubspec_version(self, new_version):
        """Update version in pubspec.yaml"""
        pubspec_file = self.project_root / "pubspec.yaml"
        
        with open(pubspec_file, 'r') as f:
            content = f.read()
        
        # Replace version line
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith('version:'):
                lines[i] = f"version: {new_version}"
                break
        
        with open(pubspec_file, 'w') as f:
            f.write('\n'.join(lines))
        
        print(f"✅ Updated pubspec.yaml with version {new_version}")
    
    def update_changelog(self, version, bump_type):
        """Update CHANGELOG.md with new version entry"""
        changelog_file = self.project_root / "CHANGELOG.md"
        
        # Create CHANGELOG.md if it doesn't exist
        if not changelog_file.exists():
            with open(changelog_file, 'w') as f:
                f.write("# Changelog\n\nAll notable changes to this project will be documented in this file.\n\n")
        
        # Read current content
        with open(changelog_file, 'r') as f:
            content = f.read()
        
        # Generate version entry
        date_str = datetime.now().strftime('%Y-%m-%d')
        bump_description = {
            'patch': 'Bug fixes and improvements',
            'minor': 'New features and enhancements', 
            'major': 'Major release with breaking changes'
        }
        
        new_entry = f"""## [{version}] - {date_str}

### {bump_description.get(bump_type, 'Changes')}
- Automated release via FT-214 Protected Branch Release Workflow
- Version bumped from previous release ({bump_type} increment)

"""
        
        # Insert new entry after the header
        lines = content.split('\n')
        header_end = 0
        
        # Find where to insert (after initial header/description)
        for i, line in enumerate(lines):
            if line.startswith('## ['):  # Found existing version entry
                header_end = i
                break
            elif line.startswith('# ') and 'Changelog' not in line:  # Found other header (not main title)
                header_end = i
                break
        
        # If no existing versions found, find insertion point after description
        if header_end == 0:
            # Look for the end of the description section
            found_title = False
            for i, line in enumerate(lines):
                if line.startswith('# ') and 'Changelog' in line:
                    found_title = True
                    continue
                # After finding title, look for first empty line that indicates end of description
                if found_title and line.strip() == '' and i > 2:
                    # Check if next line is also empty or is a version entry
                    if i + 1 < len(lines) and (lines[i + 1].strip() == '' or lines[i + 1].startswith('## [')):
                        header_end = i + 1
                        break
            
            # Final fallback: if still no insertion point found, add after a reasonable default
            if header_end == 0:
                # Find the main title and add some lines after it
                for i, line in enumerate(lines):
                    if line.startswith('# ') and 'Changelog' in line:
                        # Insert after title + empty line + description + empty line
                        header_end = min(i + 4, len(lines))
                        break
                
                # Ultimate fallback: add at end if nothing else works
                if header_end == 0:
                    header_end = len(lines)
        
        # Insert new entry
        lines.insert(header_end, new_entry)
        
        # Write updated content
        with open(changelog_file, 'w') as f:
            f.write('\n'.join(lines))
        
        print(f"✅ Updated CHANGELOG.md with version {version}")
    
    def commit_version_changes(self, version, bump_type):
        """Commit version changes to git"""
        try:
            # Add the changed files
            result = subprocess.run(
                "git add pubspec.yaml CHANGELOG.md",
                shell=True,
                capture_output=True,
                text=True
            )
            
            if result.returncode != 0:
                print(f"⚠️  Could not add files to git: {result.stderr}")
                return
            
            # Create commit message (sanitize version input)
            safe_version = version.replace('"', '\\"').replace('`', '\\`').replace('$', '\\$')
            commit_msg = f"chore: Bump version to {safe_version} ({bump_type})\n\n- Update pubspec.yaml version\n- Update CHANGELOG.md with release notes\n- Automated via FT-214 release workflow"
            
            # Commit the changes (SECURE: Use argument list instead of shell=True)
            result = subprocess.run(
                ["git", "commit", "-m", commit_msg],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print(f"✅ Committed version changes for {version}")
            else:
                print(f"⚠️  Could not commit changes: {result.stderr}")
                
        except Exception as e:
            print(f"⚠️  Could not commit version changes: {e}")
    
    def create_git_tag(self, tag_name):
        """Create git tag for the new version"""
        if self.dry_run:
            print(f"🔍 DRY RUN: Would create git tag {tag_name}")
            return
        
        try:
            # Check if tag already exists
            result = subprocess.run(
                f"git tag -l {tag_name}",
                shell=True,
                capture_output=True,
                text=True
            )
            
            if result.stdout.strip():
                print(f"⚠️  Tag {tag_name} already exists")
                return
            
            # Create the tag
            result = subprocess.run(
                f"git tag {tag_name}",
                shell=True,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print(f"✅ Created git tag {tag_name}")
            else:
                print(f"❌ Failed to create git tag: {result.stderr}")
                
        except Exception as e:
            print(f"⚠️  Could not create git tag: {e}")
    
    def verify_setup(self):
        """Verify all setup requirements for TestFlight release"""
        print("🔍 Verifying TestFlight setup...")
        print()
        
        checks_passed = 0
        total_checks = 7
        
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
        
        # Check 6: Branch Validation
        print("6. Checking git branch...")
        try:
            if not self.force_branch:
                self.validate_branch()
                checks_passed += 1
            else:
                print("   ⚠️  Branch validation skipped (--force-branch)")
                checks_passed += 1
        except SystemExit:
            print("   ❌ Branch validation failed")
        except:
            print("   ❌ Cannot verify git branch")
        
        # Check 7: Git Status
        print("7. Checking git status...")
        try:
            self.validate_git_status()
            checks_passed += 1
        except SystemExit:
            print("   ❌ Git status validation failed")
        except:
            print("   ❌ Cannot verify git status")
        
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
        
        # Handle version bumping if requested
        if self.version_bump:
            print("📈 Version Management")
            print("=" * 50)
            version_info = self.bump_version(self.version_bump)
            print()
        
        if self.dry_run:
            print("🔍 DRY RUN COMPLETE - No actual build or upload performed")
            return
        
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
    parser.add_argument('--force-branch', action='store_true',
                       help='Skip branch validation (emergency use only)')
    parser.add_argument('--version-bump', choices=['patch', 'minor', 'major'],
                       help='Automatically bump version (patch/minor/major)')
    parser.add_argument('--dry-run', action='store_true',
                       help='Preview changes without executing')
    args = parser.parse_args()
    
    try:
        releaser = TestFlightRelease(
            force_branch=args.force_branch,
            version_bump=args.version_bump,
            dry_run=args.dry_run
        )
        
        if args.verify:
            releaser.verify_setup()
        else:
            if args.dry_run:
                print("🔍 DRY RUN MODE - No changes will be made")
                print()
            releaser.release()
            
    except KeyboardInterrupt:
        print("\n❌ Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
