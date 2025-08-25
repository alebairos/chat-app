# FT-086: Activity Detection False Positive Fix

**Feature ID:** FT-086  
**Priority:** Critical  
**Category:** Data Quality  
**Effort Estimate:** 1-2 hours  
**Status:** Specification  
**Created:** 2025-01-26  

## Problem Statement

FT-064 semantic activity detection is creating **false positive activities** by incorrectly detecting assistant responses about activities as actual user activities, causing data pollution and inaccurate tracking.

### **Critical Issue:**
```
User: "What did I drink today?"
Assistant: "You drank water 5 times: 01:33, 01:34, 15:45, 23:07, 23:14"
FT-064: INCORRECTLY detects this as NEW water consumption → Logs FALSE activity
```

**Result:** Asking about activities creates fake new activities, polluting the database.

## Evidence from Database

### **False Positives Identified:**
```json
{"timestamp": "23:07", "notes": "Assistant mentioned hydration"}
{"timestamp": "23:14", "notes": "User asked about water drinking, assistant confirmed timestamps"}
{"timestamp": "23:22", "notes": "Assistant confirmed user drank water 5 times at specific times"}
{"timestamp": "23:56", "notes": "Assistant mentioned 6 hydration moments completed"}
```

### **Pattern Recognition:**
- **Real activities**: "Activity explicitly logged in system"
- **False positives**: "Assistant mentioned...", "Assistant confirmed..."

## Root Cause Analysis

### **Current FT-064 Logic Flaw:**
```dart
// PROBLEMATIC: Analyzes ALL conversation content
final conversationForAnalysis = _conversationHistory
    .map((msg) => msg['content'][0]['text'])
    .join('\n');  // ❌ Includes assistant responses
```

**Issue:** Cannot distinguish between:
1. **User stating activities** (should detect)
2. **Assistant discussing activities** (should ignore)

## Solution: Context-Aware Activity Detection

### **Core Fix Strategy:**
**Only analyze USER messages for activity detection** - Assistant responses should NEVER generate activity records.

### **Implementation Approach:**

#### **Phase 1: Message Role Filtering (Immediate Fix)**
Filter conversation analysis to USER messages only:

```dart
// FIXED: Only analyze user messages
final userMessagesOnly = _conversationHistory
    .where((msg) => msg['role'] == 'user')
    .map((msg) => msg['content'][0]['text'])
    .join('\n');
```

#### **Phase 2: Enhanced Semantic Prompts (Quality Improvement)**
Improve activity detection accuracy with context-aware prompts:

```dart
final improvedPrompt = '''
CRITICAL INSTRUCTION: Detect ONLY actual activities the user performed.

DETECT these patterns:
- "I just drank water" → SF1 ✅
- "Had breakfast" → SF2 ✅
- "Finished workout" → SF13 ✅

IGNORE these patterns:
- "What did I drink?" → IGNORE ❌
- "Show my activities" → IGNORE ❌
- "How many times did I..." → IGNORE ❌

USER MESSAGE: "$userMessage"

Only return activities the user explicitly states they COMPLETED.
''';
```

## Implementation Details

### **Target Files:**
1. `lib/services/claude_service.dart` - Background activity detection call
2. `lib/features/audio_assistant/services/activity_detection_service.dart` - Core detection logic

### **Change 1: Message Filtering**
```dart
// In _performBackgroundActivityDetection()
Future<void> _performBackgroundActivityDetection(
    String userMessage, String assistantResponse) async {
  
  // FT-086: Critical fix - Only analyze USER messages for activities
  // Assistant responses about activities should NOT create new activity records
  final userOnlyConversation = _conversationHistory
      .where((msg) => msg['role'] == 'user')
      .map((msg) => {
        'content': msg['content'][0]['text'],
        'timestamp': msg['timestamp'] ?? DateTime.now().toIso8601String()
      })
      .toList();
      
  if (userOnlyConversation.isEmpty) {
    _logger.debug('FT-086: No user messages to analyze for activities');
    return;
  }
      
  // Proceed with activity detection using user messages only
  await _analyzeUserActivities(userOnlyConversation);
}
```

### **Change 2: Enhanced Detection Prompt**
```dart
final activityDetectionPrompt = '''
SYSTEM: You are analyzing USER MESSAGES ONLY for actual completed activities.

CRITICAL RULES:
1. ONLY detect activities explicitly stated as COMPLETED by the user
2. IGNORE questions about activities ("what did I do?", "show me...")
3. IGNORE requests for information about past activities  
4. IGNORE hypothetical or planned activities
5. IGNORE discussions about activity tracking itself

VALID ACTIVITY PATTERNS:
- "I drank water" / "just had water" → SF1
- "ate breakfast" / "had lunch" → SF2  
- "went for a run" / "did workout" → SF13
- "took vitamins" / "had supplements" → SF4

INVALID PATTERNS (DO NOT DETECT):
- "what did I drink today?" → IGNORE
- "show my water intake" → IGNORE
- "how many times did I exercise?" → IGNORE
- "what activities did I do?" → IGNORE

USER MESSAGES TO ANALYZE:
${userOnlyConversation.map((msg) => msg['content']).join('\n---\n')}

Return ONLY actual completed activities with high confidence (>0.95).
''';
```

### **Change 3: Confidence Validation**
```dart
// Enhanced validation before storing activities
Future<void> _storeDetectedActivity(DetectedActivity activity) async {
  // FT-086: Strict validation to prevent false positives
  if (activity.confidenceScore < 0.95) {
    _logger.debug('FT-086: Rejecting low confidence activity: ${activity.confidenceScore}');
    return;
  }
  
  if (activity.source?.contains('assistant') == true || 
      activity.notes?.toLowerCase().contains('assistant') == true) {
    _logger.warning('FT-086: Blocking assistant-derived activity: ${activity.notes}');
    return;
  }
  
  // Additional validation: Check if this looks like a query response
  final suspiciousPatterns = [
    'mentioned', 'confirmed', 'listed', 'showed', 'discussed'
  ];
  
  if (suspiciousPatterns.any((pattern) => 
      activity.notes?.toLowerCase().contains(pattern) == true)) {
    _logger.warning('FT-086: Blocking suspicious activity pattern: ${activity.notes}');
    return;
  }
  
  // Store validated activity
  await _activityMemoryService.storeActivity(activity);
  _logger.info('FT-086: ✅ Stored validated user activity: ${activity.activityCode}');
}
```

## Expected Results

### **Before Fix:**
```
User: "What did I drink today?"
Assistant: "You drank water 5 times: 01:33, 01:34, 15:45, 23:07, 23:14"
FT-064: Detects "drank water 5 times" → Creates FALSE SF1 activity ❌
Database: Polluted with assistant-derived activities
```

### **After Fix:**
```
User: "What did I drink today?"  
Assistant: "You drank water 5 times: 01:33, 01:34, 15:45, 23:07, 23:14"
FT-086: Recognizes this is user QUERY, not activity statement → No activity logged ✅
Database: Clean, accurate activity records only
```

### **Real Activity Detection (Preserved):**
```
User: "Just finished drinking water"
FT-086: High confidence user activity statement → Logs SF1 ✅
Database: Accurate activity with proper timestamp
```

## Quality Improvements

### **Data Accuracy Metrics:**
- **False Positive Rate**: Target <5% (down from ~50%)
- **True Positive Rate**: Maintain >90% 
- **Database Cleanliness**: Eliminate feedback loop pollution

### **Specific Improvements:**
1. **SF1 (Water)**: Stop detecting assistant water summaries as new consumption
2. **All Activities**: Only log actual user-performed activities
3. **Query Responses**: Distinguish between asking about vs doing activities

## Implementation Plan

### **Phase 1: Critical Fix (30 minutes)**
1. Implement message role filtering in `_performBackgroundActivityDetection()`
2. Add validation to block assistant-derived activities
3. Test with recent conversation examples
4. Deploy immediately to stop new false positives

### **Phase 2: Enhanced Detection (1 hour)**
1. Improve semantic prompts for better context awareness
2. Add confidence scoring validation
3. Test accuracy with various activity types

### **Phase 3: Data Audit (30 minutes)**
1. Review recent activities for false positive patterns
2. Flag suspicious entries for potential cleanup
3. Monitor new detection accuracy

## Testing Strategy

### **Test Cases:**
```dart
// Test 1: Query should NOT create activity
"What did I drink today?" → Expected: No activity logged

// Test 2: Statement should create activity  
"Just had a glass of water" → Expected: SF1 logged

// Test 3: Assistant response should NOT create activity
Assistant: "You completed SF1 5 times" → Expected: No activity logged

// Test 4: Discussion should NOT create activity
"How often should I drink water?" → Expected: No activity logged
```

### **Validation:**
- Monitor database for assistant-derived activities
- Check activity notes for suspicious patterns
- Verify real activities still detected correctly

## Success Criteria

### **Functional Requirements:**
- [ ] Zero activities created from assistant responses
- [ ] Zero activities created from user queries about activities
- [ ] Real user activity statements still detected accurately
- [ ] No degradation in legitimate activity detection

### **Quality Metrics:**
- [ ] False positive rate <5%
- [ ] No activities with notes containing "assistant mentioned"
- [ ] Clean separation between doing vs discussing activities

## Risk Assessment

### **Implementation Risk:** ✅ MINIMAL
- **Change scope**: Modify existing detection filters
- **Rollback**: Easy to revert if issues arise
- **Breaking changes**: None - only improves accuracy

### **Data Risk:** ✅ LOW
- **Historical data**: Unchanged
- **New detections**: Higher quality only
- **User experience**: Improved accuracy, no functionality loss

## Conclusion

FT-086 solves the critical data quality issue where assistant responses about activities were being incorrectly detected as new user activities. The fix ensures that only genuine user activity statements generate database records.

**Core Principle:** Activity detection should only track what users DO, not what they DISCUSS.

**Implementation Priority:** Critical - Deploy immediately to prevent further database pollution.

**Expected Impact:** Clean, accurate activity tracking that reflects actual user behavior rather than conversation artifacts.
