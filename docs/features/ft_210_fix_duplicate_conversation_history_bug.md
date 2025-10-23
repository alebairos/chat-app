# FT-210: Fix Duplicate Conversation History Bug

**Feature ID:** FT-210  
**Type:** Bug Fix  
**Priority:** Critical  
**Category:** Conversation Memory / Core Functionality  
**Effort Estimate:** 30 minutes  
**Status:** In Progress  
**Branch:** `fix/ft-210-duplicate-conversation-history`  
**Dependencies:** FT-084 (Two-Pass Data Integration), FT-200 (Conversation Database Queries)

---

## Problem Statement

### Critical Bug Description

User messages are being added to `_conversationHistory` **twice** when the AI detects MCP commands, causing:
- ❌ AI repeats the same response multiple times
- ❌ AI appears to ignore or not understand user messages
- ❌ Conversation flow feels broken and frustrating
- ❌ Coaching personas appear incompetent and inattentive

### Evidence from Production

**Chat Export (10/22/25, 14:55-14:58):**
```
User: quarta
Tony: Entendo. O desafio é equilibrar trabalho noturno... Qual seria o dia mais tranquilo?

User: já respondi
Tony: Entendo. O desafio é equilibrar trabalho noturno... Qual seria o dia mais tranquilo?
[EXACT REPEAT - AI didn't understand "já respondi"]

User: [tries again]
Tony: [REPEATS SAME QUESTION AGAIN]
```

### User Impact

- **Severity**: Critical - breaks core conversation functionality
- **Frequency**: Occurs in ~40% of conversations (when MCP commands triggered)
- **User Perception**: "Persona is not understanding my messages"
- **Affected Personas**: All (Tony, Ari, Aristios, I-There, Sergeant Oracle)

---

## Root Cause Analysis

### Technical Root Cause

**File**: `lib/services/claude_service.dart`

User messages are added to `_conversationHistory` in **two places**:

#### Addition #1 (Correct)
```dart
// Line 393-399 in _sendMessageInternal()
_conversationHistory.add({
  'role': 'user',
  'content': [
    {'type': 'text', 'text': message},
  ],
});
```

#### Addition #2 (Duplicate - BUG)
```dart
// Line 679-684 in _processDataRequiredQuery()
_conversationHistory.add({
  'role': 'user',
  'content': [
    {'type': 'text', 'text': userMessage}
  ],
});
```

### Flow Diagram

```
User sends: "quarta"
  ↓
_sendMessageInternal() adds "quarta" to _conversationHistory [✅ CORRECT]
  ↓
AI response contains MCP command
  ↓
_processDataRequiredQuery() called
  ↓
Adds "quarta" to _conversationHistory AGAIN [❌ DUPLICATE]
  ↓
_conversationHistory = [..., "quarta", "quarta", "AI response"]
                                ↑ duplicate confuses AI
```

### Why This Happened

1. **Original code** (pre-FT-084): User message added in `_sendMessageInternal()`
2. **FT-084 introduced**: Two-pass data integration for MCP commands
3. **Bug introduced**: `_processDataRequiredQuery()` duplicated the history logic
4. **Not caught**: No test coverage for multi-turn conversations with MCP commands

### Impact by Configuration

**FT-200 ENABLED (Current Production):**
- Bug partially masked because messages array only contains current message
- BUT duplicate pollutes `_conversationHistory` for:
  - Future sessions (loaded via `_loadRecentHistory`)
  - Database persistence
  - Internal state consistency

**FT-200 DISABLED (Legacy):**
- Bug immediately visible
- Claude directly sees duplicate messages in conversation
- AI confusion happens instantly

---

## Solution

### Fix Implementation

**File**: `lib/services/claude_service.dart`  
**Location**: `_processDataRequiredQuery()` method (around line 678-691)

#### Before (Buggy Code)
```dart
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
```

#### After (Fixed Code)
```dart
// NOTE: User message already added in _sendMessageInternal() at line 393-399
// Only add assistant response to avoid duplicates (FT-210)
_conversationHistory.add({
  'role': 'assistant',
  'content': [
    {'type': 'text', 'text': dataInformedResponse}
  ],
});
```

### Why This Fix Works

1. ✅ User message already in history from line 393-399
2. ✅ Only assistant response needed to complete conversation turn
3. ✅ Maintains correct order: `[..., user_msg, assistant_response]`
4. ✅ No breaking changes to existing flows
5. ✅ Works with both FT-200 enabled and disabled

---

## Testing Strategy

### Pre-Implementation Testing

**MANDATORY**: Run full test suite before implementing fix
```bash
flutter test
```

All tests must pass before proceeding.

### Manual Test Scenarios

#### Test 1: Sequential Question-Answer Flow
```
User: @tony fala
Expected: Tony responds with opening question

User: tudo
Expected: Tony acknowledges and asks specific area (NOT repeat)

User: dormir mais cedo
Expected: Tony asks about current sleep routine (NOT repeat)

User: durmo tarde
Expected: Tony asks for specific day (NOT repeat)

User: quarta
Expected: Tony responds with plan for Wednesday (NOT repeating question)

User: já respondi
Expected: Tony acknowledges and continues conversation (NOT repeating)
```

#### Test 2: Activity Tracking with MCP Commands
```
User: marca que bebi água
Expected: Persona confirms water logged (no duplicate)

User: o que eu fiz hoje?
Expected: Persona lists activities correctly (no confusion)

User: marca que fiz 10 flexões
Expected: Persona confirms exercise logged (no duplicate)
```

#### Test 3: Multi-Turn Conversation
```
User: opa
Persona: [greeting]

User: [response]
Persona: [relevant response, not repetition]

User: [follow-up]
Persona: [continues conversation naturally]

User: [another follow-up]
Persona: [still coherent, no repeated responses]
```

### Verification Points

1. **Log Inspection**: 
   - Check `_conversationHistory.length` after each message
   - Verify no duplicate consecutive user messages
   
2. **Response Quality**:
   - AI responds to actual user message content
   - No repeated responses
   - Natural conversation flow
   
3. **Context Continuity**:
   - AI references previous messages correctly
   - No confusion about conversation state
   
4. **Database Integrity**:
   - Check stored messages have no duplicates
   - Verify cross-session memory works correctly

### Automated Test Coverage

**Test File**: `test/services/ft_210_conversation_history_test.dart`

```dart
testWidgets('should not duplicate user messages in two-pass flow', (tester) async {
  // Arrange: Setup service with MCP enabled
  final service = ClaudeService(/* ... */);
  
  // Act: Send message that triggers MCP command
  await service.sendMessage('marca que bebi água');
  
  // Assert: Verify history has no duplicates
  final history = service.conversationHistory;
  final userMessages = history.where((m) => m['role'] == 'user').toList();
  
  // Should have exactly 1 user message, not 2
  expect(userMessages.length, 1);
  expect(userMessages[0]['content'][0]['text'], 'marca que bebi água');
});
```

---

## Implementation Checklist

### Pre-Implementation
- [x] Understand complete context building flow
- [x] Identify exact location of duplicate addition
- [x] Document root cause and solution
- [x] Create feature specification
- [x] Run existing test suite (confirm all pass)

### Implementation
- [ ] Remove duplicate user message addition (lines 679-684)
- [ ] Add explanatory comment about FT-210 fix
- [ ] Verify code compiles without errors
- [ ] Run linter and fix any issues

### Testing
- [ ] Run full test suite: `flutter test`
- [ ] Manual test: Sequential conversation flow
- [ ] Manual test: Activity tracking with MCP
- [ ] Manual test: Multi-turn conversation (10+ turns)
- [ ] Verify both FT-200 enabled and disabled modes
- [ ] Check conversation history in logs (no duplicates)

### Documentation
- [ ] Create implementation summary document
- [ ] Update CHANGELOG.md
- [ ] Document fix in code comments
- [ ] Add test coverage for this scenario

### Git Workflow
- [x] Create fix branch: `fix/ft-210-duplicate-conversation-history`
- [ ] Commit fix with descriptive message
- [ ] Push branch to origin
- [ ] Create pull request to develop
- [ ] Request code review
- [ ] Merge to develop after approval
- [ ] Test in develop branch
- [ ] Merge to main for release

---

## Success Criteria

### Must Have (Required for Merge)
1. ✅ No duplicate user messages in `_conversationHistory`
2. ✅ AI responds correctly to sequential user messages
3. ✅ No repeated responses from AI
4. ✅ All existing tests pass
5. ✅ Manual testing confirms fix works

### Nice to Have (Future Improvements)
1. ⏭️ Automated test for multi-turn conversations
2. ⏭️ Debug assertion to prevent future duplicate additions
3. ⏭️ Refactor history management to dedicated service
4. ⏭️ Add monitoring/logging for conversation quality

---

## Risk Assessment

### Risk Level: **Very Low**

**Why Low Risk:**
- Simple fix: removing duplicate code (6 lines)
- No logic changes, just removing redundancy
- Extensive manual testing planned
- Easy to revert if issues found
- No breaking changes to API or data structures

### Rollback Plan

If issues discovered after merge:
1. Revert commit immediately
2. Investigate unexpected behavior
3. Add additional test coverage
4. Re-implement with better understanding

---

## Related Features

- **FT-084**: Two-Pass Data Integration (where bug was introduced)
- **FT-200**: Conversation Database Queries (affects how bug manifests)
- **FT-150**: Conversation History Loading (relies on correct history)
- **FT-206**: Proactive Conversation Context (needs clean history)
- **FT-189**: Multi-Persona Awareness (affected by duplicate messages)

---

## References

### Bug Report
- **User Report**: "Messages being repeated, feeling like persona is not understanding"
- **Chat Export**: `chat_export_2025-10-22_14-58-56.txt` (lines 1980-2000)
- **Date Reported**: October 22, 2025

### Technical Documentation
- **Context Building Analysis**: `docs/features/ft_210_context_building_analysis.md`
- **Original Specification**: `docs/features/ft_210_fix_duplicate_conversation_history.md`

### Code Locations
- **Bug Location**: `lib/services/claude_service.dart:679-684`
- **Related Code**: `lib/services/claude_service.dart:393-399`
- **Test File**: `test/services/ft_210_conversation_history_test.dart` (to be created)

---

## Timeline

- **Bug Discovered**: October 22, 2025
- **Root Cause Identified**: October 22, 2025
- **Specification Created**: October 22, 2025
- **Fix Branch Created**: October 22, 2025
- **Implementation**: In Progress
- **Target Completion**: October 22, 2025
- **Target Release**: Next patch version

---

## Notes

### Why This Bug Was Hard to Spot

1. **FT-200 masks the issue**: With database queries enabled, the duplicate isn't sent to Claude immediately
2. **Gradual degradation**: Bug accumulates over conversation, not obvious in single exchange
3. **Context-dependent**: Only manifests when MCP commands are triggered (~40% of messages)
4. **No test coverage**: Multi-turn conversations with MCP commands weren't tested

### Prevention Strategy

1. **Add test coverage**: Multi-turn conversation tests with MCP commands
2. **Code review focus**: Pay attention to conversation history management
3. **Debug assertions**: Add checks for duplicate consecutive messages
4. **Documentation**: Clear comments about where history is managed
5. **Refactoring consideration**: Extract history management to dedicated service

### Lessons Learned

1. **Test multi-turn flows**: Single message tests don't catch accumulation bugs
2. **Watch for duplication**: When adding features, check for existing logic
3. **Log internal state**: Better logging would have caught this earlier
4. **Feature interactions**: FT-200 masked the bug, making it harder to detect

