# FT-155: Claude Overload Protection System

**Feature ID:** FT-155  
**Priority:** Critical  
**Category:** System Reliability  
**Effort:** 2-3 hours (first cut)  
**Dependencies:** FT-151, FT-152, FT-154  

## Problem Analysis

### Root Cause Identified
Based on production logs and Claude Console data, the system is experiencing cascading failures due to Claude API 529 "Overloaded" errors, which are fundamentally different from 429 "Rate Limited" errors.

### Critical Issues Found

#### 1. Claude API Overload Cascade
```
Lines 66, 83-84, 161, 619: Claude API error: 529 - {"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}
```

**The system hits Claude's 529 "Overloaded" errors repeatedly:**
- Claude servers reject requests due to high demand/capacity issues
- Different from rate limiting (429) - this is server capacity exhaustion
- Current rate limiting logic doesn't handle 529 errors properly

#### 2. Activity Detection Failure Chain
**Pattern observed:**
1. User reports activities: "1L de agua + 1 hora com familia"
2. System processes command and detects 2 activities correctly
3. Fails to save them due to subsequent 529 errors
4. User complains: "não marcou no banco de dados"
5. System correctly interprets complaint as non-activity

#### 3. FT-154 Queue System Issues
```
FT-154: Processing 2 queued activities
FT-154: No activities detected in queued message
```
- Activities queued when rate limits hit
- Queue processing fails with same 529 errors
- Queue items removed even when processing fails

#### 4. Rate Limiting vs Overload Confusion
Current system treats 529 (overloaded) same as 429 (rate limited):
- **429 = Too many requests** → Wait and retry
- **529 = Server overloaded** → Different backoff strategy needed

### Claude Console Data Analysis

#### Request Pattern (30-second window):
```
14:37:23 → SUCCESS (27,725 tokens in, 165 tokens out)
14:37:33 → SUCCESS (4,424 tokens in, 294 tokens out) 
14:37:41 → SUCCESS (27,818 tokens in, 178 tokens out)
14:37:54 → SUCCESS (4,420 tokens in, 133 tokens out)
14:41:54 → 529 ERROR (6.095s latency)
```

#### Key Findings:
- **6.095 seconds latency** before 529 error
- **27K+ token requests** are massive (Oracle context overload)
- **4-5 large requests in 30 seconds** overwhelmed Claude servers
- Console suggests: **"Implement retry logic with exponential backoff"**

#### API Call Analysis by Message:
- **Message 1**: 4 calls (1 success, 3 failures)
- **Message 2**: 2 calls (2 successes) 
- **Message 3**: 1+ calls (1 success, 1 failure)

**Call explosion**: Single user input triggers 2-4 API calls each.

## Proposed Solution: Multi-Layer Overload Protection

### Architecture Overview
```
User Message → Circuit Breaker → Smart Queuing → Optimized Requests → Claude API
                     ↓              ↓              ↓
              [OPEN/CLOSED]    [Batch/Defer]   [Compressed Context]
```

### Tier 1: Circuit Breaker Pattern
**Problem Addressed:**
- System keeps calling Claude after repeated 529s
- 6+ second latencies before failures
- No detection of Claude server stress

**Solution:**
```dart
class ClaudeCircuitBreaker {
  enum State { CLOSED, OPEN, HALF_OPEN }
  
  State _state = State.CLOSED;
  int _consecutiveFailures = 0;
  DateTime? _lastFailureTime;
  
  // Circuit opens after 2 consecutive 529s OR 1 slow response (>4s)
  bool shouldAllowRequest() {
    if (_state == State.OPEN) {
      // Stay open for exponentially increasing time
      Duration backoffTime = Duration(seconds: min(300, pow(2, _consecutiveFailures) * 30));
      if (DateTime.now().difference(_lastFailureTime!) > backoffTime) {
        _state = State.HALF_OPEN;
        return true; // Allow one test request
      }
      return false;
    }
    return true;
  }
  
  void recordSuccess() {
    _state = State.CLOSED;
    _consecutiveFailures = 0;
  }
  
  void recordFailure(int statusCode, Duration latency) {
    if (statusCode == 529 || latency.inSeconds > 4) {
      _consecutiveFailures++;
      _lastFailureTime = DateTime.now();
      
      if (_consecutiveFailures >= 2 || latency.inSeconds > 4) {
        _state = State.OPEN;
      }
    }
  }
}
```

### Tier 2: Smart Activity Queuing & Batching
**Problem Addressed:**
- Multiple API calls per user message (2-4 calls each)
- Activities lost when processing fails
- No intelligent request consolidation

**Solution:**
```dart
class SmartActivityProcessor {
  final Queue<PendingActivity> _activityQueue = Queue();
  Timer? _batchTimer;
  
  // Instead of immediate processing, batch activities
  Future<void> queueActivity(String message, DateTime timestamp) async {
    _activityQueue.add(PendingActivity(message, timestamp));
    
    // Process in batches every 10 seconds OR when circuit is closed
    _batchTimer?.cancel();
    _batchTimer = Timer(Duration(seconds: 10), _processBatch);
  }
  
  Future<void> _processBatch() async {
    if (!CircuitBreaker.shouldAllowRequest() || _activityQueue.isEmpty) {
      return; // Wait for circuit to close
    }
    
    // Batch up to 5 activities in single request
    List<PendingActivity> batch = [];
    for (int i = 0; i < min(5, _activityQueue.length); i++) {
      batch.add(_activityQueue.removeFirst());
    }
    
    try {
      await _processBatchedActivities(batch);
      CircuitBreaker.recordSuccess();
    } catch (e) {
      // Re-queue failed activities at front
      for (var activity in batch.reversed) {
        _activityQueue.addFirst(activity);
      }
      CircuitBreaker.recordFailure(e.statusCode, e.duration);
    }
  }
}
```

### Tier 3: Oracle Context Optimization
**Problem Addressed:**
- 27K+ token requests overwhelming Claude
- Massive Oracle context (265 activities) sent every time
- No context pruning or relevance filtering

**Solution:**
```dart
class OptimizedOracleContext {
  // Instead of sending all 265 activities, send only relevant subset
  Map<String, dynamic> getRelevantContext(String userMessage) {
    // 1. Keyword-based filtering
    Set<String> messageKeywords = _extractKeywords(userMessage);
    
    // 2. Get top 20 most relevant activities (not all 265)
    List<Activity> relevantActivities = _oracleActivities
        .where((activity) => _isRelevant(activity, messageKeywords))
        .take(20)
        .toList();
    
    // 3. Compress activity descriptions
    List<Map<String, String>> compressedActivities = relevantActivities
        .map((activity) => {
          'code': activity.code,
          'name': activity.name.length > 50 
              ? activity.name.substring(0, 50) + '...' 
              : activity.name,
          'dimension': activity.dimension
        })
        .toList();
    
    return {
      'relevant_activities': compressedActivities,
      'total_available': _oracleActivities.length,
      'context_size': 'optimized' // Signal to Claude this is filtered
    };
  }
  
  // Reduce from 27K tokens to ~3K tokens
  bool _isRelevant(Activity activity, Set<String> keywords) {
    String activityText = '${activity.name} ${activity.description}'.toLowerCase();
    return keywords.any((keyword) => activityText.contains(keyword.toLowerCase()));
  }
}
```

### Tier 4: Graceful Degradation
**Problem Addressed:**
- Users see "Claude is experiencing high demand" errors
- No fallback responses during outages
- Poor user experience during 529 periods

**Solution:**
```dart
class GracefulResponseHandler {
  Future<String> handleClaudeUnavailable(String userMessage) async {
    // Analyze message locally for basic patterns
    if (_containsActivityKeywords(userMessage)) {
      return """
Entendi! Vou registrar suas atividades assim que o sistema estiver disponível. 
Por enquanto, suas informações estão salvas e serão processadas em breve.
Continue me contando sobre seu dia! 📝
      """;
    }
    
    if (_containsQuestionKeywords(userMessage)) {
      return """
Ótima pergunta! O sistema está processando algumas informações no momento.
Que tal me contar mais sobre o que você fez hoje enquanto isso? 🤔
      """;
    }
    
    return """
Estou aqui ouvindo! O sistema está organizando algumas informações,
mas continue nossa conversa normalmente. 😊
    """;
  }
}
```

## Expected Impact

### Request Reduction:
- **Before**: 4 calls per message = 240 calls/hour (60 messages)
- **After**: 0.8 calls per message = 48 calls/hour (batching + circuit breaker)
- **85% reduction** in API calls

### Token Optimization:
- **Before**: 27K tokens per request
- **After**: 3K tokens per request  
- **90% reduction** in token usage

### Reliability Improvement:
- **Before**: 50% success rate during overload
- **After**: 95%+ success rate (circuit breaker + queuing)
- **Zero data loss** (persistent queuing)

### User Experience:
- **Before**: 6+ second delays → error messages
- **After**: Immediate responses → background processing
- **No error messages** shown to users

## First Cut Implementation (Priority 1)

### Focus: Circuit Breaker + 529 Error Handling
**Why This First:**
- **Fastest to implement**: ~2-3 hours
- **Biggest immediate impact**: Stops cascade failures
- **Builds on existing code**: Extends `SharedClaudeRateLimiter`
- **Zero data loss risk**: Safe to deploy

### Minimal Implementation:

#### 1. Add 529 Detection to Existing Rate Limiter
```dart
// In SharedClaudeRateLimiter class
static bool _claudeOverloaded = false;
static DateTime? _lastOverloadTime;
static int _overloadCount = 0;

static bool isClaudeOverloaded() {
  if (!_claudeOverloaded) return false;
  
  // Auto-recover after exponential backoff
  Duration backoff = Duration(seconds: min(300, pow(2, _overloadCount) * 30));
  if (DateTime.now().difference(_lastOverloadTime!) > backoff) {
    _claudeOverloaded = false;
    _overloadCount = 0;
    return false;
  }
  return true;
}

static void recordOverload() {
  _claudeOverloaded = true;
  _lastOverloadTime = DateTime.now();
  _overloadCount++;
}
```

#### 2. Update Error Handling in ClaudeService
```dart
// In _callClaudeWithPrompt method
if (response.statusCode == 529) {
  SharedClaudeRateLimiter.recordOverload();
  return _getOverloadFallbackResponse();
}

String _getOverloadFallbackResponse() {
  return "Entendi! Vou processar isso assim que possível. Continue me contando! 😊";
}
```

#### 3. Add Pre-Call Check
```dart
// In waitAndRecord method
if (SharedClaudeRateLimiter.isClaudeOverloaded()) {
  if (!isUserFacing) {
    throw Exception('Claude overloaded - skipping background call');
  }
  // For user-facing calls, allow with warning
}
```

### Expected Results (First Cut):

#### Immediate Benefits:
- **Stops 529 cascade failures** within hours
- **No more "high demand" error messages** to users
- **Exponential backoff**: 30s → 60s → 120s → 240s → 300s
- **Preserves existing functionality** completely

#### Impact Metrics:
- **Before**: 4 failed calls per 529 error
- **After**: 1 failed call, then circuit opens
- **User experience**: Always gets response (even if fallback)
- **System protection**: Automatic recovery

### Implementation Steps:
1. **30 minutes**: Add overload detection to `SharedClaudeRateLimiter`
2. **30 minutes**: Update error handling in `ClaudeService` 
3. **30 minutes**: Add pre-call checks
4. **30 minutes**: Test with rate limit battle test
5. **30 minutes**: Deploy and monitor

**Total: 2.5 hours for complete protection**

## Implementation Timeline

### Phase 1 (Week 1): Circuit Breaker
- Implement 529 error detection and exponential backoff
- Add graceful fallback responses
- Deploy and monitor

### Phase 2 (Week 2): Context Optimization  
- Implement Oracle context filtering (top 50 activities instead of 265)
- Add keyword-based relevance filtering
- Measure token reduction

### Phase 3 (Week 3): Smart Queuing
- Improve batching in existing FT-154 queue system
- Add intelligent request consolidation
- Implement batch processing

### Phase 4 (Week 4): Advanced Degradation
- Add smarter fallback response patterns
- Implement local activity pattern recognition
- Add recovery monitoring and metrics

## Success Metrics

### Technical Metrics:
- **529 Error Rate**: < 1% (currently ~50%)
- **API Call Frequency**: < 1 call per user message (currently 2-4)
- **Token Usage**: < 5K tokens per request (currently 27K)
- **Response Latency**: < 2 seconds average (currently 6+ seconds)

### User Experience Metrics:
- **Error Messages**: 0 visible to users (currently frequent)
- **Activity Loss**: 0% (currently ~30% during overload)
- **Response Success**: 99%+ (currently ~50% during overload)
- **User Satisfaction**: Maintain conversational flow during outages

## Risk Assessment

### Low Risk (First Cut):
- Builds on existing, tested rate limiting system
- Additive changes only (no breaking modifications)
- Graceful degradation preserves functionality
- Easy rollback via feature flag

### Medium Risk (Later Phases):
- Oracle context changes require careful testing
- Batching logic needs validation with real data
- Token optimization may affect accuracy

### Mitigation Strategies:
- Feature flags for each component
- A/B testing for context optimization
- Gradual rollout with monitoring
- Immediate rollback capability

## Monitoring and Alerting

### Key Metrics to Track:
- Circuit breaker state changes
- 529 error frequency and recovery time
- Token usage per request
- Activity queue size and processing time
- User-visible error rate

### Alert Thresholds:
- Circuit breaker open for > 5 minutes
- 529 error rate > 5%
- Activity queue size > 100 items
- Token usage > 10K per request
- User error rate > 0.1%

## Conclusion

This multi-tier approach addresses the root causes of Claude API overload while providing immediate protection through the circuit breaker pattern. The first cut implementation can be deployed within hours to stop cascade failures, while subsequent phases optimize for long-term scalability and user experience.

The solution is designed to be:
- **Incremental**: Each phase builds on the previous
- **Safe**: Non-breaking changes with easy rollback
- **Measurable**: Clear metrics for success validation
- **User-focused**: Maintains conversational experience during outages

**Priority**: Implement First Cut (Circuit Breaker) immediately to stop production issues.
