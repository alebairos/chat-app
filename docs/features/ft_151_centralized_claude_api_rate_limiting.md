# FT-151: Centralized Claude API Rate Limiting

**Priority**: High  
**Category**: Infrastructure  
**Effort**: 3 hours  
**Status**: Specification  

## Problem Statement

The current architecture has **multiple services making independent Claude API calls** without coordination, leading to rate limit exceeded errors (HTTP 429). Analysis shows:

### Current Issues:
- **4 different `_callClaude()` methods** across services
- **Only `ClaudeService` tracks API calls** for rate limiting
- **Uncoordinated API calls** bypass rate limiting entirely
- **Background activity detection** triggers additional untracked calls

### Rate Limit Incident Analysis:
```
Line 884: ClaudeService._callClaudeWithPrompt() ✅ (tracked)
Line 918: SystemMCPService._callClaude() ❌ (untracked) 
Line 994: Error recovery call ❌ (untracked)
Result: 3 rapid API calls, only 1 tracked = Rate limit exceeded
```

## Solution Architecture

### Core Principle: **Single Point of API Access**
All Claude API calls must flow through a centralized, rate-limited service.

### Components:

#### 1. **ClaudeAPIManager** (New)
- **Purpose**: Single point for all Claude API calls
- **Features**: 
  - Global rate limiting (8 calls/minute)
  - Request queuing with priority levels
  - Automatic retry with exponential backoff
  - Circuit breaker for sustained failures

#### 2. **Request Priority System**
```dart
enum ClaudeRequestPriority {
  critical,    // User conversations (immediate)
  high,        // Activity detection (background)
  normal,      // Pre-selection, analytics
  low          // Non-essential operations
}
```

#### 3. **Centralized Rate Limiting**
```dart
class ClaudeRateLimiter {
  static const int maxCallsPerMinute = 8;
  static const Duration rateLimitWindow = Duration(minutes: 1);
  static const Duration circuitBreakerTimeout = Duration(minutes: 5);
}
```

## Implementation Plan

### Phase 1: Create Centralized API Manager (1.5 hours)

#### 1.1 Create `ClaudeAPIManager`
```dart
class ClaudeAPIManager {
  static final ClaudeAPIManager _instance = ClaudeAPIManager._internal();
  factory ClaudeAPIManager() => _instance;
  
  // Request queue with priority
  final PriorityQueue<ClaudeRequest> _requestQueue;
  
  // Rate limiting state
  final List<DateTime> _apiCallHistory = [];
  DateTime? _lastRateLimit;
  bool _circuitBreakerOpen = false;
  
  Future<String> makeRequest(
    String prompt, {
    ClaudeRequestPriority priority = ClaudeRequestPriority.normal,
    Duration? timeout,
    int maxRetries = 3,
  });
}
```

#### 1.2 Implement Request Queuing
- **Priority-based queue** for request ordering
- **Rate limit checking** before each request
- **Automatic delays** between requests
- **Circuit breaker** for sustained failures

#### 1.3 Enhanced Error Handling
```dart
class ClaudeAPIException implements Exception {
  final ClaudeErrorType type;
  final String message;
  final bool isRetryable;
  final Duration? retryAfter;
}

enum ClaudeErrorType {
  rateLimitExceeded,
  serviceOverloaded,
  authenticationFailed,
  networkError,
  circuitBreakerOpen,
}
```

### Phase 2: Migrate Existing Services (1 hour)

#### 2.1 Update `SystemMCPService`
```dart
// BEFORE:
Future<String> _callClaude(String prompt) async {
  // Direct API call - NO rate limiting
}

// AFTER:
Future<String> _callClaude(String prompt) async {
  return await ClaudeAPIManager().makeRequest(
    prompt,
    priority: ClaudeRequestPriority.high, // Activity detection
    timeout: Duration(seconds: 30),
  );
}
```

#### 2.2 Update `SemanticActivityDetector`
```dart
// AFTER:
static Future<String> _callClaude(String prompt) async {
  return await ClaudeAPIManager().makeRequest(
    prompt,
    priority: ClaudeRequestPriority.high, // Activity detection
  );
}
```

#### 2.3 Update `LLMActivityPreSelector`
```dart
// AFTER:
static Future<String> _callClaude(String prompt) async {
  return await ClaudeAPIManager().makeRequest(
    prompt,
    priority: ClaudeRequestPriority.normal, // Pre-selection
  );
}
```

#### 2.4 Update `ClaudeService`
```dart
// AFTER:
Future<String> _callClaudeWithPrompt(String prompt) async {
  return await ClaudeAPIManager().makeRequest(
    prompt,
    priority: ClaudeRequestPriority.critical, // User conversation
    timeout: Duration(seconds: 45),
  );
}
```

### Phase 3: Advanced Rate Limiting (30 minutes)

#### 3.1 Adaptive Delays
```dart
Duration _calculateDelay() {
  if (_circuitBreakerOpen) return Duration(minutes: 5);
  if (_hasRecentRateLimit()) return Duration(seconds: 15);
  if (_isHighUsage()) return Duration(seconds: 8);
  return Duration(seconds: 2); // Minimum delay
}
```

#### 3.2 Request Batching
- **Batch similar requests** when possible
- **Debounce rapid requests** from same source
- **Smart queuing** based on request similarity

## Expected Results

### Immediate Benefits:
- **✅ Zero rate limit errors** - All calls coordinated
- **✅ Improved reliability** - Circuit breaker prevents cascading failures
- **✅ Better user experience** - Priority ensures conversations aren't blocked
- **✅ Reduced API costs** - Fewer redundant calls

### Performance Metrics:
- **Rate limit errors**: 100% → 0%
- **API call efficiency**: +25% (reduced redundancy)
- **User conversation latency**: No impact (critical priority)
- **Background detection latency**: +2-5s (acceptable for background)

### Monitoring:
```dart
class ClaudeAPIMetrics {
  static int totalRequests = 0;
  static int rateLimitHits = 0;
  static int circuitBreakerTrips = 0;
  static Duration averageResponseTime = Duration.zero;
  
  static Map<String, dynamic> getMetrics();
}
```

## Testing Strategy

### Unit Tests:
- **Rate limiting logic** - Verify call throttling
- **Priority queue** - Ensure correct ordering
- **Circuit breaker** - Test failure scenarios
- **Error handling** - Verify graceful degradation

### Integration Tests:
- **Multi-service coordination** - Simulate concurrent calls
- **Rate limit recovery** - Test automatic retry
- **Priority handling** - Verify user conversations aren't blocked

### Load Tests:
- **Burst traffic** - Multiple rapid requests
- **Sustained load** - Long-term API usage patterns
- **Failure scenarios** - API unavailability, network issues

## Migration Strategy

### Phase 1: Non-Breaking Changes
1. Create `ClaudeAPIManager` alongside existing code
2. Add feature flag: `centralized_claude_api: false`
3. Implement with comprehensive logging

### Phase 2: Gradual Migration
1. Enable for `SystemMCPService` first (lowest risk)
2. Monitor for 24 hours, verify no issues
3. Enable for other services sequentially
4. Full rollout with `centralized_claude_api: true`

### Phase 3: Cleanup
1. Remove old `_callClaude()` methods
2. Remove feature flag
3. Update documentation

## Risk Mitigation

### Risks:
1. **Single point of failure** - API manager becomes bottleneck
2. **Increased latency** - Queuing adds delays
3. **Complex debugging** - Centralized errors harder to trace

### Mitigations:
1. **Robust error handling** - Circuit breaker prevents cascades
2. **Priority system** - Critical requests bypass queue
3. **Comprehensive logging** - Request tracing with IDs
4. **Gradual rollout** - Feature flag allows instant rollback

## Success Criteria

### Must Have:
- ✅ Zero rate limit errors in production
- ✅ All services use centralized API manager
- ✅ User conversations maintain current latency
- ✅ Background detection continues working

### Should Have:
- ✅ 25% reduction in total API calls
- ✅ Circuit breaker prevents service degradation
- ✅ Comprehensive metrics and monitoring
- ✅ Automatic recovery from rate limits

### Could Have:
- ✅ Request batching for efficiency
- ✅ Predictive rate limiting
- ✅ API usage analytics dashboard

## Dependencies

### Technical:
- No breaking changes to existing APIs
- Maintains current service interfaces
- Compatible with existing error handling

### Operational:
- Monitoring dashboard updates
- Alert thresholds adjustment
- Documentation updates

## Acceptance Criteria

1. **Zero Rate Limits**: No HTTP 429 errors in 7-day monitoring period
2. **Service Reliability**: 99.9% uptime for Claude API calls
3. **Performance**: User conversation latency < 3s (95th percentile)
4. **Monitoring**: Real-time metrics dashboard operational
5. **Recovery**: Automatic recovery from rate limits within 2 minutes
6. **Testing**: 100% test coverage for rate limiting logic

---

**Implementation Timeline**: 3 hours total
- Phase 1: 1.5 hours (Core API manager)
- Phase 2: 1 hour (Service migration)  
- Phase 3: 30 minutes (Advanced features)

**Risk Level**: Medium (centralized architecture change)
**Impact**: High (eliminates rate limiting issues)
