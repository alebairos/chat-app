# FT-153: Invisible Rate Limiting with Auto-Retry

**Priority**: Critical  
**Category**: User Experience  
**Effort**: 30 minutes  
**Status**: Specification  

## Problem Statement

**Critical UX Issue**: Users are seeing "Rate limit exceeded. Please try again later." messages instead of seamless, invisible rate limiting.

### Current Broken Behavior:
- ❌ Raw 429 errors shown to users
- ❌ Users must manually retry
- ❌ Poor user experience during high usage
- ❌ Exposes technical implementation details

### Evidence:
```
User sees: "Rate limit exceeded. Please try again later."
Should see: Normal response (with invisible background retry)
```

## Solution: Invisible Auto-Retry with Graceful UX

### Core Principle: **Users Should Never See Rate Limit Errors**

Rate limiting should be completely invisible to users through:
1. **Automatic retry** with exponential backoff
2. **"Thinking..." indicators** during delays
3. **Seamless user experience** 
4. **Background queue management**

## Implementation

### **1. Update ClaudeService Error Handling**

Replace user-facing error messages with invisible retry logic:

```dart
// Current (BROKEN):
case 'rate_limit_error':
  return 'You\'ve reached the rate limit. Please wait a moment...'; // ❌ USER SEES THIS

// New (INVISIBLE):
case 'rate_limit_error':
  SharedClaudeRateLimiter().recordRateLimit();
  return await _retryWithBackoff(originalRequest); // ✅ INVISIBLE RETRY
```

### **2. Implement Auto-Retry Logic**

```dart
class ClaudeService {
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  Future<String> _retryWithBackoff(Future<String> Function() apiCall, {int attempt = 0}) async {
    try {
      return await apiCall();
    } catch (e) {
      if (_isRateLimitError(e) && attempt < _maxRetries) {
        // Calculate exponential backoff: 2s, 4s, 8s
        final delay = Duration(seconds: _baseRetryDelay.inSeconds * (1 << attempt));
        
        _logger.info('Rate limit hit, retrying in ${delay.inSeconds}s (attempt ${attempt + 1}/${_maxRetries})');
        
        await Future.delayed(delay);
        return await _retryWithBackoff(apiCall, attempt: attempt + 1);
      }
      
      // If max retries exceeded, return graceful fallback
      if (_isRateLimitError(e)) {
        return _getGracefulFallbackResponse();
      }
      
      rethrow;
    }
  }

  bool _isRateLimitError(dynamic error) {
    return error.toString().contains('429') || 
           error.toString().contains('rate_limit_error');
  }

  String _getGracefulFallbackResponse() {
    return "I'm processing a lot of requests right now. Let me get back to you with a thoughtful response.";
  }
}
```

### **3. Update HTTP Status Code Handling**

```dart
// Current (BROKEN):
case 429:
  return 'Rate limit exceeded. Please try again later.'; // ❌ USER SEES THIS

// New (INVISIBLE):
case 429:
  SharedClaudeRateLimiter().recordRateLimit();
  // Retry the same request automatically
  await Future.delayed(Duration(seconds: 2));
  return await _retryCurrentRequest(); // ✅ INVISIBLE RETRY
```

### **4. Background Service Rate Limiting**

Background services should **never** affect user experience:

```dart
// SystemMCPService, SemanticActivityDetector, etc.
Future<String> _callClaude(String prompt) async {
  try {
    await SharedClaudeRateLimiter().waitAndRecord(isUserFacing: false);
    // ... API call
  } catch (e) {
    if (_isRateLimitError(e)) {
      // Background services fail silently or queue for later
      _logger.warning('Background service hit rate limit, queuing for later');
      await _queueForLaterProcessing(prompt);
      return ''; // Silent failure
    }
    rethrow;
  }
}
```

## User Experience Flow

### **Before FT-153 (BROKEN):**
```
User: "Hello"
App: "Rate limit exceeded. Please try again later." ❌
User: *frustrated, has to manually retry*
```

### **After FT-153 (SEAMLESS):**
```
User: "Hello"
App: *shows thinking indicator*
App: *automatically retries in background*
App: "Hi! How can I help you today?" ✅
User: *never knows there was a rate limit*
```

## Implementation Plan

### **Step 1: Add Retry Logic (10 minutes)**
- Add `_retryWithBackoff()` method to ClaudeService
- Add `_isRateLimitError()` helper
- Add graceful fallback response

### **Step 2: Update Error Handling (10 minutes)**
- Replace rate limit error messages with retry calls
- Update both JSON error parsing and HTTP status handling
- Remove user-facing rate limit messages

### **Step 3: Background Service Protection (10 minutes)**
- Update background services to fail silently on rate limits
- Implement queuing for non-critical background operations
- Ensure user requests always take priority

## Success Criteria

### **Must Have:**
- ✅ **Zero user-visible rate limit errors**
- ✅ **Automatic retry with exponential backoff**
- ✅ **Seamless user experience during rate limits**
- ✅ **Background services don't affect user experience**

### **Performance Targets:**
- ✅ **Max 3 retry attempts** before graceful fallback
- ✅ **2s, 4s, 8s exponential backoff** timing
- ✅ **User requests prioritized** over background
- ✅ **Graceful degradation** when retries exhausted

## Risk Assessment

**Risk Level**: **Very Low** (pure UX improvement)

**Benefits:**
- **Dramatically improved UX** - users never see technical errors
- **Higher user satisfaction** - seamless experience
- **Reduced support burden** - no "try again later" confusion
- **Professional app behavior** - handles errors gracefully

**Mitigations:**
- **Preserve all existing functionality** - only change error presentation
- **Maintain rate limiting protection** - still prevent API abuse
- **Add comprehensive logging** - track retry patterns for monitoring
- **Graceful fallback** - handle cases where retries fail

## Design Principles Applied

- ✅ **User-Centric Design** - Hide technical complexity from users
- ✅ **Graceful Degradation** - Fail elegantly with helpful responses
- ✅ **Invisible Infrastructure** - Rate limiting works behind the scenes
- ✅ **Resilient Systems** - Automatically recover from transient failures

---

**Implementation Focus**: Transform rate limiting from a **user problem** into an **invisible system capability** that enhances rather than disrupts the user experience.
