# FT-098: JSON Malformation Auto-Correction Fix

## Problem
Enhanced temporal prompting (FT-095/FT-097) introduced JSON malformation bug:
- Claude generates: `{"action": "get_activity_stats", "days": 2"}`
- Extra quote causes `FormatException` during MCP execution
- Two-pass processing fails, TTS contamination returns

## Root Cause
- Regex detects malformed JSON ✅
- JSON parsing fails ❌ → No data collected → Poor responses

## Minimal Fix Strategy
Add JSON auto-correction before MCP execution to handle common malformation patterns.

## Implementation
**Location**: `lib/services/claude_service.dart` 
**Method**: `_processDataRequiredQuery()` - Add correction before `processCommand()`

**Correction Pattern**:
- Detect: `"days": 2"}` 
- Fix: `"days": 2}`

## Expected Outcome
- Malformed JSON auto-corrected
- Two-pass processing restored
- TTS contamination eliminated
- System resilient to JSON generation issues

**Category**: Bug Fix / Error Recovery
**Priority**: High
**Effort**: 15 minutes
