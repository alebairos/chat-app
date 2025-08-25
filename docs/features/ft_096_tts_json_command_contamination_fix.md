# FT-096: TTS JSON Command Contamination Fix

**Status**: ✅ IMPLEMENTED  
**Priority**: High  
**Category**: Audio UX / Bug Fix  
**Effort**: 1 hour  

## Problem Statement

ElevenLabs TTS is speaking raw JSON MCP commands in audio responses, creating poor user experience with phrases like `{action: getactivitystats, days: um}` being vocalized.

### Root Cause Analysis

**Regex Pattern Mismatch** between MCP command detection functions:

```dart
// _containsMCPCommand() - BROKEN
RegExp(r'\{"action":\s*"[^"]+"\}')  // Only matches simple JSON

// _extractMCPCommands() - CORRECT  
RegExp(r'\{"action":\s*"[^"]+"[^}]*\}')  // Matches JSON with parameters
```

### Specific Failure Case

**Query**: "ontem" (yesterday)  
**Response**: `Deixa eu verificar... {"action": "get_activity_stats", "days": 1}`

1. `_containsMCPCommand()` returns `false` (doesn't match `"days": 1` part)
2. Single-pass processing triggered (bypasses JSON cleaning)  
3. Raw JSON sent to TTS: `{action: getactivitystats, days: um}`

## Solution Strategy

**Align regex patterns** to ensure consistent MCP command detection for all JSON structures.

### Technical Implementation

**File**: `lib/services/claude_service.dart`  
**Method**: `_containsMCPCommand()` (line 318)  
**Change**: Single character addition to regex pattern

```dart
// BEFORE (broken)
final mcpPattern = RegExp(r'\{"action":\s*"[^"]+"\}');

// AFTER (fixed)  
final mcpPattern = RegExp(r'\{"action":\s*"[^"]+"[^}]*\}');
```

### Expected Behavior

**Before Fix:**
- Simple JSON: `{"action": "get_activity_stats"}` → Two-pass ✅
- Parametized JSON: `{"action": "get_activity_stats", "days": 1}` → Single-pass ❌

**After Fix:**
- All MCP commands trigger two-pass processing ✅
- JSON commands cleaned before TTS ✅
- No more audio contamination ✅

## Functional Requirements

### Primary
- [ ] MCP commands with parameters trigger two-pass processing
- [ ] JSON commands removed from TTS text before audio generation
- [ ] Consistent detection for all MCP command formats

### Non-Functional
- [ ] Zero impact on response time or accuracy
- [ ] Maintains existing two-pass architecture
- [ ] No regression in temporal intelligence functionality

## Implementation Notes

### Architecture Benefits
- **Surgical fix**: Single regex character change
- **Universal solution**: Fixes issue for all parametized MCP commands
- **Zero side effects**: Maintains all existing functionality

### Edge Cases Covered
- `{"action": "get_activity_stats", "days": 1}` ✅
- `{"action": "get_message_stats", "limit": 10}` ✅  
- `{"action": "get_current_time"}` ✅ (still works)

## Testing Strategy

### Verification Tests
1. **"ontem" query** - Should trigger two-pass, clean TTS audio
2. **"hoje" query** - Should maintain existing behavior  
3. **Complex queries** - Should handle all MCP commands consistently

### Success Criteria
- No JSON commands audible in TTS responses
- All temporal queries use appropriate processing path
- Maintained accuracy of temporal intelligence features

---

**Dependencies**: None  
**Breaking Changes**: None  
**Rollback Strategy**: Revert single regex change if issues arise
