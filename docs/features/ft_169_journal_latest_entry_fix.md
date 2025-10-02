# FT-169: Journal Latest Entry Fix

## Feature Information
- **Feature ID**: FT-169
- **Category**: Bug Fix
- **Priority**: High
- **Effort Estimate**: 0.25 hours
- **Status**: Pending

## Problem Statement

### Current Issue
The journal UI shows old/stale content even after regeneration because `getJournalForDate()` uses `findFirst()` which returns the first database match, not the most recent one.

### Evidence
Database shows two PT entries for the same date:
```json
{"id":37,"createdAt":1759365905066184,"content":"Alexandre, você teve um ótimo dia hoje..."}
{"id":37,"createdAt":1759365905066184,"content":"Alexandre, você teve um ótimo dia hoje..."}
```

Both have the same ID but potentially different creation timestamps. The UI is showing the older entry.

### Root Cause
**File**: `lib/features/journal/services/journal_storage_service.dart`
**Method**: `getJournalForDate()` (lines 166-172)

```dart
final result = await isar.journalEntryModels
    .where()
    .filter()
    .dateEqualTo(normalizedDate)
    .and()
    .languageEqualTo(language)
    .findFirst(); // ❌ Returns first match, not latest
```

## Solution

### Approach
Change `getJournalForDate()` to return the **most recent** entry for a given date and language, not just the first one found.

### Implementation Strategy
1. **Sort by Creation Time**: Order results by `createdAt` descending
2. **Get Latest**: Use `findFirst()` on the sorted results
3. **Maintain Performance**: Still return only one result

### Code Changes

**File**: `lib/features/journal/services/journal_storage_service.dart`

**Before** (lines 166-172):
```dart
final result = await isar.journalEntryModels
    .where()
    .filter()
    .dateEqualTo(normalizedDate)
    .and()
    .languageEqualTo(language)
    .findFirst(); // ❌ First match (potentially old)
```

**After**:
```dart
final result = await isar.journalEntryModels
    .where()
    .filter()
    .dateEqualTo(normalizedDate)
    .and()
    .languageEqualTo(language)
    .sortByCreatedAtDesc() // ✅ Most recent first
    .findFirst(); // ✅ Latest entry
```

## Expected Results

### Functional Improvements
1. **Latest Content**: UI always shows the most recently generated journal
2. **Consistent Behavior**: Language switching shows current generation
3. **No Stale Data**: Old entries don't interfere with new ones

### Technical Benefits
1. **Database Integrity**: Handles duplicate entries gracefully
2. **Predictable Behavior**: Always returns newest entry for date/language
3. **Performance**: Still single query, just with proper sorting

## Implementation Notes

### Risk Assessment
- **Very Low Risk**: Simple query modification
- **No Breaking Changes**: Same API, better results
- **Performance**: Minimal impact (sorting is efficient)

### Alternative Approaches Considered
1. **Delete old entries**: More complex, potential data loss
2. **Unique constraints**: Would require migration
3. **Sort in application**: Less efficient than database sorting

## Acceptance Criteria

- [ ] `getJournalForDate()` returns the most recent entry for date/language
- [ ] UI shows latest generated content after regeneration
- [ ] Language switching displays current generation timestamp
- [ ] No performance degradation in journal loading
- [ ] Existing functionality remains unchanged
