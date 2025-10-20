# FT-210: Fix Journal Database Connection Errors

## Problem Statement

Journal generation and storage services are failing with "IsarError: Isar instance has already been closed" errors when switching personas or generating journals.

## Root Cause Analysis

### Evidence from Logs:
```
❌ [ERROR] JournalStorage: Failed to get journal for date: IsarError: Isar instance has already been closed
❌ [ERROR] JournalGeneration: Failed to aggregate day data: IsarError: Isar instance has already been closed
❌ [ERROR] JournalScreen: Failed to load journal for date: IsarError: Isar instance has already been closed
```

### Technical Analysis:
Journal services are creating **new instances** of `ChatStorageService` instead of using the singleton pattern implemented in FT-209, causing database connection conflicts.

**Affected Code:**
1. `lib/features/journal/services/journal_generation_service.dart:89`
   ```dart
   final chatStorage = ChatStorageService(); // ❌ Creates new instance
   ```

2. `lib/features/journal/services/journal_storage_service.dart:14`
   ```dart
   final chatStorage = ChatStorageService(); // ❌ Creates new instance
   ```

## Solution

Update journal services to use the singleton pattern implemented in FT-209.

### Changes Required:

#### 1. JournalGenerationService
**File:** `lib/features/journal/services/journal_generation_service.dart`
**Line 89:** Change from:
```dart
final chatStorage = ChatStorageService();
```
To:
```dart
final chatStorage = ChatStorageService.instance;
```

#### 2. JournalStorageService
**File:** `lib/features/journal/services/journal_storage_service.dart`
**Line 14:** Change from:
```dart
final chatStorage = ChatStorageService();
```
To:
```dart
final chatStorage = ChatStorageService.instance;
```

## Expected Outcomes

### Immediate Benefits:
- ✅ **Journal Generation**: No more database connection errors
- ✅ **Persona Switching**: Smooth journal operations across persona changes
- ✅ **Database Consistency**: Single database connection across all services

### User Experience:
- ✅ **"Gerar Novamente" button**: Works reliably without errors
- ✅ **Journal Loading**: Consistent access to journal entries
- ✅ **Cross-Persona Journals**: Journal generation works with any active persona

## Risk Assessment

### Low Risk:
- Simple change using existing singleton pattern
- No breaking changes to journal functionality
- Consistent with FT-209 database architecture

### Testing:
- Verify journal generation works with different personas
- Test "Gerar Novamente" functionality
- Confirm no database connection errors in logs

## Dependencies

- **FT-209**: Requires ChatStorageService singleton implementation
- **No external dependencies**

## Implementation Priority

**HIGH PRIORITY** - Journal functionality is broken for users, causing poor UX when switching personas or generating journals.

---

**Status**: Ready for Implementation  
**Estimated Effort**: 5 minutes  
**Risk Level**: Low  
**User Impact**: High (fixes broken journal functionality)
