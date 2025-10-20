# FT-209: Fix Database Deletion on App Start

## Problem Statement

The database is being deleted/reset when the app starts, causing data loss. This happens due to multiple `ChatStorageService` instances creating conflicting database connections.

## Root Cause Analysis

### Evidence from Logs:
```
Line 148: ✅ ActivityMemoryService: Fresh connection established successfully
Line 164: ❌ ActivityMemoryService: Database not available: IsarError: Isar instance has already been closed
Line 211: ✅ ActivityMemoryService: Database available, count: 0  ← Data is gone!
```

### Technical Analysis:
1. **Multiple Service Instances**: Found 23 different locations creating `new ChatStorageService()`
2. **Database Connection Conflicts**: Multiple instances try to manage the same Isar database
3. **Premature Closure**: One instance closes the database while others are using it
4. **Data Loss on Reconnection**: When reconnection happens, a fresh database is created

### Affected Locations:
- `lib/screens/chat_screen.dart`
- `lib/services/system_mcp_service.dart` (5 instances)
- `lib/screens/character_selection_screen.dart` (2 instances)
- `lib/features/journal/services/journal_generation_service.dart`
- `lib/services/activity_memory_service.dart` (2 instances)
- `lib/screens/settings/chat_management_screen.dart` (6 instances)
- `lib/screens/stats_screen.dart`
- And 6 more locations...

## Solution

### Implement Singleton Pattern for ChatStorageService

Convert `ChatStorageService` to a singleton to ensure:
1. **Single Database Connection**: Only one Isar instance throughout app lifecycle
2. **No Connection Conflicts**: All services use the same database connection
3. **Data Persistence**: No accidental database recreation/deletion

### Implementation Plan

#### Phase 1: Singleton Implementation
1. Convert `ChatStorageService` to singleton pattern
2. Add static `instance` getter
3. Make constructor private
4. Ensure thread-safe initialization

#### Phase 2: Update All References
1. Replace all `ChatStorageService()` calls with `ChatStorageService.instance`
2. Update dependency injection patterns
3. Fix any async initialization issues

#### Phase 3: Database Connection Management
1. Improve database availability checking
2. Add proper connection lifecycle management
3. Remove redundant reconnection logic

## Expected Outcomes

### Immediate Benefits:
- ✅ **Data Persistence**: Database won't be deleted on app start
- ✅ **Connection Stability**: No more "Isar instance has already been closed" errors
- ✅ **Performance**: Reduced database initialization overhead

### Long-term Benefits:
- ✅ **Reliability**: Consistent database state across app lifecycle
- ✅ **Maintainability**: Single point of database connection management
- ✅ **Debugging**: Easier to track database-related issues

## Risk Assessment

### Low Risk:
- Singleton pattern is well-established for database connections
- No breaking changes to public API
- Existing functionality preserved

### Mitigation:
- Thorough testing of all database operations
- Gradual rollout with feature toggle if needed
- Backup/restore functionality verification

## Testing Strategy

### Unit Tests:
- Singleton instance creation and reuse
- Database connection lifecycle
- Concurrent access handling

### Integration Tests:
- Cross-service database operations
- App lifecycle database persistence
- Error recovery scenarios

### Manual Testing:
- App restart with existing data
- Multiple screen navigation
- Background/foreground transitions

## Implementation Priority

**HIGH PRIORITY** - This is causing data loss for users, which is a critical issue that needs immediate attention.

## Dependencies

- No external dependencies
- Internal refactoring only
- Compatible with existing Isar database structure

## Rollback Plan

If issues arise:
1. Revert singleton changes
2. Add temporary connection pooling
3. Implement gradual migration strategy

---

**Status**: Ready for Implementation  
**Estimated Effort**: 2-3 hours  
**Risk Level**: Low  
**User Impact**: High (fixes data loss)
