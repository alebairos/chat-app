# FT-149.2: Metadata Completeness Strategy

## Problem Statement

Current metadata extraction achieves only **30-70% completeness** due to rate limiting and error handling that falls back to basic metadata instead of ensuring rich metadata for all activities.

## Completeness Goals

- **Target**: 95%+ of activities have rich metadata (Performance + Behavioral + Quantitative sections)
- **Acceptable**: 5% fallback to basic metadata only in extreme failure cases
- **Unacceptable**: Current 70% fallback rate due to rate limits

## Enhanced Retry Strategy

### 1. Intelligent Batching
```dart
class MetadataExtractionQueue {
  // Current: Process 3 tasks simultaneously → Rate limits
  // Enhanced: Process 1 task every 2 seconds → Avoid rate limits
  
  static const Duration _batchDelay = Duration(seconds: 2);
  static const int _maxConcurrentTasks = 1; // Reduced from 3
}
```

### 2. Extended Retry Policy
```dart
// Current: 3 retries → Fallback
// Enhanced: 5 retries with longer backoff → Higher success rate

static const int _maxRetriesPerTask = 5; // Increased from 3
static const Duration _maxRetryDelay = Duration(hours: 2); // Extended window
```

### 3. Persistent Queue with Recovery
```dart
// Store failed tasks in database for later retry
class PersistentMetadataQueue {
  // Retry failed extractions during low-traffic periods
  // Background processing during app idle time
  // Manual retry trigger for important activities
}
```

### 4. Quality-Based Fallback Tiers

Instead of binary rich/basic metadata:

**Tier 1**: Full Universal Framework (Quantitative + Qualitative + Relational + Behavioral)
**Tier 2**: Reduced Framework (Quantitative + Behavioral only)  
**Tier 3**: Basic Framework (Quantitative only)
**Tier 4**: Fallback (Activity code + category + context)

### 5. Proactive Rate Limit Management

```dart
class RateLimitPredictor {
  // Track API usage patterns
  // Predict rate limit windows
  // Schedule extractions during low-usage periods
  // Implement circuit breaker pattern
}
```

## Implementation Phases

### Phase 1: Immediate Improvements (1-2 hours)
- Reduce concurrent processing from 3 to 1 task
- Increase retry count from 3 to 5
- Extend retry window from 1 hour to 2 hours

### Phase 2: Enhanced Retry Logic (2-3 hours)  
- Implement tiered fallback system
- Add persistent queue for failed tasks
- Background retry during app idle time

### Phase 3: Predictive Management (4-6 hours)
- Rate limit prediction and avoidance
- Intelligent scheduling based on usage patterns
- Circuit breaker for API health monitoring

## Success Metrics

- **Completeness Rate**: % of activities with rich metadata
- **Retry Success Rate**: % of retries that succeed vs. fallback
- **Time to Completion**: Average time from detection to rich metadata
- **API Efficiency**: Requests per successful extraction

## Monitoring Dashboard

Track in real-time:
- Current completeness rate
- Queue status and backlog
- Rate limit incidents
- Retry success patterns
- Cost per successful extraction

## Cost Analysis

**Current Cost**: ~$0.0003 per extraction attempt (many failures)
**Enhanced Cost**: ~$0.0005 per successful extraction (higher success rate)
**Net Impact**: Lower total cost due to fewer retries and higher success rate
