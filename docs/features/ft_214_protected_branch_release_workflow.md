# FT-214: Protected Branch Release Workflow Enhancement

**Feature ID:** FT-214  
**Priority:** High  
**Category:** DevOps / Release Management  
**Effort Estimate:** 2-3 hours  
**Status:** Specification  
**Created:** October 20, 2025  

## Problem Statement

With the implementation of protected branches (`main` and `develop`) in GitHub, the current release workflow needs enhancement to:

1. **Enforce Branch Safety**: Prevent accidental releases from wrong branches
2. **Automate Version Management**: Handle version bumps within the release script
3. **Update Documentation**: Reflect new protected branch workflow

### Current Limitations

- ❌ **No Branch Validation**: Script can run from any branch without warning
- ❌ **Manual Version Bumps**: Requires separate commits for version changes
- ❌ **Outdated Documentation**: README doesn't reflect protected branch workflow
- ❌ **No Safety Checks**: Easy to accidentally release from feature branches

## Solution Overview

Enhance the existing `release_testflight.py` script with:

1. **Branch Validation**: Mandatory check for `develop` branch
2. **Automated Version Bumping**: Integrated version management
3. **Enhanced Safety**: Multiple validation layers
4. **Updated Documentation**: Complete workflow documentation

## Functional Requirements

### FR-214-1: Branch Validation
- **Mandatory Branch Check**: Script must verify current branch is `develop`
- **Clear Error Messages**: Informative guidance when on wrong branch
- **Override Option**: `--force-branch` flag for emergency releases
- **Status Display**: Show current branch in verification output

### FR-214-2: Automated Version Management
- **Version Detection**: Parse current version from `pubspec.yaml`
- **Increment Options**: Support patch, minor, major version bumps
- **Git Tag Creation**: Automatically create version tags
- **Changelog Integration**: Update CHANGELOG.md with new version

### FR-214-3: Enhanced Release Options
- **Branch Safety**: `--branch-check` (default enabled)
- **Version Bumping**: `--version-bump [patch|minor|major]`
- **Force Override**: `--force-branch` for emergency use
- **Dry Run**: `--dry-run` to preview changes without execution

### FR-214-4: Documentation Updates
- **README Enhancement**: Update with new protected branch workflow
- **Release Process**: Step-by-step guide for new workflow
- **Troubleshooting**: Common issues and solutions

## Technical Implementation

### 1. Enhanced Script Structure

```python
class TestFlightRelease:
    def __init__(self, force_branch=False, version_bump=None):
        self.project_root = Path(__file__).parent.parent
        self.force_branch = force_branch
        self.version_bump = version_bump
        self.load_env()
        self.validate_environment()
        if not force_branch:
            self.validate_branch()
    
    def validate_branch(self):
        """Ensure we're on the develop branch for releases"""
        
    def get_current_version(self):
        """Parse current version from pubspec.yaml"""
        
    def bump_version(self, bump_type):
        """Increment version and update files"""
        
    def create_git_tag(self, version):
        """Create git tag for the new version"""
        
    def update_changelog(self, version):
        """Add new version entry to CHANGELOG.md"""
```

### 2. New Command Line Options

```bash
# Standard release (with branch check and version bump)
python3 scripts/release_testflight.py --version-bump patch

# Verify setup only
python3 scripts/release_testflight.py --verify

# Upload without distribution
python3 scripts/release_testflight.py --upload-only --version-bump minor

# Emergency release (bypass branch check)
python3 scripts/release_testflight.py --force-branch --version-bump patch

# Dry run (preview changes)
python3 scripts/release_testflight.py --dry-run --version-bump major
```

### 3. Version Bumping Logic

```python
def bump_version(self, bump_type):
    """
    Increment version based on type:
    - patch: 2.1.0 → 2.1.1 (bug fixes)
    - minor: 2.1.0 → 2.2.0 (new features)
    - major: 2.1.0 → 3.0.0 (breaking changes)
    """
    current = self.get_current_version()  # e.g., "2.1.0+26"
    version, build = current.split('+')
    major, minor, patch = map(int, version.split('.'))
    
    if bump_type == 'patch':
        patch += 1
    elif bump_type == 'minor':
        minor += 1
        patch = 0
    elif bump_type == 'major':
        major += 1
        minor = 0
        patch = 0
    
    new_build = int(build) + 1
    new_version = f"{major}.{minor}.{patch}+{new_build}"
    
    # Update pubspec.yaml
    self.update_pubspec_version(new_version)
    
    # Update CHANGELOG.md
    self.update_changelog(f"{major}.{minor}.{patch}")
    
    # Create git tag
    self.create_git_tag(f"v{major}.{minor}.{patch}")
    
    return new_version
```

### 4. Branch Validation Implementation

```python
def validate_branch(self):
    """Ensure we're on the develop branch for releases"""
    try:
        result = subprocess.run(
            "git branch --show-current", 
            shell=True, 
            capture_output=True, 
            text=True
        )
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
            sys.exit(1)
```

## New Release Workflow

### Standard Release Process

```bash
# 1. Ensure you're on develop and up to date
git checkout develop
git pull origin develop

# 2. Run release with version bump
python3 scripts/release_testflight.py --version-bump patch

# 3. Script automatically:
#    - Validates branch (develop)
#    - Bumps version in pubspec.yaml
#    - Updates CHANGELOG.md
#    - Creates git tag
#    - Builds and uploads to TestFlight
#    - Commits version changes

# 4. Push changes (if auto-commit enabled)
git push origin develop --tags
```

### Emergency Release Process

```bash
# For hotfixes or emergency releases from other branches
python3 scripts/release_testflight.py --force-branch --version-bump patch
```

## Updated Verification Checks

Enhance the existing 5-check system to 7 checks:

1. ✅ **Credentials** (existing)
2. ✅ **Flutter** (existing)  
3. ✅ **Xcode Tools** (existing)
4. ✅ **Apple Authentication** (existing)
5. ✅ **Bundle ID** (existing)
6. 🆕 **Branch Validation** (new)
7. 🆕 **Git Status** (new - ensure clean working directory)

## Documentation Updates

### README.md Enhancements

```markdown
## 🚀 Release Process

### Prerequisites
- Ensure you're on the `develop` branch
- Working directory is clean (no uncommitted changes)
- All tests passing

### Standard Release
```bash
# Patch release (bug fixes)
python3 scripts/release_testflight.py --version-bump patch

# Minor release (new features)  
python3 scripts/release_testflight.py --version-bump minor

# Major release (breaking changes)
python3 scripts/release_testflight.py --version-bump major
```

### Protected Branch Workflow
- `main`: Production-ready code, protected
- `develop`: Integration branch for releases, protected  
- Feature branches: Merge to `develop` via PR
- Releases: Always from `develop` branch
```

## Acceptance Criteria

### Core Functionality
- [ ] Script validates current branch is `develop` before releasing
- [ ] Automated version bumping for patch/minor/major releases
- [ ] Git tag creation with proper version format (`v2.1.1`)
- [ ] CHANGELOG.md automatic updates with new version entries
- [ ] All existing TestFlight functionality preserved

### Safety & Validation
- [ ] Clear error messages when on wrong branch
- [ ] `--force-branch` override for emergency releases
- [ ] Clean working directory validation
- [ ] Dry run mode for previewing changes

### Documentation
- [ ] README updated with new protected branch workflow
- [ ] Release process documentation complete
- [ ] Troubleshooting guide for common issues
- [ ] Command line help text updated

### Backward Compatibility
- [ ] Existing `--verify` flag continues to work
- [ ] Existing `--upload-only` flag preserved (if implemented)
- [ ] No breaking changes to current usage patterns

## Implementation Plan

### Phase 1: Core Branch Validation (30 minutes)
1. Add branch validation method
2. Integrate with existing verification system
3. Add `--force-branch` override option

### Phase 2: Version Management (60 minutes)
1. Implement version parsing from pubspec.yaml
2. Add version bumping logic (patch/minor/major)
3. Update pubspec.yaml with new versions
4. Create git tags automatically

### Phase 3: Enhanced Features (45 minutes)
1. CHANGELOG.md integration
2. Git status validation (clean working directory)
3. Dry run mode implementation
4. Enhanced command line options

### Phase 4: Documentation (30 minutes)
1. Update README.md with new workflow
2. Add troubleshooting section
3. Update command line help text
4. Create release process guide

## Risk Assessment

**Low Risk Implementation:**
- ✅ **Additive Changes**: All enhancements are additions, not modifications
- ✅ **Backward Compatible**: Existing usage patterns preserved
- ✅ **Override Options**: `--force-branch` for emergency scenarios
- ✅ **Dry Run**: Safe testing of changes before execution

**Mitigation Strategies:**
- Comprehensive testing on develop branch before merging
- `--force-branch` escape hatch for emergencies
- Detailed error messages and troubleshooting guides
- Gradual rollout with team training

## Success Metrics

- ✅ **Zero Wrong-Branch Releases**: No accidental releases from feature branches
- ✅ **Automated Version Management**: No manual pubspec.yaml editing required
- ✅ **Consistent Git Tags**: All releases have proper version tags
- ✅ **Updated Documentation**: Team can follow new workflow easily
- ✅ **Maintained Reliability**: All existing TestFlight functionality works

---

**This enhancement transforms the release process from manual and error-prone to automated and safe, while maintaining full compatibility with existing workflows and providing escape hatches for emergency scenarios.**
