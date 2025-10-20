# FT-211: Revert Singleton Database Changes

## Problem Statement

The singleton pattern implementation (FT-209, FT-210) has introduced complex architectural conflicts between services, causing journal generation failures and database connection issues that are beyond the scope of the current Aristios 4.5 persona development branch.

## Root Cause Analysis

### Original Issue (Solved Elsewhere):
- **Database deletion on app start** was likely already resolved by other changes in the branch
- **Evidence**: App was working fine before singleton implementation

### New Issues Introduced:
- **Journal generation failures**: "Isar instance has already been closed" errors
- **Service architecture conflicts**: `ActivityMemoryService` vs `ChatStorageService` database instance management
- **Complex debugging**: Multiple services with different database connection strategies

### Scope Mismatch:
- **Current branch focus**: Aristios 4.5 persona development (`ft_186_persona_ari4.5`)
- **Singleton complexity**: Requires dedicated database architecture refactoring
- **Risk vs benefit**: More problems introduced than solved

## Solution: Safe Reversion

Revert all singleton-related changes to restore the working state, allowing focus to return to Aristios 4.5 persona development.

### Files to Revert:

#### 1. ChatStorageService - Remove Singleton Pattern
**File:** `lib/services/chat_storage_service.dart`
```dart
// Revert to original constructor pattern:
class ChatStorageService {
  late Future<Isar> db;

  ChatStorageService() {
    db = openDB();
  }
  // Remove: singleton instance, resetSingleton(), factory constructor
}
```

#### 2. All Services - Restore Original ChatStorageService Usage
**Files to update:**
- `lib/features/journal/services/journal_generation_service.dart:89`
- `lib/features/journal/services/journal_storage_service.dart:14`  
- `lib/services/activity_memory_service.dart:209,278`
- `lib/services/system_mcp_service.dart:413,470,979,1022,1064`

```dart
// Change back from:
final chatStorage = ChatStorageService.instance;

// To:
final chatStorage = ChatStorageService();
```

#### 3. Test Files - Remove Singleton Reset Calls
**Files to clean up:**
- `test/chat_storage_test.dart:63` - Remove `ChatStorageService.resetSingleton();`
- `test/utf8_handling_test.dart:129` - Remove `ChatStorageService.resetSingleton();`

## Implementation Steps

### Phase 1: Core Service Reversion
1. Revert `ChatStorageService` to original non-singleton form
2. Update all service files to use `ChatStorageService()` constructor
3. Verify compilation

### Phase 2: Test Cleanup  
1. Remove singleton reset calls from test files
2. Run test suite to ensure all tests pass
3. Verify no singleton-related test dependencies

### Phase 3: Verification
1. Test journal generation functionality
2. Verify persona switching works correctly
3. Confirm no database deletion issues on app start

## Expected Outcomes

### Immediate Benefits:
- ✅ **Journal Generation**: Restored to working state
- ✅ **Reduced Complexity**: No service architecture conflicts
- ✅ **Branch Focus**: Return to Aristios 4.5 persona development
- ✅ **Stable Foundation**: Working database operations

### Risk Mitigation:
- **Low Risk**: Reverting to previously working state
- **No Data Loss**: Database structure unchanged
- **Preserved Functionality**: All original features maintained

## Future Considerations

### Proper Database Architecture Refactoring:
- **Dedicated Branch**: Create separate branch for database architecture improvements
- **Comprehensive Planning**: Full analysis of all database-using services
- **Unified Strategy**: Consistent database connection management across all services
- **Thorough Testing**: Complete test coverage for database operations

### Lessons Learned:
- **Scope Separation**: Keep architectural changes separate from feature development
- **Impact Assessment**: Fully analyze service dependencies before major changes
- **Branch Focus**: Maintain clear separation of concerns per branch

## Dependencies

- **No external dependencies**
- **No breaking changes to public APIs**
- **Compatible with existing database structure**

## Implementation Priority

**HIGH PRIORITY** - Blocking Aristios 4.5 persona development due to journal generation failures.

---

**Status**: Ready for Implementation  
**Estimated Effort**: 15 minutes  
**Risk Level**: Low (reverting to working state)  
**User Impact**: Positive (restores journal functionality)
