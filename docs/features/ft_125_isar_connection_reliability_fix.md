# FT-125: Isar Database Connection Reliability Fix

## Overview
Fix intermittent "Isar instance has already been closed" errors by standardizing database connection recovery across all services.

## Problem
- Export functionality fails with `IsarError: Isar instance has already been closed`
- Stats tab works reliably because it uses robust connection recovery
- `ActivityMemoryService` holds stale references to closed Isar instances
- Inconsistent recovery patterns between services

## Root Cause
1. **Stale Connection References**: `ActivityMemoryService._isar` retains closed instances
2. **Inconsistent Recovery**: Export service checks availability first, Stats tab creates fresh connections immediately
3. **Singleton Reuse Issue**: `Isar.getInstance()` may return closed instances

## Solution
Standardize all database access to use the **"Fresh Connection First"** pattern from Stats tab.

### Functional Requirements

**FR-125-01: Unified Connection Recovery**
- All services must use identical connection recovery logic
- Remove dependency on `isDatabaseAvailable()` checks before recovery
- Always attempt fresh connection when database operations fail

**FR-125-02: ActivityMemoryService Enhancement**
- Add `ensureFreshConnection()` method using Stats tab pattern
- Update all database access points to use reliable connection recovery
- Remove brittle `isDatabaseAvailable()` dependency in critical paths

**FR-125-03: Export Service Reliability**
- Apply Stats tab connection pattern to export service
- Remove `isDatabaseAvailable()` check before `_getAllActivitiesChronological()`
- Use direct fresh connection recovery on any database error

## Implementation

### Phase 1: ActivityMemoryService Enhancement (15 min)
```dart
// Add to ActivityMemoryService
static Future<bool> ensureFreshConnection() async {
  try {
    final storageService = ChatStorageService();
    final freshIsar = await storageService.db;
    return await reinitializeDatabase(freshIsar);
  } catch (e) {
    _logger.error('Failed to ensure fresh connection: $e');
    return false;
  }
}
```

### Phase 2: Export Service Fix (10 min)
```dart
// Replace in ActivityExportService._getAllActivitiesChronological()
// Remove: final dbAvailable = await ActivityMemoryService.isDatabaseAvailable();
// Replace with: await ActivityMemoryService.ensureFreshConnection();
```

### Phase 3: Statistics Method Fix (5 min)
```dart
// Update getExportStatistics() to use fresh connection pattern
// Remove isDatabaseAvailable() check, use direct fresh connection
```

## Technical Details

**Connection Recovery Pattern (Stats Tab Proven)**:
```dart
final storageService = ChatStorageService();  // Fresh instance
final newIsar = await storageService.db;      // New connection  
await ActivityMemoryService.reinitializeDatabase(newIsar);
```

**Anti-Pattern (Current Export)**:
```dart
final dbAvailable = await ActivityMemoryService.isDatabaseAvailable(); // ❌
if (!dbAvailable) { /* recovery */ }  // Too late, connection already stale
```

## Risk Assessment
- **Low Risk**: Uses proven Stats tab pattern
- **High Impact**: Fixes critical export functionality
- **No Breaking Changes**: Internal service improvements only

## Success Criteria
- Export functionality works consistently without "database closed" errors
- All database operations use unified connection recovery
- No regression in Stats tab or other database functionality

## Effort Estimate
**30 minutes** - Simple pattern replication from working Stats tab code

## Dependencies
- None (internal refactoring only)

## Testing Strategy
1. Test export after hot reload (common failure scenario)
2. Test export after visiting Stats tab (currently working scenario)  
3. Verify Stats tab continues working (regression test)
4. Test multiple export operations in sequence

---
**Priority**: High  
**Category**: Bug Fix  
**Effort**: 30 minutes
