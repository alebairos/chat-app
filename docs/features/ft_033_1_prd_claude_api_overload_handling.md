# FT-033 PRD: Claude API Overload Handling

## Product Overview
Implement simple, robust handling for Claude API overload errors (HTTP 529) to improve user experience during high-demand periods. The solution focuses on automatic retry with exponential backoff and clear user feedback.

## Problem Statement

### Current Issue
- **Error Observed**: `{"client_error": false, "code": 529, "detail": "Overloaded"}`
- **Latency Impact**: 2.602 seconds before failure
- **User Experience**: App fails with unclear error messages
- **No Recovery**: No automatic retry mechanism in place

### User Impact
- Users experience failed message sends during peak usage
- Unclear error messages ("Unable to send message")
- Manual retry required (frustrating UX)
- Lost conversation context if user gives up

## Solution: Simple Retry with Exponential Backoff

### Core Strategy
**"The Simplest Thing That Could Possibly Work"**
1. **Detect 529 errors** specifically
2. **Automatic retry** with exponential backoff
3. **User feedback** during retries
4. **Graceful degradation** after max attempts

### Technical Implementation

#### 1. Error Detection
```dart
// In ClaudeService.sendMessage()
if (response.statusCode == 529) {
  return await _handleOverloadError(message, retryCount);
}
```

#### 2. Retry Logic
```dart
Future<ClaudeResponse> _handleOverloadError(String message, int retryCount) async {
  const maxRetries = 3;
  const baseDelay = Duration(seconds: 2);
  
  if (retryCount >= maxRetries) {
    return ClaudeResponse(
      text: "Claude is experiencing high demand. Please try again in a few minutes.",
      isError: true
    );
  }
  
  // Exponential backoff: 2s, 4s, 8s
  final delay = Duration(seconds: baseDelay.inSeconds * (1 << retryCount));
  
  // Show user feedback
  _notifyRetrying(retryCount + 1, delay);
  
  await Future.delayed(delay);
  
  // Retry the request
  return await sendMessage(message, retryCount: retryCount + 1);
}
```

#### 3. User Feedback
```dart
void _notifyRetrying(int attempt, Duration delay) {
  final seconds = delay.inSeconds;
  final message = "Claude is busy. Retrying in ${seconds}s... (attempt $attempt/3)";
  
  // Show temporary message in chat
  _showTemporaryMessage(message);
}
```

## Implementation Requirements

### 1. ClaudeService Updates
**File**: `lib/services/claude_service.dart`

**Changes Required**:
- Add retry logic for 529 errors specifically
- Implement exponential backoff (2s, 4s, 8s)
- Add user notification system
- Maintain conversation context during retries

### 2. UI Feedback System
**File**: `lib/screens/chat_screen.dart`

**Changes Required**:
- Display retry status to user
- Show countdown timer during wait
- Maintain typing indicator during retries
- Clear temporary messages on success/failure

### 3. Error Message Improvements
**Current**: "Error: Unable to send message. Please try again later."
**New**: 
- During retry: "Claude is busy. Retrying in 4s... (attempt 2/3)"
- After failure: "Claude is experiencing high demand. Please try again in a few minutes."

## Technical Specifications

### Retry Configuration
```dart
class RetryConfig {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 2);
  static const List<int> retryableCodes = [429, 529, 503, 502];
}
```

### Exponential Backoff Formula
- **Attempt 1**: 2 seconds
- **Attempt 2**: 4 seconds  
- **Attempt 3**: 8 seconds
- **Total Max Time**: ~14 seconds before giving up

### Error Response Types
1. **529 Overloaded**: Claude API at capacity
2. **429 Rate Limited**: Too many requests
3. **503 Service Unavailable**: Temporary service issues
4. **502 Bad Gateway**: Infrastructure problems

## User Experience Flow

### Successful Retry Scenario
1. User sends message
2. API returns 529 error
3. App shows: "Claude is busy. Retrying in 2s... (attempt 1/3)"
4. Wait 2 seconds with countdown
5. Retry succeeds
6. Normal conversation continues

### Failed After Retries Scenario
1. User sends message
2. All 3 retry attempts fail with 529
3. App shows: "Claude is experiencing high demand. Please try again in a few minutes."
4. User can manually retry or wait

### UI States
- **Normal**: Standard typing indicator
- **Retrying**: "Claude is busy. Retrying in Xs... (attempt N/3)"
- **Failed**: Clear error message with suggestion

## Implementation Phases

### Phase 1: Core Retry Logic (2 hours)
- Implement 529 detection in ClaudeService
- Add exponential backoff retry mechanism
- Basic error message improvements

### Phase 2: User Feedback (1 hour)
- Add retry status display in chat
- Implement countdown timer
- Improve error messaging

### Phase 3: Polish & Testing (1 hour)
- Test with mock 529 responses
- Refine timing and user feedback
- Ensure conversation context preservation

## Testing Strategy

### Mock Testing
```dart
// Create mock service that returns 529 errors
class MockOverloadedClaudeService extends ClaudeService {
  @override
  Future<http.Response> post(Uri url, {required Map<String, String> headers, required String body}) {
    return Future.value(http.Response('{"error": "Overloaded"}', 529));
  }
}
```

### Test Cases
1. **Single retry success**: 529 → wait → success
2. **Multiple retries**: 529 → 529 → success
3. **Max retries exceeded**: 529 → 529 → 529 → final error
4. **Mixed errors**: 529 → 200 success
5. **User cancellation**: Allow user to cancel during retry

## Error Monitoring

### Metrics to Track
- **Retry success rate**: How often retries succeed
- **Average retry time**: Time from first attempt to success
- **529 error frequency**: How often overload occurs
- **User abandonment**: Users who stop after seeing retries

### Logging
```dart
Logger.info('Claude API overloaded, retrying in ${delay.inSeconds}s (attempt $attempt/$maxRetries)');
Logger.error('Claude API overload retry failed after $maxRetries attempts');
```

## Configuration Options

### Adjustable Parameters
```dart
class OverloadConfig {
  static int maxRetries = 3;              // Can be adjusted based on usage patterns
  static int baseDelaySeconds = 2;        // Base wait time
  static bool showCountdown = true;       // Show countdown to user
  static bool enableRetries = true;       // Emergency disable switch
}
```

## Success Criteria

### User Experience
- ✅ No more sudden "Unable to send message" failures during 529 errors
- ✅ Clear feedback about what's happening and expected wait time
- ✅ Automatic recovery in most cases (target: 70%+ success rate)

### Technical Requirements
- ✅ Retry logic isolated to ClaudeService
- ✅ No conversation context loss during retries
- ✅ Configurable retry parameters
- ✅ Proper error logging and monitoring

### Performance
- ✅ Maximum 14 seconds total retry time
- ✅ No impact on successful requests
- ✅ Graceful degradation under sustained load

## Edge Cases Handled

1. **Network disconnection during retry**: Fail gracefully
2. **User navigates away**: Cancel pending retries
3. **Multiple messages queued**: Handle each independently
4. **App backgrounded**: Respect system constraints
5. **Different error codes**: Only retry 529/429/503/502

## Future Enhancements

### Potential Improvements
1. **Smart retry timing**: Adjust delays based on success patterns
2. **Queue management**: Batch requests during high load
3. **Fallback modes**: Reduce features during overload
4. **User preferences**: Allow users to disable auto-retry

### Not Included (Scope Creep Prevention)
- ❌ Complex queue systems
- ❌ Request batching
- ❌ Circuit breaker patterns
- ❌ Multiple API endpoints
- ❌ Caching mechanisms

## Implementation Files

### Primary Changes
- `lib/services/claude_service.dart` - Core retry logic
- `lib/screens/chat_screen.dart` - User feedback display

### Supporting Changes
- Add retry configuration constants
- Improve error message strings
- Add logging for monitoring

## Conclusion

This simple retry mechanism addresses the immediate 529 overload issue with minimal complexity. The exponential backoff approach respects API constraints while providing a smooth user experience. The solution is focused, testable, and provides a foundation for future enhancements if needed.

**Key Philosophy**: Start simple, measure impact, iterate based on real usage patterns.

---

**Priority**: High (affects user experience during peak usage)  
**Effort**: 4 hours total  
**Dependencies**: None  
**Affects**: API reliability, User experience, Error handling
