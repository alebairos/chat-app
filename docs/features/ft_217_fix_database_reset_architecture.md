# FT-217: Fix Database Reset Architecture Issues

## Problem Statement

The merge from `ft/ui_updates` introduced a centralized `DatabaseService` that causes "Isar instance has already been closed" errors throughout the app. While the Reset All Data feature is valuable, the centralized database architecture creates concurrency issues.

- **Priority**: Critical
- **Category**: Architecture Fix
- **Effort**: 1-2 hours

## Current Issues

### Database Connection Errors
```
flutter: ❌ ActivityMemoryService: Database not available: IsarError: Isar instance has already been closed
flutter: ⚠️ [WARNING] FT-150-Simple: ❌ Failed to load conversation history: IsarError: Isar instance has already been closed
flutter: ❌ [ERROR] Error initializing services: IsarError: Isar instance has already been closed
```

### Root Cause
The `DatabaseService._initializeDatabase()` method closes existing Isar instances while other services are still using them:

```dart
// Problem in DatabaseService._initializeDatabase():
if (_isar != null) {
  await _isar!.close(); // ❌ Closes DB while others use it
  _isar = null;
}
```

## Solution Strategy

**Preserve Reset Feature + Revert Problematic Architecture**

### Keep These Components ✅
- `UserSettingsModel` and `UserSettingsService` (better than SharedPreferences)
- `AppRestartService` (clean app restart mechanism)
- Reset UI components in `ProfileScreen` (excellent UX)
- Reset dialog flows and confirmation logic

### Remove These Components ❌
- Centralized `DatabaseService` singleton
- Services refactored to use centralized database access
- Concurrent database initialization logic

### Add Simple Reset Service ✅
```dart
class DataResetService {
  static Future<void> resetAllUserData() async {
    // Direct database operations without centralization
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open([...schemas], directory: dir.path);
    
    await isar.writeTxn(() async {
      await isar.chatMessageModels.clear();
      await isar.activityModels.clear();
      await isar.userSettingsModels.clear();
      await isar.journalEntryModels.clear();
      
      // Create fresh user settings
      final newSettings = UserSettingsModel.initial();
      await isar.userSettingsModels.put(newSettings);
    });
    
    await isar.close();
  }
}
```

## Implementation Plan

### Phase 1: Revert Problematic Changes
- [ ] Remove centralized `DatabaseService`
- [ ] Revert `ChatStorageService` to original pattern
- [ ] Revert other services to original database access patterns
- [ ] Clean up modified files from merge conflicts

### Phase 2: Implement Simple Reset
- [ ] Create `DataResetService` with direct database operations
- [ ] Update `OnboardingManager.resetAllUserData()` to use new service
- [ ] Keep all UI components and user experience intact

### Phase 3: Testing & Validation
- [ ] Test app launches without database errors
- [ ] Test reset functionality works end-to-end
- [ ] Test all existing features work normally
- [ ] Verify no regression in user experience

## Acceptance Criteria

### Functional Requirements
- [ ] App launches without "Isar instance has already been closed" errors
- [ ] Reset All Data feature works completely (UI + functionality)
- [ ] All existing features work normally (chat, activities, journal)
- [ ] User settings are properly managed with new model

### Technical Requirements
- [ ] No centralized database singleton causing concurrency issues
- [ ] Services use original, proven database access patterns
- [ ] Reset functionality is isolated and doesn't affect normal operations
- [ ] Clean separation between reset logic and daily operations

### User Experience Requirements
- [ ] Reset dialog and confirmation flow unchanged
- [ ] App restart after reset works smoothly
- [ ] No visible changes to user experience
- [ ] All personas and features work normally

## Risk Assessment

### Low Risk Changes
- Reverting to proven database patterns
- Adding isolated reset service
- Keeping UI components unchanged

### Mitigation Strategies
- Test thoroughly before merging
- Keep reset functionality completely separate
- Maintain existing service interfaces

## Files to Modify

### Remove/Revert
- `lib/services/database_service.dart` (delete)
- `lib/services/chat_storage_service.dart` (revert to original)
- `lib/services/user_settings_service.dart` (keep new model, revert DB access)

### Add/Modify
- `lib/services/data_reset_service.dart` (new)
- `lib/services/onboarding_manager.dart` (update reset call)
- Clean up other modified files from merge

### Keep Unchanged
- `lib/models/user_settings_model.dart` ✅
- `lib/services/app_restart_service.dart` ✅
- `lib/screens/profile_screen.dart` reset UI ✅

## Success Metrics

### Before Fix
- App crashes with database connection errors
- Multiple "Isar instance has already been closed" errors
- Services fail to initialize properly

### After Fix
- App launches cleanly without database errors
- Reset All Data feature works end-to-end
- All existing functionality preserved
- Clean, maintainable architecture

---

**Why This Approach?**
- Preserves the valuable Reset All Data feature
- Eliminates problematic centralized database architecture
- Minimal risk by reverting to proven patterns
- Maintains excellent user experience
- Can be implemented and tested quickly
