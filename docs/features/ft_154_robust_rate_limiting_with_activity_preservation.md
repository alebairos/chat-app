# FT-154: Robust Rate Limiting with Activity Preservation

**Priority**: Critical  
**Category**: System Reliability  
**Effort**: 20 minutes  
**Status**: Specification  

## Problem Statement

**Critical Robustness Issue**: FT-153 invisible rate limiting is too aggressive, causing cascading failures and permanent activity loss during high load.

### Current Failures:
- **Over-aggressive recovery**: 15s delays for all requests create "death spiral"
- **Activity loss**: Background services fail silently, losing user activities permanently
- **Poor user feedback**: Users don't understand delays, send more messages, worsening the problem
- **Perpetual recovery mode**: System gets stuck in rate limit recovery

### Evidence:
```
User: "que mensagem e essa? tá trabalhando muito hein?"
System: "I'm processing a lot of requests right now..."
User: "shiii" (frustrated)
System: Another fallback message
Result: Activities not detected, user frustrated
```

## Solution: Graduated Recovery with Activity Preservation

### Core Principle: **Degrade Gracefully, Never Lose Data**

## Implementation

### **1. Graduated Rate Limit Recovery**

Replace blanket 15s delays with intelligent recovery:

```dart
// SharedClaudeRateLimiter.waitAndRecord()
if (_hasRecentRateLimit()) {
  delay = isUserFacing 
    ? Duration(seconds: 3)    // Faster user recovery
    : Duration(seconds: 15);  // Maintain background protection
}
```

### **2. Activity Queuing System**

Preserve activities during rate limits instead of silent failure:

```dart
class ActivityQueue {
  static final List<PendingActivity> _queue = [];
  
  static Future<void> queueActivity(String message, DateTime timestamp) async {
    _queue.add(PendingActivity(message, timestamp));
    Logger().info('FT-154: Activity queued for later processing');
  }
  
  static Future<void> processQueue() async {
    if (_queue.isEmpty) return;
    
    Logger().info('FT-154: Processing ${_queue.length} queued activities');
    
    for (final activity in _queue) {
      try {
        await _processActivityDetection(activity.message, activity.timestamp);
        _queue.remove(activity);
      } catch (e) {
        // Keep in queue if still failing
        break;
      }
    }
  }
}
```

### **3. Background Service Robustness**

Update all background services to queue instead of fail:

```dart
// SystemMCPService, SemanticActivityDetector, LLMActivityPreSelector
catch (e) {
  if (_isRateLimitError(e)) {
    Logger().warning('FT-154: Background service hit rate limit, queuing activity');
    await ActivityQueue.queueActivity(userMessage, DateTime.now());
    return ''; // Silent failure for UX, but activity preserved
  }
  rethrow;
}
```

### **4. Contextual User Feedback**

Track consecutive failures for better communication:

```dart
class ClaudeService {
  int _consecutiveFallbacks = 0;
  
  String _getContextualFallbackResponse() {
    _consecutiveFallbacks++;
    
    if (_consecutiveFallbacks == 1) {
      return "I'm processing a lot of requests right now. Let me get back to you with a thoughtful response in just a moment.";
    } else if (_consecutiveFallbacks <= 3) {
      return "I'm experiencing high demand right now. Your message is important to me - please give me a moment to respond thoughtfully.";
    } else {
      return "I'm working through a high volume of requests. I'll respond as soon as possible - thank you for your patience.";
    }
  }
  
  void _resetFallbackCounter() {
    _consecutiveFallbacks = 0;
  }
}
```

### **5. Automatic Queue Processing**

Process queued activities when system recovers:

```dart
// In ClaudeService after successful API call
if (response.statusCode == 200) {
  _resetFallbackCounter();
  
  // Process any queued activities
  if (!SharedClaudeRateLimiter.hasRecentRateLimit()) {
    ActivityQueue.processQueue();
  }
}
```

## Performance Impact

### **Before FT-154 (Broken)**:
- Rate limit hit → 15s delays for everything → User frustration → More messages → Worse delays
- Activities permanently lost during rate limits
- System stuck in recovery mode

### **After FT-154 (Robust)**:
- Rate limit hit → 3s user delays, 15s background → Quick user recovery
- Activities queued and processed later → Zero data loss
- Graduated user feedback → Reduced user frustration

## Success Criteria

### **Must Have**:
- ✅ **Zero activity loss** during rate limits
- ✅ **Faster user recovery** (3s vs 15s delays)
- ✅ **Activity queue processing** when system recovers
- ✅ **Graduated user feedback** based on consecutive failures

### **Performance Targets**:
- ✅ **User recovery**: 3s delays instead of 15s
- ✅ **Activity preservation**: 100% of activities eventually processed
- ✅ **Queue processing**: Within 30s of rate limit recovery
- ✅ **User communication**: Contextual messages based on failure count

## Implementation Plan

### **Step 1: Graduated Recovery (5 minutes)**
- Update SharedClaudeRateLimiter with differentiated recovery delays
- Reduce user-facing recovery from 15s to 3s
- Maintain 15s for background protection

### **Step 2: Activity Queue System (10 minutes)**
- Create ActivityQueue class with queueActivity() and processQueue()
- Add PendingActivity model for queued items
- Implement automatic queue processing on recovery

### **Step 3: Background Service Updates (5 minutes)**
- Update all background services to use ActivityQueue.queueActivity()
- Replace silent failures with activity preservation
- Maintain silent UX behavior

### **Step 4: Contextual Feedback (5 minutes)**
- Add consecutive failure tracking to ClaudeService
- Implement graduated user feedback messages
- Reset counter on successful responses

## Risk Assessment

**Risk Level**: **Very Low** (improves existing broken behavior)

**Benefits**:
- **Zero data loss** - activities preserved during rate limits
- **Better UX** - faster recovery, contextual feedback
- **System resilience** - graceful degradation under load
- **User satisfaction** - reduced frustration, maintained functionality

**Mitigations**:
- **Preserve all existing functionality** - only improve failure handling
- **Maintain rate limiting protection** - still prevent API abuse
- **Queue size limits** - prevent memory issues during extended outages
- **Comprehensive logging** - track queue operations and recovery

## Design Principles Applied

- ✅ **Graceful Degradation** - Slower but functional during overload
- ✅ **Data Preservation** - Never lose user activities
- ✅ **User-Centric Design** - Faster recovery, better communication
- ✅ **System Resilience** - Automatic recovery and queue processing

---

**Implementation Focus**: Transform rate limiting from a **system failure mode** into a **robust degradation strategy** that preserves all user data while maintaining system protection.
