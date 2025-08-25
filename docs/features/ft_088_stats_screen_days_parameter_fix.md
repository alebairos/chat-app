# FT-088: Stats Screen Days Parameter Fix

## **Overview**
Fix the critical bug where "Today's Activities" shows yesterday's data due to incorrect days parameter in activity stats queries.

## **Problem Statement**
The stats screen uses `days: 1` when querying for "today's activities", which after the FT-083 fix actually returns yesterday's data. This causes:
- Wrong day's activities displayed under "Today's Activities" 
- Impossible negative time calculations (e.g., "-1386 min ago")
- Misleading progress indicators
- Complete loss of user trust in data accuracy

## **Root Cause**
**File**: `lib/screens/stats_screen.dart`  
**Line 63**: `final todayData = await ActivityMemoryService.getActivityStats(days: 1);`

After FT-083 changes:
- `days: 0` = Today's activities (current day)
- `days: 1` = Yesterday's activities (previous 1 day, excluding today)

The stats screen is requesting yesterday's data but labeling it as "today's data".

## **Evidence from Database**
From `db_20250825_0102.json`:
- **Monday 25/8 (Today)**: 2 activities at 00:28 and 00:29
- **Sunday 24/8 (Yesterday)**: ~30+ activities throughout the day

Current stats screen shows the 30+ Sunday activities as "Today's Activities" instead of the 2 Monday activities.

## **Solution**

### **Primary Fix**
```dart
// Before (WRONG)
final todayData = await ActivityMemoryService.getActivityStats(days: 1);

// After (CORRECT)  
final todayData = await ActivityMemoryService.getActivityStats(days: 0);
```

### **Time Calculation Fix**
The `_getLastActivityTime()` method also needs updating to handle proper date context:

```dart
// Current problematic logic
final activityTime = DateTime(
  now.year,
  now.month, 
  now.day,
  int.parse(parts[0]), // hour
  int.parse(parts[1]), // minute  
);

// Problem: Assumes activity is from "today" when it might be from yesterday
```

**Solution**: Use the full timestamp from activity data instead of reconstructing date.

## **Implementation Plan**

### **Step 1: Fix Days Parameter**
- Change `days: 1` to `days: 0` in `_loadActivityStats()`
- Update comments to clarify the intention
- Test with current database to verify correct data

### **Step 2: Fix Time Calculation**  
- Modify `_getLastActivityTime()` to use `full_timestamp` field
- Remove date reconstruction logic that causes negative times
- Add proper error handling for malformed timestamps

### **Step 3: Validation**
- Add debug logging to verify correct day's data is loaded
- Test around midnight to ensure proper day transitions
- Verify time calculations are always positive and accurate

## **Files to Modify**

### **lib/screens/stats_screen.dart**
```dart
// Line 63: Fix primary query
final todayData = await ActivityMemoryService.getActivityStats(days: 0);

// Lines 416-444: Fix time calculation method
String _getLastActivityTime(List<dynamic> activities) {
  if (activities.isEmpty) return '';
  
  final lastActivity = activities.first;
  final fullTimestamp = lastActivity['full_timestamp'] as String?;
  
  if (fullTimestamp == null) return '';
  
  try {
    final activityTime = DateTime.parse(fullTimestamp);
    final now = DateTime.now();
    final diff = now.difference(activityTime);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return '${diff.inHours} hours ago';
    }
  } catch (e) {
    return 'Recently';
  }
}
```

## **Expected Results**

### **Before Fix**
- "Today's Activities" shows Sunday's 30+ activities
- Last activity: "-1386 minutes ago" 
- User confusion and lost trust

### **After Fix**  
- "Today's Activities" shows Monday's 2 activities (Water, Pomodoro)
- Last activity: "X hours ago" (positive, accurate time)
- Accurate daily progress tracking restored

## **Testing Checklist**

- [ ] Verify today's data shows current day activities
- [ ] Confirm time calculations are positive and accurate
- [ ] Test around midnight for proper day transitions  
- [ ] Validate against known database state
- [ ] Ensure no regression in week/month views

## **Priority**: **Critical**
This is a critical data accuracy bug that completely undermines the stats screen's core functionality.

## **Effort**: **Low** (Simple parameter change + time calculation fix)

## **Category**: **Bug Fix**
