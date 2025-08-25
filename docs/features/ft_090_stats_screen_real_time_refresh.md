# FT-090: Stats Screen Real-Time Refresh Mechanism

## **Overview**
Implement automatic refresh of stats screen data to immediately reflect newly logged activities without requiring manual refresh or app restart.

## **Problem Statement**
The stats screen currently doesn't update when new activities are logged, causing:
- **Stale data**: Recent activities (like the 00:28 and 00:29 activities) don't appear
- **User confusion**: "I just logged an activity, where is it?"
- **Poor UX**: Users must manually refresh or restart app to see updates
- **Broken feedback loop**: No immediate confirmation that activity was tracked

## **Evidence from Database**
From `db_20250825_0102.json`, the latest activities are:
- **00:28**: SF1 - Beber água (ID: 142)
- **00:29**: T8 - Pomodoro (ID: 143)

If these don't appear immediately in the stats screen, users lose confidence in the tracking system.

## **Current Architecture Issues**

### **Stats Screen Data Flow**
1. **Load on init**: `_loadActivityStats()` called once in `initState()`
2. **Manual refresh**: Pull-to-refresh triggers `_loadActivityStats()`
3. **No auto-refresh**: No mechanism to detect new activities
4. **Cache dependency**: May be showing cached/stale data

### **Activity Logging Flow**
1. User completes activity
2. `ActivityMemoryService.logActivity()` saves to database
3. **Missing step**: No notification to stats screen about new data
4. Stats screen remains unaware of changes

## **Solution Strategy**

### **Option 1: Database Change Notifications (Recommended)**
- Use Isar's built-in change stream functionality
- Subscribe to activity collection changes
- Auto-refresh stats when new activities detected

### **Option 2: App State Management**
- Implement global app state for activity updates
- Notify all interested screens when activities change
- More complex but scalable to other screens

### **Option 3: Periodic Auto-Refresh**
- Refresh stats every 30-60 seconds automatically
- Simple but inefficient (unnecessary API calls)
- Good fallback if change notifications fail

## **Recommended Implementation**

### **Approach: Isar Change Streams + Smart Refresh**

```dart
class _StatsScreenState extends State<StatsScreen> {
  late StreamSubscription<void> _activitySubscription;
  
  @override
  void initState() {
    super.initState();
    _loadActivityStats();
    _setupActivityListener();
  }
  
  void _setupActivityListener() {
    // Listen for changes to activity collection
    _activitySubscription = ActivityMemoryService.database
        .activityModels
        .watchLazy()
        .listen((_) {
      // New activity detected, refresh stats
      if (mounted) {
        _refreshStatsData();
      }
    });
  }
  
  Future<void> _refreshStatsData() async {
    // Smart refresh: only reload if user can see the screen
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      await _loadActivityStats();
    }
  }
  
  @override
  void dispose() {
    _activitySubscription.cancel();
    super.dispose();
  }
}
```

### **Enhanced User Feedback**
```dart
Future<void> _loadActivityStats() async {
  // Add loading state for real-time updates
  if (!_isInitialLoad) {
    setState(() => _isRefreshing = true);
  }
  
  // ... existing loading logic ...
  
  if (!_isInitialLoad) {
    setState(() => _isRefreshing = false);
    
    // Show subtle confirmation of new data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stats updated'),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
```

## **Implementation Details**

### **Database Change Detection**
```dart
// In ActivityMemoryService
static Stream<void> get activityChanges => 
    _database.activityModels.watchLazy();

// Usage in StatsScreen
void _setupActivityListener() {
  _activitySubscription = ActivityMemoryService.activityChanges
      .debounceTime(Duration(milliseconds: 500)) // Prevent spam
      .listen((_) => _refreshStatsData());
}
```

### **Optimized Refresh Strategy**
```dart
Future<void> _refreshStatsData() async {
  // Only refresh if:
  // 1. Screen is currently visible
  // 2. Not already refreshing
  // 3. Last refresh was > 1 second ago (debounce)
  
  if (!mounted || _isRefreshing) return;
  
  final now = DateTime.now();
  if (_lastRefresh != null && 
      now.difference(_lastRefresh!).inSeconds < 1) {
    return; // Too soon, skip refresh
  }
  
  _lastRefresh = now;
  await _loadActivityStats();
}
```

### **Background/Foreground Handling**
```dart
class _StatsScreenState extends State<StatsScreen> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ... existing init
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh data
      _refreshStatsData();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // ... existing dispose
  }
}
```

## **Files to Modify**

### **lib/screens/stats_screen.dart**
- Add activity change listener setup
- Implement smart refresh logic
- Add debouncing to prevent excessive refreshes
- Handle app lifecycle changes

### **lib/services/activity_memory_service.dart**
- Expose activity change stream
- Ensure database operations trigger change notifications
- Add logging for refresh triggers

## **User Experience Improvements**

### **Immediate Feedback**
- Activity appears in stats within 1-2 seconds of logging
- Subtle animation or highlight for new activities
- No jarring full-screen refreshes

### **Performance Optimization**
- Debounced refreshes (max 1 per second)
- Only refresh when screen is visible
- Smart caching to avoid redundant queries

### **Error Handling**
- Graceful degradation if change streams fail
- Fallback to pull-to-refresh if auto-refresh broken
- Clear error messaging for connection issues

## **Testing Scenarios**

### **Real-Time Update Tests**
- [ ] Log activity → appears in stats within 2 seconds
- [ ] Multiple rapid activities → batched refresh, no spam
- [ ] Background/foreground → refreshes when returning to app
- [ ] Network issues → graceful fallback behavior

### **Performance Tests**
- [ ] No excessive database queries
- [ ] Smooth scrolling maintained during refresh
- [ ] Memory usage stable with long-running listeners

### **Edge Cases**
- [ ] App killed/restarted → listeners re-established
- [ ] Database corruption → error handling
- [ ] Very large activity lists → refresh performance

## **Expected Results**

### **Before Fix**
- User logs water at 00:28 → not visible in stats
- User logs pomodoro at 00:29 → still not visible
- User must manually refresh to see activities
- Frustration and lost confidence in system

### **After Fix**
- User logs water → appears in stats immediately
- User logs pomodoro → stats update automatically  
- Seamless experience reinforces positive tracking behavior
- Increased user confidence and engagement

## **Priority**: **High**
Real-time feedback is essential for user engagement and system trust.

## **Effort**: **Medium** 
Requires stream handling, lifecycle management, and performance optimization.

## **Category**: **UX Enhancement**

## **Dependencies**
- Requires FT-088 (days parameter fix) to be completed first
- Works best with FT-089 (neutral confidence indicators) for overall positive UX

## **Rollout Strategy**
1. **Phase 1**: Basic change stream implementation
2. **Phase 2**: Smart refresh with debouncing
3. **Phase 3**: Performance optimization and edge case handling
