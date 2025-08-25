# FT-086: Activity Detection Accuracy Improvement

**Feature ID:** FT-086  
**Priority:** High  
**Category:** Data Quality  
**Effort Estimate:** 2-3 hours  
**Status:** Specification  
**Created:** 2025-01-26  

## Problem Statement

FT-064 semantic activity detection is creating false positives by detecting **assistant responses about activities** as **actual user activities**, leading to data pollution and inaccurate activity tracking.

### **Evidence of False Positives:**
```json
// FALSE POSITIVE - Assistant discussing water intake
{"notes": "Assistant mentioned hydration", "timestamp": "23:07"}
{"notes": "Assistant confirmed user drank water 5 times", "timestamp": "23:22"}
{"notes": "Assistant mentioned 6 hydration moments", "timestamp": "23:56"}

// LIKELY REAL - User actually performing activity
{"notes": "Activity explicitly logged in system", "timestamp": "01:34"}
```

## Root Cause Analysis

### **Current FT-064 Detection Logic:**
1. Analyzes entire conversation for activity mentions
2. Does NOT distinguish between:
   - **User reporting activities** ✅ (should detect)
   - **Assistant discussing activities** ❌ (should ignore)
3. Creates feedback loop: discussing activities → logs more activities

### **Context Clues for False Positives:**
- Assistant responses containing activity summaries
- Data queries where assistant lists past activities
- Conversations about activity tracking itself

## Solution Approach

### **Strategy: Context-Aware Activity Detection**

**Core Principle:** Only detect activities from **user-initiated contexts**, not assistant responses or data discussions.

### **Implementation Phases:**

#### **Phase 1: Message Role Discrimination** (Immediate Fix)
Filter out activities detected from assistant messages:

```dart
// Only analyze USER messages for activity detection
if (message['role'] == 'user') {
  // Proceed with activity detection
} else {
  // Skip assistant messages to prevent false positives
}
```

#### **Phase 2: Contextual Analysis** (Enhanced Accuracy)
Improve semantic detection with context awareness:

```dart
// Enhanced prompt for activity detection
final contextualPrompt = '''
Analyze this USER message for ACTUAL activities they performed, not discussions about activities.

DETECT as activities:
- "I just drank water"
- "Finished my workout" 
- "Had lunch at noon"

DO NOT detect as activities:
- Asking about past activities
- Discussing activity tracking
- Questions about habits
- References to others' activities

USER MESSAGE: "$userMessage"
''';
```

#### **Phase 3: Confidence Scoring** (Advanced Filtering)
Implement confidence-based filtering:

```dart
// Only log activities with high confidence of being actual user actions
if (activity.confidenceScore > 0.95 && activity.isUserAction) {
  // Log activity
}
```

## Detailed Implementation

### **Target File:** `lib/services/activity_memory_service.dart`

### **Change 1: Message Role Filtering**
```dart
// In _performBackgroundActivityDetection()
Future<void> _performBackgroundActivityDetection(
    String userMessage, String assistantResponse) async {
  
  // FT-086: Only detect activities from user messages, not assistant responses
  final conversationForAnalysis = _conversationHistory
      .where((msg) => msg['role'] == 'user')  // Filter user messages only
      .map((msg) => msg['content'][0]['text'])
      .join('\n');
      
  // Proceed with activity detection...
}
```

### **Change 2: Enhanced Semantic Prompt**
```dart
final activityDetectionPrompt = '''
CRITICAL: Analyze this conversation for ACTUAL USER ACTIVITIES ONLY.

RULES:
1. ONLY detect activities the user explicitly states they DID/COMPLETED
2. IGNORE questions about activities ("what did I do?")
3. IGNORE discussions about activity tracking
4. IGNORE assistant summaries of past activities
5. IGNORE hypothetical or planned activities

DETECT Examples:
- "I just drank water" → SF1
- "Finished my run" → SF13  
- "Had breakfast" → SF2

DO NOT DETECT Examples:
- "What did I drink today?" → IGNORE
- "Show me my water intake" → IGNORE
- "How many times did I exercise?" → IGNORE

Conversation to analyze:
$conversationForAnalysis

Return only ACTUAL user activities with high confidence.
''';
```

### **Change 3: Confidence Threshold**
```dart
// Only log activities with very high confidence
const double ACTIVITY_CONFIDENCE_THRESHOLD = 0.95;

if (detectedActivity.confidenceScore >= ACTIVITY_CONFIDENCE_THRESHOLD && 
    detectedActivity.source == 'user_statement') {
  await _storeActivity(detectedActivity);
}
```

## Expected Impact

### **Before (Current State):**
```
User: "What did I drink today?"
Assistant: "You drank water 5 times: 01:33, 01:34, 15:45, 23:07, 23:14"
FT-064: Detects "drank water" → Logs NEW false activity at 23:22 ❌
```

### **After (Fixed):**
```
User: "What did I drink today?"
Assistant: "You drank water 5 times: 01:33, 01:34, 15:45, 23:07, 23:14"  
FT-086: Recognizes this is data query → No activity logged ✅
```

### **Real Activity Detection (Preserved):**
```
User: "Just had a glass of water"
FT-086: High confidence user action → Logs SF1 activity ✅
```

## Data Quality Improvements

### **Accuracy Metrics:**
- **False Positive Rate**: Target <5% (down from current ~50%)
- **True Positive Rate**: Maintain >90%
- **Data Cleanliness**: Eliminate feedback loop contamination

### **Activity Categories Most Affected:**
1. **SF1 (Beber água)**: High false positive rate from hydration discussions
2. **SF13 (Exercício)**: Assistant mentions of workouts
3. **SF2 (Alimentação)**: Food discussions vs actual eating

## Implementation Plan

### **Phase 1: Quick Fix (1 hour)**
1. Add message role filtering to skip assistant messages
2. Test with existing conversations
3. Immediate deployment to stop new false positives

### **Phase 2: Enhanced Detection (2 hours)**
1. Improve semantic prompts with context awareness
2. Add confidence scoring for user actions
3. Test accuracy improvements

### **Phase 3: Data Cleanup (1 hour)**
1. Identify existing false positives in database
2. Flag suspicious activities for review
3. Optional: Clean historical data

## Success Criteria

### **Functional Requirements:**
- [ ] Only detect activities from user messages
- [ ] Distinguish between activity reports and activity discussions
- [ ] Maintain high accuracy for real activity detection
- [ ] Eliminate assistant-induced false positives

### **Quality Metrics:**
- [ ] False positive rate <5%
- [ ] No degradation in true positive detection
- [ ] Clean activity timeline without discussion artifacts

## Risk Assessment

### **Implementation Risk:** ✅ LOW
- **Change scope**: Modify existing detection logic
- **Rollback**: Can revert to current behavior
- **Testing**: Easy to validate with conversation examples

### **Data Risk:** ✅ MINIMAL
- **Historical data**: Preserved unchanged
- **New detections**: Higher quality going forward
- **User experience**: Improved accuracy

## Alternative Approaches Considered

### **Option 1: Disable FT-064 Entirely**
- **Pro**: Eliminates false positives
- **Con**: Loses valuable automatic activity tracking
- **Verdict**: Too aggressive

### **Option 2: Manual Activity Logging Only**
- **Pro**: 100% accuracy
- **Con**: Poor user experience, low adoption
- **Verdict**: Not user-centric

### **Option 3: Context-Aware Detection (CHOSEN)**
- **Pro**: Maintains automation with improved accuracy
- **Con**: Requires refined semantic logic
- **Verdict**: Best balance of automation and accuracy

## Conclusion

FT-086 addresses the critical data quality issue in activity detection while preserving the valuable automatic tracking capability. The solution focuses on **context awareness** to distinguish between actual user activities and conversations about activities.

**Core Philosophy:** Smart automation that understands the difference between doing and discussing.
