# FT-149.3: Immediate Metadata Completeness Fix

## Quick Win Strategy (30 minutes implementation)

### Problem
- Recent activities getting fallback metadata due to rate limits
- 70% completeness loss from 429 errors

### Solution: Conservative Processing

#### 1. Reduce Concurrent Processing
```dart
// In MetadataExtractionQueue._processQueue()
// Current: Process up to 3 tasks simultaneously
final readyTasks = sortedTasks.where(...).take(3);

// Fix: Process 1 task at a time
final readyTasks = sortedTasks.where(...).take(1);
```

#### 2. Increase Inter-Task Delay
```dart
// Current: 500ms delay between tasks
await Future.delayed(Duration(milliseconds: 500));

// Fix: 3 second delay between tasks  
await Future.delayed(Duration(seconds: 3));
```

#### 3. Extend Retry Attempts
```dart
// Current: 3 retries maximum
static const int _maxRetriesPerTask = 3;

// Fix: 5 retries maximum
static const int _maxRetriesPerTask = 5;
```

#### 4. Longer Retry Windows
```dart
// Current: 1 minute base cooldown
static const Duration _rateLimitCooldown = Duration(minutes: 1);

// Fix: 2 minute base cooldown
static const Duration _rateLimitCooldown = Duration(minutes: 2);
```

## Expected Results

- **Rate Limit Reduction**: 90% fewer 429 errors
- **Completeness Improvement**: 30% → 85% rich metadata
- **Processing Time**: Slower but more reliable
- **Cost Efficiency**: Fewer wasted API calls

## Implementation Steps

1. Update `MetadataExtractionQueue` constants
2. Test with new activity detection
3. Monitor logs for rate limit reduction
4. Measure completeness improvement

## Rollback Plan

If issues occur:
1. Revert constants to original values
2. Monitor system stability
3. Investigate alternative approaches

## Success Criteria

- ✅ Zero 429 rate limit errors in logs
- ✅ 85%+ activities have rich metadata sections
- ✅ Queue processing remains stable
- ✅ No increase in app response time
