# FT-119: Activity Tracking Graceful Degradation Policy

**Feature ID:** FT-119  
**Priority:** High  
**Category:** Performance / User Experience  
**Effort:** 2-3 hours  

## Problem Statement

Activity tracking fails silently during Claude API rate limiting, causing:
- **Lost activity requests**: Activities mentioned by users are not tracked at all
- **Delayed tracking without notification**: Activities appear 20+ minutes later without user awareness
- **Silent failures**: Users have no visibility into tracking status or delays
- **Broken user experience**: Users lose trust in the activity tracking system

**Current Issue:**
```
User: "bebi agua" (15:05)
→ Rate limit hit → Activity lost
→ Later retry succeeds → "Beber água" appears at 15:25
→ User confused: "Why did this take 20 minutes?"
```

## Solution Overview

Implement **Option B: Graceful Degradation with Background Processing** - enhance the existing throttling framework to queue failed activities and provide subtle user notifications about delays.

## Core Principle

**Transparent Reliability**: Users should always receive their conversation response, with activity tracking happening reliably in the background even during rate limit periods.

## Technical Approach

### **Phase 1: Rate Limit State Tracking**

Replace placeholder implementations in `claude_service.dart`:

```dart
class _RateLimitTracker {
  static DateTime? _lastRateLimit;
  static int _recentApiCalls = 0;
  static final List<DateTime> _apiCallHistory = [];
  
  static bool hasRecentRateLimit() {
    if (_lastRateLimit == null) return false;
    return DateTime.now().difference(_lastRateLimit!) < Duration(minutes: 2);
  }
  
  static void recordRateLimit() {
    _lastRateLimit = DateTime.now();
  }
  
  static bool hasHighApiUsage() {
    _cleanOldCalls();
    return _apiCallHistory.length > 8; // 8+ calls in last minute
  }
  
  static void recordApiCall() {
    _apiCallHistory.add(DateTime.now());
    _cleanOldCalls();
  }
}
```

### **Phase 2: Activity Request Queue**

Add activity queuing to `ActivityMemoryService`:

```dart
class ActivityQueue {
  static final List<ActivityRequest> _pendingActivities = [];
  
  static void queueActivity(String userMessage, DateTime requestTime) {
    _pendingActivities.add(ActivityRequest(
      message: userMessage,
      requestedAt: requestTime,
      retryCount: 0,
    ));
  }
  
  static Future<void> processQueue() async {
    if (_pendingActivities.isEmpty) return;
    
    // Try to process oldest queued activity
    final activity = _pendingActivities.first;
    if (await _tryProcessActivity(activity)) {
      _pendingActivities.removeAt(0);
    }
  }
}
```

### **Phase 3: User Notification Enhancement**

Modify conversation responses to include subtle status updates:

```dart
String _addActivityStatusNote(String response) {
  if (ActivityQueue.hasPendingActivities()) {
    return "$response\n\n_Note: Activity tracking temporarily delayed due to high usage._";
  }
  return response;
}
```

## Implementation Details

### **Target Files:**

1. **`lib/services/claude_service.dart`**
   - Replace `_hasRecentRateLimit()` and `_hasHighApiUsage()` placeholders
   - Add rate limit detection on HTTP 429 and `rate_limit_error` responses
   - Enhance response with activity status notes

2. **`lib/services/activity_memory_service.dart`**
   - Add activity queuing system
   - Add background queue processing

3. **`lib/services/integrated_mcp_processor.dart`**
   - Modify to queue activities when rate limited instead of failing silently

### **Key Changes:**

**Rate Limit Detection Enhancement:**
```dart
// In claude_service.dart - line 258
case 429:
  _RateLimitTracker.recordRateLimit(); // ADD THIS
  return 'Rate limit exceeded. Please try again later.';
```

**Activity Queuing Integration:**
```dart
// In integrated_mcp_processor.dart - line 69
} catch (e) {
  if (e.toString().contains('429') || e.toString().contains('rate_limit')) {
    ActivityQueue.queueActivity(userMessage, DateTime.now()); // ADD THIS
    Logger().debug('FT-119: Activity queued due to rate limit');
  }
  Logger().debug('FT-064: Integrated processing failed silently: $e');
}
```

## Functional Requirements

### **FR-119-1: Rate Limit State Tracking**
- System accurately detects and remembers rate limit events
- API usage patterns are monitored to predict rate limiting
- State persists for appropriate recovery periods (2-5 minutes)

### **FR-119-2: Activity Request Queuing**
- Failed activity requests are queued with timestamp and retry count
- Queue processes automatically when rate limits clear
- Maximum queue size prevents memory issues (limit: 20 activities)

### **FR-119-3: Graceful User Communication**
- Users receive normal conversation responses even during rate limits
- Subtle notifications inform users about activity tracking delays
- No error messages or conversation interruptions

### **FR-119-4: Background Recovery**
- Queued activities are processed automatically every 2-3 minutes
- Failed activities are retried up to 3 times before being discarded
- Successful processing removes activities from queue

## Non-Functional Requirements

### **NFR-119-1: Performance**
- Queue processing adds <100ms overhead to conversation responses
- Memory usage for queue limited to <1MB
- No impact on main conversation flow

### **NFR-119-2: Reliability**
- 95% of activities eventually processed within 10 minutes
- No data loss during rate limit periods
- Graceful degradation maintains core chat functionality

### **NFR-119-3: User Experience**
- Rate limit delays are invisible to conversation flow
- Activity tracking appears reliable from user perspective
- Status notifications are informative but non-intrusive

## Acceptance Criteria

### **AC-119-1: Rate Limit Handling**
- [ ] HTTP 429 responses trigger rate limit state tracking
- [ ] `rate_limit_error` JSON responses trigger rate limit state tracking
- [ ] Rate limit state correctly influences throttling delays (5s → 15s)
- [ ] API usage tracking accurately counts recent calls

### **AC-119-2: Activity Queuing**
- [ ] Activities mentioned during rate limits are queued, not lost
- [ ] Queued activities include original timestamp and user message
- [ ] Queue processing runs automatically every 2-3 minutes
- [ ] Successfully processed activities are removed from queue

### **AC-119-3: User Experience**
- [ ] Conversation responses include activity status notes when appropriate
- [ ] Users receive responses even when activity tracking is delayed
- [ ] No error messages or conversation interruptions during rate limits
- [ ] Activity tracking appears in Stats screen within 10 minutes

### **AC-119-4: Background Processing**
- [ ] Queue processing happens without user interaction
- [ ] Failed activities are retried up to 3 times
- [ ] Queue size is limited to prevent memory issues
- [ ] Processing logs provide visibility into queue status

## Dependencies

- **FT-085**: Smart API delay system (already implemented)
- **FT-103**: Activity detection throttling framework (already implemented)
- **FT-064**: Integrated MCP processor (existing integration point)

## Migration Considerations

- **Backward Compatibility**: No breaking changes to existing activity tracking
- **Data Preservation**: Existing activities remain unaffected
- **Graceful Rollout**: Feature can be enabled gradually with feature flags

## Testing Strategy

### **Unit Tests**
- Rate limit state tracking accuracy
- Activity queue operations (add, remove, process)
- User notification message formatting

### **Integration Tests**
- End-to-end activity tracking during simulated rate limits
- Queue processing with real activity detection pipeline
- User experience during rate limit scenarios

### **Manual Testing**
- Trigger rate limits and verify activity queuing
- Confirm activities appear in Stats screen after delays
- Validate user notification messages are appropriate

## Success Metrics

- **Activity Loss Rate**: Reduce from ~30% to <5% during rate limit periods
- **User Notification Clarity**: 90% of delayed activities include status notes
- **Recovery Time**: 95% of queued activities processed within 10 minutes
- **System Reliability**: No conversation flow interruptions during rate limits

## Implementation Notes

This feature enhances the existing throttling framework rather than replacing it. The implementation focuses on filling the gaps in rate limit detection and providing graceful degradation for activity tracking while preserving the excellent conversation experience.
