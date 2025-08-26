# FT-100: Basic Temporal Query MCP Fix

**Status**: ✅ IMPLEMENTED  
**Priority**: High  
**Category**: Bug Fix / Query Triggering  
**Effort**: 5 minutes  

## Problem Statement

Basic temporal queries show inconsistent MCP command generation:

| **Query Type** | **Example** | **MCP Triggered** | **Result** |
|----------------|-------------|-------------------|------------|
| Time | "que horas são?" | ✅ `{"action": "get_current_time"}` | Correct current time |
| Date/Day | "que dia é hoje?" | ❌ No MCP command | Wrong date from training data |

**Observed Failure**: User asks "que dia é hoje?" → AI responds "Segunda-feira, 11 de março de 2024" (incorrect training data) instead of using MCP to get current date "segunda-feira, 25 de agosto de 2025".

## Root Cause Analysis

**Function Description Mismatch**: The `get_current_time` function description is time-centric, causing Claude to miss date/day queries:

```dart
// CURRENT (unclear for date queries)
'- get_current_time: Returns current date, time, and temporal information\n'
```

**Semantic Mapping Issue**:
- "que horas são?" → "time" → ✅ Maps to `get_current_time`
- "que dia é hoje?" → "day/date" → ❌ Doesn't clearly map to `get_current_time`

## Minimal Fix Strategy

**Enhance function description** to explicitly cover all temporal query types, making it clear that `get_current_time` handles ANY temporal question.

## Implementation

**Location**: `lib/services/claude_service.dart`  
**Method**: `_buildSystemPrompt()` - Line ~472  
**Change**: Enhanced function description with explicit temporal query examples

```dart
// BEFORE (time-focused)
'- get_current_time: Returns current date, time, and temporal information\n'

// AFTER (comprehensive temporal with examples table)
'- get_current_time: Returns ALL temporal information (date, day, time, day of week)\n'
'  ALWAYS use for temporal queries:\n'
'  • "que horas são?" / "what time?" → get_current_time\n'
'  • "que dia é hoje?" / "what day?" → get_current_time\n'
'  • "que data é hoje?" / "what date?" → get_current_time\n'
'  • "que dia da semana?" / "day of week?" → get_current_time\n'
'  Returns: timestamp, hour, minute, dayOfWeek, readableTime (PT-BR formatted)\n'
```

## Expected Outcome

**All temporal queries trigger MCP commands**:
- "que horas são?" → `{"action": "get_current_time"}` ✅ (already working)
- "que dia é hoje?" → `{"action": "get_current_time"}` ✅ (will be fixed)
- "que data é hoje?" → `{"action": "get_current_time"}` ✅ (will be fixed)
- "que dia da semana é?" → `{"action": "get_current_time"}` ✅ (will be fixed)

**Result**: Consistent, accurate temporal responses using real-time data instead of outdated training data.

## Success Criteria

- [ ] "que dia é hoje?" generates MCP command instead of direct response
- [ ] All temporal queries use current system time (2025) not training data (2024)
- [ ] No regression in existing time query functionality
- [ ] Consistent two-pass processing for all temporal questions

---

## Implementation Summary

**Date Implemented**: August 25, 2025  
**Lines Modified**: `lib/services/claude_service.dart` line 472-478  
**Change Type**: Enhanced function description in system prompt  

### What Was Changed
- Replaced generic `get_current_time` description with explicit temporal query examples
- Added bilingual examples (Portuguese/English) for common temporal questions
- Clarified that ALL temporal queries should use this single function
- Added return value context to help with response generation

### Expected Behavior After Fix
- "que dia é hoje?" → Generates `{"action": "get_current_time"}` → Uses real current date
- "que horas são?" → Continues working as before (already correct)
- "que data é hoje?" → Generates MCP command instead of training data response
- "que dia da semana é?" → Uses real-time day of week information

---

**Dependencies**: None  
**Breaking Changes**: None  
**Rollback Strategy**: Simple revert of function description change
