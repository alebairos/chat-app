# FT-210: Fix Duplicate Conversation History Bug

**Feature ID:** FT-210  
**Priority:** Critical  
**Category:** Bug Fix / Conversation Memory  
**Effort Estimate:** 30 minutes  
**Status:** Specification  
**Dependencies:** FT-084 (Two-Pass Data Integration), FT-200 (Conversation Database Queries)

## Problem Statement

**Critical Bug**: User messages are being added to `_conversationHistory` twice, causing AI to repeat responses and lose context understanding.

### Current Broken Behavior

**Chat Export Evidence (10/22/25, 14:55-14:58):**
```
User: tudo
Tony: Bom dia! Qual área da sua vida você gostaria de melhorar primeiro?

User: nessa vc pegou na curva
Tony: E aí! Qual área da sua vida você quer melhorar primeiro? [slight variation but ignoring user]

User: ok. dormir mais cedo
Tony: Como você está lidando com o sono atualmente? [good response]

User: durmo tarde, por causa do trabalho. preciso acordar cedo...
Tony: Entendo. O desafio é equilibrar trabalho noturno... Qual seria o dia mais tranquilo?

User: quarta
Tony: Entendo. O desafio é equilibrar trabalho noturno... Qual seria o dia mais tranquilo? [EXACT REPEAT]

User: já respondi
Tony: Entendo. O desafio é equilibrar trabalho noturno... Qual seria o dia mais tranquilo? [EXACT REPEAT AGAIN]
```

### Root Cause Analysis

**File**: `lib/services/claude_service.dart`

**Duplicate Addition Points:**
1. **Line 393-399** in `_sendMessageInternal()`:
```dart
// Add user message to history using content blocks format
_conversationHistory.add({
  'role': 'user',
  'content': [
    {'type': 'text', 'text': message},
  ],
});
```

2. **Line 679-684** in `_processDataRequiredQuery()`:
```dart
// Add to conversation history
_conversationHistory.add({
  'role': 'user',
  'content': [
    {'type': 'text', 'text': userMessage}
  ],
});
```

**Flow Diagram:**
```
User sends: "quarta"
  ↓
_sendMessageInternal() adds "quarta" to _conversationHistory [FIRST TIME]
  ↓
AI detects MCP command needed
  ↓
_processDataRequiredQuery() called
  ↓
Adds "quarta" to _conversationHistory AGAIN [DUPLICATE]
  ↓
_conversationHistory now has:
  [...previous messages, "quarta", "quarta"]
  ↓
AI sees duplicate and gets confused, repeats previous response
```

### Impact

**User Experience:**
- ❌ AI appears to not understand or ignore user responses
- ❌ AI repeats the same question multiple times
- ❌ Conversation feels broken and frustrating
- ❌ Coaching personas (Tony, Ari, Aristios) appear incompetent

**Technical Impact:**
- Conversation history grows incorrectly
- Context window pollution with duplicate messages
- Potential token waste (minor but accumulates)

## Business Value

### User Experience Benefits
- ✅ AI responds appropriately to user messages
- ✅ No more repeated questions
- ✅ Natural conversation flow restored
- ✅ Coaching personas appear intelligent and attentive

### Technical Benefits
- ✅ Correct conversation history management
- ✅ Reduced token usage (no duplicate messages)
- ✅ Proper context for AI responses
- ✅ Foundation for reliable multi-turn conversations

## Functional Requirements

### FR-1: Single User Message Addition
**As the ClaudeService, I should add each user message to conversation history exactly once.**

#### Acceptance Criteria:
- ✅ User message added to `_conversationHistory` only in `_sendMessageInternal()`
- ✅ `_processDataRequiredQuery()` does NOT add user message again
- ✅ Assistant response added to history after final response generation
- ✅ No duplicate messages in `_conversationHistory` at any point

### FR-2: Correct Two-Pass History Management
**As the two-pass data integration flow, I should maintain correct conversation history.**

#### Acceptance Criteria:
- ✅ First pass: User message already in history (from `_sendMessageInternal`)
- ✅ Second pass: Only add assistant response to history
- ✅ History order: [...previous, user_msg, assistant_response]
- ✅ No intermediate history additions during data fetching

## Technical Implementation

### Solution: Remove Duplicate Addition

**File**: `lib/services/claude_service.dart`

**Change in `_processDataRequiredQuery()` (around line 678-691):**

```dart
// BEFORE (BUGGY):
// Add to conversation history
_conversationHistory.add({
  'role': 'user',
  'content': [
    {'type': 'text', 'text': userMessage}
  ],
});

_conversationHistory.add({
  'role': 'assistant',
  'content': [
    {'type': 'text', 'text': dataInformedResponse}
  ],
});

// AFTER (FIXED):
// User message already added in _sendMessageInternal() - only add assistant response
_conversationHistory.add({
  'role': 'assistant',
  'content': [
    {'type': 'text', 'text': dataInformedResponse}
  ],
});
```

### Code Comment to Add

```dart
// NOTE: User message already added to _conversationHistory in _sendMessageInternal()
// at line 393-399. We only add the assistant response here to avoid duplicates.
// See FT-210 for bug fix details.
```

## Non-Functional Requirements

### NFR-1: Backward Compatibility
- No breaking changes to existing conversation flows
- Works with FT-200 (Conversation Database Queries)
- Compatible with FT-084 (Two-Pass Data Integration)

### NFR-2: Testing
- Verify no duplicate messages in conversation history
- Test both regular and two-pass flows
- Confirm AI responds correctly to sequential messages

## Testing Strategy

### Manual Testing Scenarios

**Test 1: Sequential Question-Answer Flow**
```
User: @tony fala
Expected: Tony responds with opening question

User: tudo
Expected: Tony acknowledges and asks specific area

User: dormir mais cedo
Expected: Tony asks about current sleep routine

User: durmo tarde
Expected: Tony asks for specific day

User: quarta
Expected: Tony responds with plan for Wednesday (NOT repeating question)
```

**Test 2: Activity Tracking Flow (MCP Commands)**
```
User: marca que bebi água
Expected: Persona confirms water logged (no duplicate)

User: o que eu fiz hoje?
Expected: Persona lists activities correctly (no confusion)
```

**Test 3: Multi-Turn Conversation**
```
User: opa
Persona: [greeting]

User: [response]
Persona: [relevant response, not repetition]

User: [follow-up]
Persona: [continues conversation naturally]
```

### Verification Points

1. **Log Inspection**: Check `_conversationHistory` length after each message
2. **Response Quality**: AI should respond to actual user message, not repeat
3. **Context Continuity**: AI should reference previous messages correctly
4. **No Regressions**: Existing features (FT-084, FT-200) still work

## Success Criteria

### Must Have
1. ✅ No duplicate user messages in `_conversationHistory`
2. ✅ AI responds correctly to sequential user messages
3. ✅ No repeated responses from AI
4. ✅ All existing tests pass

### Nice to Have
1. ✅ Debug logging to track history additions
2. ✅ Assertion to prevent future duplicate additions

## Implementation Notes

### Why This Bug Happened
- FT-084 introduced two-pass processing for MCP commands
- Original code in `_sendMessageInternal()` added user message to history
- `_processDataRequiredQuery()` was added later and duplicated this logic
- No test caught this because it only manifests in multi-turn conversations

### Prevention Strategy
- Add comment explaining history management flow
- Consider extracting history management to dedicated method
- Add debug assertion to detect duplicate consecutive messages

## Related Features

- **FT-084**: Two-Pass Data Integration (where bug was introduced)
- **FT-200**: Conversation Database Queries (affected by this bug)
- **FT-150**: Conversation History Loading (relies on correct history)
- **FT-206**: Proactive Conversation Context (needs correct history)

## References

- Chat export: `chat_export_2025-10-22_14-58-56.txt` (lines 1980-2000)
- Bug report: User reported "Messages being repeated, feeling like persona is not understanding"

