# FT-124: Preserve Original Timestamps During Activity Import

**Feature ID:** FT-124  
**Priority:** Critical  
**Category:** Bug Fix  
**Effort Estimate:** 1 hour  
**Dependencies:** FT-122 (Activity Export/Import)  

## Problem Statement

**Critical Bug:** When importing activity data, the system is altering the original timestamps instead of preserving them. This corrupts the historical accuracy of activity tracking data.

### Current Behavior (Incorrect)
- Import reads `completedAt: "2025-09-16T15:30:00.000Z"` from JSON
- System calls `ActivityMemoryService.logActivity()` which uses `DateTime.now()`
- Activity is stored with current import time instead of original completion time
- Historical data integrity is lost

### Expected Behavior (Correct)
- Import reads `completedAt: "2025-09-16T15:30:00.000Z"` from JSON
- System preserves the original timestamp exactly as exported
- Activity is stored with original completion time
- Historical data integrity is maintained

## Root Cause Analysis

The issue is in `ActivityExportService._importActivities()` method:

```dart
// PROBLEM: This uses current time, not imported timestamp
await ActivityMemoryService.logActivity(
  activityCode: activityData['activityCode'] as String?,
  activityName: activityData['activityName'] as String,
  dimension: activityData['dimension'] as String,
  // ... other fields
);
```

The `logActivity()` method always uses `DateTime.now()` for the completion time, ignoring the original timestamp from the import data.

## Solution

### Approach 1: Create New Import-Specific Method (Recommended)
Create `ActivityMemoryService.importActivity()` method that accepts a pre-built `ActivityModel` with original timestamps.

### Approach 2: Extend Existing Method
Add optional timestamp parameter to `logActivity()` method.

**Recommendation:** Use Approach 1 to avoid breaking existing functionality.

## Technical Implementation

### FR-124-01: Create Import-Specific Method
- **Requirement:** Add `ActivityMemoryService.importActivity(ActivityModel activity)` method
- **Details:**
  - Accepts pre-built `ActivityModel` with original timestamps
  - Performs database insertion without timestamp modification
  - Maintains all existing validation and error handling

### FR-124-02: Preserve All Timestamp Fields
- **Requirement:** Preserve all time-related fields from import data
- **Details:**
  - `completedAt` - Original completion timestamp
  - `timestamp` - Original detection timestamp  
  - `createdAt` - Original creation timestamp
  - `hour`, `minute` - Derived from original time
  - `dayOfWeek`, `timeOfDay` - Calculated from original time

### FR-124-03: Update Import Logic
- **Requirement:** Modify import process to use preserved timestamps
- **Details:**
  - Parse timestamps from JSON import data
  - Create `ActivityModel` with original timestamps
  - Use new `importActivity()` method instead of `logActivity()`

## Implementation Steps

### Step 1: Add Import Method to ActivityMemoryService
```dart
static Future<ActivityModel> importActivity(ActivityModel activity) async {
  // Insert activity with preserved timestamps
  await _database.writeTxn(() async {
    await _database.activityModels.put(activity);
  });
  return activity;
}
```

### Step 2: Create ActivityModel from Import Data
```dart
ActivityModel _createActivityFromImport(Map<String, dynamic> data) {
  return ActivityModel.fromDetection(
    activityCode: data['activityCode'] as String?,
    activityName: data['activityName'] as String,
    dimension: data['dimension'] as String,
    source: data['source'] as String? ?? 'Import',
    completedAt: DateTime.parse(data['completedAt'] as String), // PRESERVE ORIGINAL
    dayOfWeek: data['dayOfWeek'] as String,
    timeOfDay: data['timeOfDay'] as String,
    durationMinutes: data['durationMinutes'] as int?,
    notes: data['notes'] as String?,
    confidenceScore: (data['confidenceScore'] as num?)?.toDouble() ?? 1.0,
  );
}
```

### Step 3: Update Import Process
```dart
// Replace logActivity() call with importActivity()
final activityModel = _createActivityFromImport(activityData);
await ActivityMemoryService.importActivity(activityModel);
```

## Success Criteria

### Acceptance Criteria
- [ ] Imported activities retain original `completedAt` timestamps
- [ ] All time-related fields are preserved exactly as exported
- [ ] Import process maintains data integrity
- [ ] Existing export functionality remains unchanged
- [ ] No regression in duplicate detection logic

### Testing Approach
1. **Export activities** with known timestamps
2. **Clear database** to simulate fresh install
3. **Import the exported file**
4. **Verify timestamps** match original export exactly
5. **Test edge cases** with various timestamp formats

## Risk Assessment

### Technical Risks
- **Minimal Risk** - Isolated change to import logic only
- **No Breaking Changes** - Existing functionality unaffected
- **Data Integrity** - Improves rather than risks data quality

### Implementation Risks
- **Low Complexity** - Straightforward timestamp preservation
- **Well-Defined Scope** - Limited to import process only

## Validation

### Before Fix
```json
// Exported: completedAt: "2025-09-16T15:30:00.000Z"
// After Import: completedAt: "2025-09-16T16:45:00.000Z" (WRONG - current time)
```

### After Fix
```json
// Exported: completedAt: "2025-09-16T15:30:00.000Z"  
// After Import: completedAt: "2025-09-16T15:30:00.000Z" (CORRECT - preserved)
```

---

**Created:** 2025-09-16  
**Priority:** Critical - Data integrity issue  
**Impact:** High - Affects all activity imports  
**Complexity:** Low - Simple timestamp preservation
