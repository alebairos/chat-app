# FT-151: Minimal Claude API Rate Limiting Fix

**Priority**: High  
**Category**: Infrastructure  
**Effort**: 1 hour  
**Status**: Specification  

## Problem Statement

**Code Duplication + Rate Limit Bypass**: 4 services have identical `_callClaude()` implementations, but only `ClaudeService` tracks API calls for rate limiting. This causes HTTP 429 errors when background processes make uncoordinated API calls.

### Current Issues:
- **99% identical code** across 4 `_callClaude()` methods
- **Only `ClaudeService._callClaudeWithPrompt()`** uses rate limiting
- **3 services bypass rate limiting**: `SystemMCPService`, `SemanticActivityDetector`, `LLMActivityPreSelector`
- **Background activity detection** triggers untracked API calls

### Rate Limit Incident:
```
User conversation: ClaudeService._callClaudeWithPrompt() ✅ (tracked)
Background detection: SystemMCPService._callClaude() ❌ (untracked) 
Activity pre-selection: LLMActivityPreSelector._callClaude() ❌ (untracked)
Result: 3 rapid API calls, only 1 tracked = HTTP 429 Rate limit exceeded
```

## Solution: Shared Rate Limiter

### Core Principle: **Minimal Change, Maximum Fix**
Extract existing proven rate limiting logic into a shared component. **Zero functional changes** to existing features.

### Implementation

#### 1. **SharedClaudeRateLimiter** (New - 15 minutes)
```dart
/// Centralized rate limiting using proven ClaudeService logic
class SharedClaudeRateLimiter {
  static final _instance = SharedClaudeRateLimiter._internal();
  factory SharedClaudeRateLimiter() => _instance;
  SharedClaudeRateLimiter._internal();
  
  // Extracted from existing _RateLimitTracker (proven to work)
  static final List<DateTime> _apiCallHistory = [];
  static const int _maxCallsPerMinute = 8;
  static const Duration _rateLimitMemory = Duration(minutes: 2);
  static DateTime? _lastRateLimit;
  
  /// Apply rate limiting before API call
  Future<void> waitAndRecord() async {
    // Use existing adaptive delay logic from ClaudeService
    if (_hasRecentRateLimit()) {
      await Future.delayed(Duration(seconds: 15));
    } else if (_hasHighApiUsage()) {
      await Future.delayed(Duration(seconds: 8));
    }
    
    _apiCallHistory.add(DateTime.now());
    _cleanOldCalls();
  }
  
  /// Record rate limit event (for error handling)
  void recordRateLimit() {
    _lastRateLimit = DateTime.now();
  }
  
  // Copy existing methods from _RateLimitTracker
  bool _hasRecentRateLimit() { /* identical to existing */ }
  bool _hasHighApiUsage() { /* identical to existing */ }
  void _cleanOldCalls() { /* identical to existing */ }
}
```

#### 2. **Service Updates** (30 minutes)

**SystemMCPService** - Add ONE line:
```dart
Future<String> _callClaude(String prompt) async {
  await SharedClaudeRateLimiter().waitAndRecord(); // <-- ONLY CHANGE
  
  // Everything else IDENTICAL
  final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  final model = (dotenv.env['ANTHROPIC_MODEL'] ?? 'claude-3-5-sonnet-20241022').trim();
  // ... rest unchanged
  'max_tokens': 1024,           // PRESERVED
  'temperature': 0.1,           // PRESERVED
}
```

**SemanticActivityDetector** - Add ONE line:
```dart
static Future<String> _callClaude(String prompt) async {
  await SharedClaudeRateLimiter().waitAndRecord(); // <-- ONLY CHANGE
  
  // Everything else IDENTICAL
  'max_tokens': 1000,           // PRESERVED
  'temperature': 0.1,           // PRESERVED
}
```

**LLMActivityPreSelector** - Add ONE line:
```dart
static Future<String> _callClaude(String prompt) async {
  await SharedClaudeRateLimiter().waitAndRecord(); // <-- ONLY CHANGE
  
  // Everything else IDENTICAL  
  'max_tokens': 200,            // PRESERVED
  'temperature': 0.2,           // PRESERVED
}
```

#### 3. **ClaudeService Update** (15 minutes)
```dart
Future<String> _callClaudeWithPrompt(String prompt) async {
  await SharedClaudeRateLimiter().waitAndRecord(); // <-- REPLACE _RateLimitTracker.recordApiCall()
  
  // Everything else IDENTICAL
  // Remove _RateLimitTracker usage, use SharedClaudeRateLimiter for error handling
}
```

## Service-Specific Differences (PRESERVED)

| Service | `max_tokens` | `temperature` | Purpose |
|---------|-------------|---------------|---------|
| **ClaudeService** | 1024 | *none* | User conversations |
| **SystemMCPService** | 1024 | 0.1 | Oracle activity detection |
| **SemanticActivityDetector** | 1000 | 0.1 | Activity detection |
| **LLMActivityPreSelector** | 200 | 0.2 | Activity pre-selection |

## What Will NOT Change

- ✅ **Service interfaces** - All method signatures identical
- ✅ **Error handling** - Each service keeps specific error handling
- ✅ **Request parameters** - Different `max_tokens`/`temperature` preserved
- ✅ **FT-085 smart delays** - Already working, preserved
- ✅ **FT-140 token optimizations** - Already working, preserved  
- ✅ **Two-pass conversation flow** - Already working, preserved
- ✅ **Background activity detection** - Already working, preserved

## Expected Results

### Immediate Benefits:
- **✅ Zero rate limit errors** - All API calls coordinated
- **✅ Code deduplication** - 4 rate limiters → 1 shared rate limiter
- **✅ Zero functional changes** - All existing features preserved
- **✅ Minimal risk** - Only adding rate limiting, nothing else

### Performance Impact:
- **User conversations**: No change (already rate limited)
- **Background detection**: +2-8s delay (prevents rate limits, acceptable)
- **Activity pre-selection**: +2-8s delay (prevents rate limits, acceptable)

## Testing Strategy

### Unit Tests:
- **Rate limiting logic** - Verify shared limiter works identically to existing
- **Service parameters** - Verify all `max_tokens`/`temperature` preserved
- **Error handling** - Verify each service's error handling unchanged

### Integration Tests:
- **Multi-service coordination** - Simulate concurrent calls from different services
- **Rate limit prevention** - Verify no HTTP 429 errors under load
- **Existing features** - Verify all current functionality unchanged

## Implementation Timeline

**Total: 1 hour**
- **15 minutes**: Create `SharedClaudeRateLimiter` (extract existing logic)
- **30 minutes**: Update 4 services (add one line each)
- **15 minutes**: Update `ClaudeService` to use shared limiter

## Success Criteria

### Must Have:
- ✅ Zero HTTP 429 rate limit errors
- ✅ All services use shared rate limiter
- ✅ All existing functionality unchanged
- ✅ Code duplication eliminated

### Verification:
- ✅ All existing tests pass unchanged
- ✅ No new test failures
- ✅ Rate limit coordination working under load
- ✅ Service-specific parameters preserved

## Risk Assessment

**Risk Level**: **Low** (only adding rate limiting coordination)

**Mitigations**:
- Extract proven logic from existing `_RateLimitTracker`
- Add only one line per service
- Preserve all service-specific parameters
- No interface changes

---

**Implementation Focus**: Fix rate limiting coordination with **minimal code changes** and **zero functional impact**.
