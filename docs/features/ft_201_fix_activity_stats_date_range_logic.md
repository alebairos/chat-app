# FT-201: Fix Activity Stats Date Range Logic

## Problem Statement

The `ActivityMemoryService.getActivityStats()` method has incorrect date range logic that causes inconsistent MCP responses when AI personas query activity history.

### Current Broken Behavior
- **`days: 0`**: ✅ Today only (working correctly)
- **`days: 7`**: ❌ Previous 7 days **excluding today** (October 11-17)
- **`days: 30`**: ❌ Previous 30 days **excluding today**

### Expected Behavior
- **`days: 0`**: Today only
- **`days: 7`**: Today + previous 6 days (7 total days including today)
- **`days: 30`**: Today + previous 29 days (30 total days including today)

### Impact on User Experience
This causes AI personas to give inconsistent responses:
1. When querying "last week" → Shows old activities (excluding today)
2. When querying "today" → Shows current activities
3. Users get confused by missing recent activities in weekly/monthly summaries

## Evidence from Logs

**Line 17**: `Querying PREVIOUS 7 days from 2025-10-11T00:00:00.000 to 2025-10-17T23:59:59.999`
- Result: Found 1 old activity (Tuesday's "dar bom dia")
- Missing: Today's 5 activities (pomodoro, water, walk, etc.)

**Lines 378-380**: When querying today (`days: 0`)
- Result: Found 5 activities today
- Correct behavior for today-only queries

## Root Cause Analysis

**File**: `lib/services/activity_memory_service.dart` (lines 665-672)

```dart
} else {
  // Query previous days (exclude today) ← PROBLEM: Excludes today
  startDate = today.subtract(Duration(days: days));
  final endDate = today.subtract(const Duration(days: 1)); ← PROBLEM: Ends yesterday
  queryEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
}
```

## Solution

### Fix Date Range Logic
Change the logic to **include today** in multi-day queries:

```dart
} else {
  // Query last N days INCLUDING today
  startDate = today.subtract(Duration(days: days - 1)); // Include today in count
  queryEndDate = now; // Include current time today
  print(
      '🔍 ActivityMemoryService: Querying LAST $days days (including today) from ${startDate.toIso8601String()} to ${queryEndDate.toIso8601String()}');
}
```

### Expected Results After Fix
- **`days: 7`**: October 12-18 (7 days including today)
- **`days: 30`**: September 19 - October 18 (30 days including today)
- **`days: 0`**: October 18 only (unchanged)

## Implementation Plan

### Phase 1: Core Fix
1. **Update date calculation logic** in `ActivityMemoryService.getActivityStats()`
2. **Update log messages** to reflect "including today"
3. **Test with different day values** (0, 1, 7, 30)

### Phase 2: Validation
1. **Verify MCP responses** show consistent data
2. **Test AI persona responses** for activity history queries
3. **Confirm Stats UI** displays correct date ranges

### Phase 3: Documentation
1. **Update method documentation** to clarify inclusive date ranges
2. **Add unit tests** for date range calculations
3. **Document expected behavior** in code comments

## Testing Strategy

### Unit Tests
```dart
test('getActivityStats includes today in multi-day queries', () async {
  // Test days: 7 includes today + previous 6 days
  // Test days: 30 includes today + previous 29 days
  // Test days: 0 remains today-only
});
```

### Integration Tests
1. **MCP Command Testing**: Verify `get_activity_stats` returns consistent data
2. **AI Response Testing**: Check persona responses include recent activities
3. **UI Testing**: Confirm Stats screen shows correct date ranges

## Acceptance Criteria

### Functional Requirements
- [ ] `days: 7` includes today + previous 6 days (7 total)
- [ ] `days: 30` includes today + previous 29 days (30 total)
- [ ] `days: 0` remains today-only (unchanged)
- [ ] Log messages clearly indicate "including today"

### Performance Requirements
- [ ] No performance regression in database queries
- [ ] Maintains existing caching behavior
- [ ] Query execution time remains under 200ms

### User Experience Requirements
- [ ] AI personas give consistent activity summaries
- [ ] Weekly/monthly queries include today's activities
- [ ] Stats UI shows accurate date ranges
- [ ] MCP responses are predictable and reliable

## Risk Assessment

### Low Risk
- **Backward Compatibility**: Only affects date range calculation
- **Database Impact**: No schema changes required
- **Performance**: Same query structure, just different date parameters

### Mitigation Strategies
- **Gradual Rollout**: Test with single persona first
- **Logging**: Enhanced debug logs to verify correct date ranges
- **Rollback Plan**: Simple revert of date calculation logic

## Success Metrics

### Before Fix
- MCP queries for "last 7 days" exclude today's activities
- AI responses show inconsistent activity data
- Users confused by missing recent activities

### After Fix
- MCP queries for "last 7 days" include today's activities
- AI responses consistently show recent activity data
- Users see complete activity history in summaries

## Dependencies

### Internal Dependencies
- `ActivityMemoryService.getActivityStats()` method
- MCP command `get_activity_stats`
- Stats UI components

### External Dependencies
- None (pure date calculation logic fix)

## Timeline

- **Analysis & Design**: ✅ Complete
- **Implementation**: 15 minutes
- **Testing**: 30 minutes
- **Documentation**: 15 minutes
- **Total Effort**: 1 hour

## Related Features

- **FT-140**: Oracle Activity Detection (uses activity stats)
- **FT-200**: Conversation Database Queries (MCP integration)
- **Stats UI**: Activity statistics display
- **AI Personas**: Activity history queries via MCP

---

**Priority**: High
**Category**: Bug Fix
**Effort**: Small (1 hour)
**Impact**: High (affects AI persona consistency)
