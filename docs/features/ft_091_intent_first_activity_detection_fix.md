# FT-091: Intent-First Activity Detection Fix

## **Overview**
Fix false positive activity detection by adding intent classification to the semantic analyzer prompt. Eliminate detection of activities mentioned in questions or discussions rather than completion reports.

## **Problem Statement**

### **Current Issue**
The semantic activity detector incorrectly logs activities when users ask questions or make references:

**Example False Positive**:
- **User Query**: "o que eu fiz ontem? além de beber água?"
- **Current Behavior**: Detects and logs "beber água" as new activity ❌
- **Expected Behavior**: Recognizes question, no activity logging ✅

### **Root Cause**
The current prompt focuses on keyword matching without understanding user intent:
- Detects "beber água" regardless of context
- Misses the distinction between reporting vs. asking
- No differentiation between completion statements and references

### **Impact**
- **False positives**: Questions create spurious activity entries
- **Data pollution**: Database fills with incorrect activities
- **User confusion**: Stats show activities that weren't actually completed
- **Trust erosion**: Users lose confidence in tracking accuracy

## **Solution Strategy**

### **Core Principle**
Trust the LLM's natural language understanding by adding intent classification before activity detection.

### **Approach: Intent-First Analysis**
1. **Intent Classification**: Determine if user is reporting or asking
2. **Conditional Detection**: Only detect activities for completion reports
3. **Minimal Change**: Enhance existing prompt without architectural changes

### **Philosophy**
- **Trust the model**: Use Claude's semantic comprehension
- **No hardcoded rules**: Avoid rigid keyword matching
- **Intent-driven**: Focus on what the user is trying to do

## **Current Implementation Analysis**

### **Existing Prompt Structure**
```dart
## Task
Detect COMPLETED activities (past tense only) mentioned by the USER ONLY.

## Rules
- ONLY past completions: "fiz", "acabei", "terminei", "did", "finished", "completed"
- IGNORE future plans: "vou", "pretendo", "will", "planning", "want to"
- IGNORE preferences: "gosto de", "amo", "love", "like"
- FT-086: IGNORE ALL QUESTIONS: Any message with "?" or question words...
```

### **Problem with Current Approach**
- **Rule-heavy**: Fights against LLM's natural understanding
- **Keyword-based**: Misses semantic context
- **Reactive**: Tries to exclude rather than understand intent

## **Proposed Solution**

### **Enhanced Prompt with Intent Classification**

#### **New Prompt Structure**
```dart
# SEMANTIC ACTIVITY DETECTION

## Oracle Activities Available
${_formatOracleActivities(oracleContext)}

## User Message Analysis
**Time Context**: ${timeContext['readableTime'] ?? 'Unknown'}
**User Message**: "$userMessage"

## Step 1: Intent Classification (CRITICAL)
First determine the user's primary intent:

**REPORTING**: User is telling you about activities they completed
- Examples: "acabei de beber água", "fiz exercício", "terminei o pomodoro"
- Action: Proceed to activity detection

**ASKING**: User is requesting information about past activities  
- Examples: "o que fiz?", "além de beber água?", "what did I do yesterday?"
- Action: Return empty list, no detection

**DISCUSSING**: User is talking about activities in general context
- Examples: "gosto de beber água", "quero fazer exercício", "planning to work out"
- Action: Return empty list, no detection

## Step 2: Activity Detection
ONLY if intent is REPORTING, detect completed activities.
If intent is ASKING or DISCUSSING, return {"detected_activities": []}

## Detection Rules (Only for REPORTING intent)
- Focus on past completions with high confidence
- Match semantically to Oracle activities
- Extract duration when mentioned
- Provide reasoning for each detection

## Output Format
{"detected_activities": [...]} or {"detected_activities": []} for non-reporting intents
```

## **Implementation Plan**

### **File to Modify**
- **Primary**: `lib/services/semantic_activity_detector.dart`
- **Method**: `_buildDetectionPrompt()`
- **Change Type**: Prompt enhancement (no signature changes)

### **Specific Changes**

#### **1. Replace Existing Rules Section**
**Before**:
```dart
## Rules
- ONLY past completions: "fiz", "acabei", "terminei"...
- IGNORE future plans: "vou", "pretendo"...
- FT-086: IGNORE ALL QUESTIONS: Any message with "?"...
```

**After**:
```dart
## Step 1: Intent Classification (CRITICAL)
First determine the user's primary intent:
- REPORTING: User telling you about completed activities → Detect
- ASKING: User requesting information about activities → Empty list  
- DISCUSSING: User talking about activities generally → Empty list

## Step 2: Activity Detection (Only for REPORTING)
```

#### **2. Add Intent Examples**
Provide clear examples of each intent type to guide the LLM's understanding.

#### **3. Conditional Detection Logic**
Make activity detection conditional on intent classification result.

## **Expected Results**

### **False Positive Fixes**
| User Input | Current Result | Expected Result |
|------------|----------------|-----------------|
| "o que fiz ontem? além de beber água?" | Detects SF1 ❌ | Empty list ✅ |
| "what did I do yesterday?" | Detects activities ❌ | Empty list ✅ |
| "além do exercício, que mais fiz?" | Detects exercise ❌ | Empty list ✅ |

### **Maintained Accuracy**
| User Input | Expected Result | Status |
|------------|-----------------|---------|
| "acabei de beber água" | Detects SF1 | ✅ Preserved |
| "fiz um pomodoro agora" | Detects T8 | ✅ Preserved |
| "terminei o exercício" | Detects exercise | ✅ Preserved |

### **Intent Classification Examples**
- **REPORTING**: "acabei de malhar" → Detect activities
- **ASKING**: "o que fiz hoje?" → No detection
- **DISCUSSING**: "gosto de correr" → No detection

## **Testing Strategy**

### **Test Cases**

#### **Test 1: Question Recognition**
```
Input: "o que eu fiz ontem? além de beber água?"
Expected Intent: ASKING
Expected Activities: []
Validation: No false positive SF1 detection
```

#### **Test 2: Completion Recognition**
```
Input: "acabei de beber água e fazer exercício"
Expected Intent: REPORTING  
Expected Activities: [SF1, Exercise]
Validation: Correct activity detection maintained
```

#### **Test 3: Discussion Recognition**
```
Input: "quero beber mais água amanhã"
Expected Intent: DISCUSSING (future planning)
Expected Activities: []
Validation: No future intent detection
```

#### **Test 4: Reference vs Report**
```
Input: "além do pomodoro, também bebi água"
Expected Intent: REPORTING (adding to previous)
Expected Activities: [SF1] (water as new completion)
Validation: Contextual understanding
```

### **Validation Criteria**
- ✅ False positive elimination for questions
- ✅ Maintained accuracy for actual completions
- ✅ Proper intent classification across scenarios
- ✅ No performance degradation

## **Risk Assessment**

### **Low Risk Implementation**
- **Minimal change**: Only prompt modification
- **No architecture impact**: Same interfaces
- **Reversible**: Easy to rollback if issues
- **Testable**: Immediate validation possible

### **Potential Issues**
- **Intent misclassification**: LLM might occasionally misunderstand
- **Borderline cases**: Some ambiguous messages might be unclear
- **Cultural nuances**: Portuguese expressions might need refinement

### **Mitigation Strategies**
- **Clear examples**: Provide diverse intent examples in prompt
- **Iterative refinement**: Adjust based on real usage patterns
- **Fallback behavior**: Default to no detection when uncertain

## **Success Metrics**

### **Primary Goals**
- **False positive reduction**: Eliminate question-based detections
- **Accuracy maintenance**: Keep valid completion detection rate
- **User trust**: Improve perceived system reliability

### **Measurable Outcomes**
- **Before**: Questions cause spurious activity logs
- **After**: Questions properly recognized, no false logging
- **Validation**: Database entries align with actual user completions

## **Implementation Steps**

### **Phase 1: Prompt Enhancement** (5 minutes)
1. Modify `_buildDetectionPrompt()` in `semantic_activity_detector.dart`
2. Add intent classification section
3. Make detection conditional on intent

### **Phase 2: Testing** (10 minutes)
1. Test problematic case: "o que fiz ontem? além de beber água?"
2. Verify no activity detection occurs
3. Test positive case: "acabei de beber água"
4. Verify activity detection still works

### **Phase 3: Validation** (5 minutes)
1. Run existing tests to ensure no regressions
2. Monitor logs for intent classification behavior
3. Confirm false positive elimination

**Total Implementation Time: ~20 minutes**

## **Future Enhancements**

### **Potential Improvements**
- **Conversation context**: Add last 5 messages for better understanding
- **Intent confidence**: Include confidence scoring for intent classification
- **Learning feedback**: Use misclassifications to improve prompts

### **Extensibility**
This intent-first approach provides foundation for:
- More sophisticated context analysis
- Multi-turn conversation understanding
- Enhanced semantic comprehension

## **Priority**: **High**
Critical fix for user trust and data accuracy.

## **Effort**: **Low** 
Simple prompt modification with immediate impact.

## **Category**: **Bug Fix / Enhancement**

## **Dependencies**: None

This fix addresses the core false positive issue while maintaining the trust-the-LLM philosophy and providing a foundation for future enhancements.
