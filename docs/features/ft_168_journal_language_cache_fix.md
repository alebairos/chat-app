# FT-168: Journal Language Cache Fix

## Feature Information
- **Feature ID**: FT-168
- **Category**: Bug Fix
- **Priority**: High
- **Effort Estimate**: 0.5 hours
- **Status**: Pending

## Problem Statement

### Current Issue
When generating a journal entry while one language is selected (e.g., EN), the Portuguese (PT) version shows stale/cached content even though both languages are generated and saved to the database correctly.

### Root Cause Analysis
The bug is in `_generateJournalEntry()` in `lib/features/journal/screens/journal_screen.dart`:

1. **Generation Phase** ✅: Both PT and EN journals are generated and saved to database
2. **UI Update Phase** ❌: Only the currently selected language entry is loaded into `_currentJournalEntry` 
3. **Language Switch Phase** ❌: When switching languages, the stale UI cache persists instead of showing the fresh database content

### Code Location
**File**: `lib/features/journal/screens/journal_screen.dart`
**Lines**: 128-136 in `_generateJournalEntry()`

```dart
// Find the entry for the currently selected language
final currentLanguageEntry = entries.firstWhere(
  (entry) => entry.language == _selectedLanguage,
  orElse: () => entries.first,
);

if (mounted) {
  setState(() {
    _currentJournalEntry = currentLanguageEntry; // ❌ ONLY current language
    _isGenerating = false;
  });
}
```

### Evidence from Logs
- Database saves both languages: ✅ `JournalStorage: Saved journal entry for 2025-10-01 in pt_BR` and `en_US`
- UI only updates current language: ❌ Only the active language gets loaded into UI state
- Language switch finds stale entry: ❌ `JournalStorage: Found journal entry for 2025-10-01 in pt_BR` (old content)

## Solution

### Approach
After generating both language entries, clear the UI cache completely so that language switching always triggers a fresh database reload.

### Implementation Strategy
1. **Remove Language-Specific UI Update**: Don't set `_currentJournalEntry` to a specific language entry after generation
2. **Force Fresh Reload**: Set `_currentJournalEntry = null` to ensure `_loadJournalForDate()` fetches fresh data
3. **Maintain Success Feedback**: Keep the success message for user confirmation

### Code Changes

**File**: `lib/features/journal/screens/journal_screen.dart`

**Before** (lines 128-136):
```dart
// Find the entry for the currently selected language
final currentLanguageEntry = entries.firstWhere(
  (entry) => entry.language == _selectedLanguage,
  orElse: () => entries.first,
);

if (mounted) {
  setState(() {
    _currentJournalEntry = currentLanguageEntry; // ❌ Causes cache issue
    _isGenerating = false;
  });
}
```

**After**:
```dart
if (mounted) {
  setState(() {
    _currentJournalEntry = null; // ✅ Clear cache to force fresh reload
    _isGenerating = false;
  });

  // Trigger fresh reload from database for current language
  _loadJournalForDate();
}
```

## Expected Results

### Functional Improvements
1. **Consistent Content**: Both PT and EN show the same generation timestamp and content
2. **No Stale Cache**: Language switching always shows the latest generated content
3. **Reliable UX**: Users can generate once and switch languages to see both versions

### Technical Benefits
1. **Simplified State Management**: Eliminates language-specific caching logic
2. **Database as Source of Truth**: UI always reflects database state
3. **Reduced Complexity**: Fewer edge cases around cache invalidation

### User Experience
- Generate journal → Both languages have fresh content
- Switch PT ↔ EN → Always shows latest generated version
- No confusion about which content is current

## Testing Strategy

### Manual Testing
1. Generate journal while EN is selected
2. Switch to PT → Should show fresh content (same generation time)
3. Switch back to EN → Should show same fresh content
4. Verify both languages have identical metadata (generation time, message/activity counts)

### Automated Testing
- Add test case for dual-language generation and cache invalidation
- Verify `_loadJournalForDate()` is called after generation
- Ensure UI state is properly cleared before reload

## Implementation Notes

### Risk Assessment
- **Low Risk**: Simple state management fix
- **No Breaking Changes**: Maintains existing API and user flow
- **Performance**: Minimal impact (one additional database query)

### Dependencies
- No external dependencies
- Uses existing `_loadJournalForDate()` method
- Maintains current generation service API

## Acceptance Criteria

- [ ] Generate journal while EN selected → PT shows fresh content when switched
- [ ] Generate journal while PT selected → EN shows fresh content when switched  
- [ ] Both languages show identical generation metadata
- [ ] No stale cache issues during language switching
- [ ] Success message still appears after generation
- [ ] Loading states work correctly during reload
