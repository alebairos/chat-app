# FT-104: JSON Command TTS Leak Fix

**Status**: ✅ IMPLEMENTED  
**Priority**: Critical  
**Category**: Bug Fix / TTS Contamination  
**Effort**: 10 minutes  

## Problem Statement

**JSON commands bleeding into TTS audio**: Despite FT-103 fixes, MCP commands are still being spoken in audio responses.

**Evidence**: 
```
User: "acabo de beber agua e pagar 10 flexões"
TTS Output: "Máquina absoluta! Sua oitava e nona atividades hoje. {"action": "get_activity_stats"}"
```

## Root Cause Analysis

**The issue is in regular conversation flow** (non-two-pass), where:
1. Claude generates response with embedded JSON command
2. Response goes directly to TTS without cleaning
3. JSON command gets spoken

**Key Finding**: The `_cleanResponseForUser()` function is only used in two-pass processing, not regular conversation flow.

## Surgical Solution

**Enhance existing `_cleanResponseForUser()` to remove ALL JSON patterns and apply it to ALL responses before TTS.**

### Implementation

**Location**: `lib/services/claude_service.dart`

**Step 1**: Enhance cleaning function to catch JSON commands
```dart
String _cleanResponseForUser(String rawResponse) {
  String cleaned = rawResponse;
  
  // Remove internal assessment sections
  final assessmentPattern = RegExp(r'---INTERNAL_ASSESSMENT---.*?---END_INTERNAL_ASSESSMENT---', multiLine: true, dotAll: true);
  cleaned = cleaned.replaceAll(assessmentPattern, '');
  
  // Remove standalone JSON commands (FT-104)
  final jsonPattern = RegExp(r'\{"action":\s*"[^"]+"\}');
  cleaned = cleaned.replaceAll(jsonPattern, '');
  
  // Remove any remaining JSON-like patterns
  final jsonPatternExtended = RegExp(r'\{[^{}]*"action"[^{}]*\}');
  cleaned = cleaned.replaceAll(jsonPatternExtended, '');
  
  // Clean up whitespace
  cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
  cleaned = cleaned.trim();
  
  return cleaned;
}
```

**Step 2**: Apply cleaning to regular conversation flow
```dart
// In regular conversation flow (around line 240)
// BEFORE TTS processing
final cleanedResponse = _cleanResponseForUser(assistantMessage);

// Use cleanedResponse for TTS, keep original for history
```

## Expected Results

- **JSON commands removed** from all TTS audio
- **Two-pass responses**: Already cleaned (no change)
- **Regular responses**: Now cleaned before TTS
- **Zero impact** on functionality - only affects user-facing text

## Implementation Summary

**Date Implemented**: August 25, 2025  
**Lines Modified**: `lib/services/claude_service.dart` lines 237-252, 875-881  
**Change Type**: Enhanced response cleaning with JSON command removal  

### What Was Implemented

**1. Enhanced JSON Command Cleaning**
- Added regex patterns to detect and remove `{"action": "command"}` patterns
- Comprehensive JSON pattern matching for edge cases
- Applied to existing `_cleanResponseForUser()` function

**2. Applied to Regular Conversation Flow**
- Modified regular conversation flow to clean responses before TTS
- Preserved original response for background activity detection
- Zero impact on two-pass processing (already using cleaning)

### Regex Patterns Added
```dart
// Basic JSON command pattern
RegExp(r'\{"action":\s*"[^"]+"\}')

// Extended JSON pattern with any content
RegExp(r'\{[^{}]*"action"[^{}]*\}')
```

### Expected Behavior After Fix
- **Regular responses**: JSON commands stripped before TTS
- **Two-pass responses**: Already cleaned (no change)
- **Activity detection**: Uses original response (preserves functionality)
- **TTS audio**: Clean, natural speech without technical commands

**Dependencies**: Existing `_cleanResponseForUser()` function  
**Breaking Changes**: None  
**Rollback Strategy**: Remove JSON pattern cleaning from function
