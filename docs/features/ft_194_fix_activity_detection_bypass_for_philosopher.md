# FT-194: Fix Activity Detection Bypass for Philosopher Persona

**Feature ID:** FT-194  
**Priority:** Critical  
**Category:** Bug Fix  
**Effort:** 1-2 hours  

## Problem Statement

### Current Issue
Activity detection is **still running** for the Philosopher persona (`aristiosPhilosopher45`) despite having `oracleEnabled: false` in the configuration. The Oracle availability check happens **too late** in the process, allowing unnecessary activity detection to start before being skipped.

### Evidence from Logs
```
Line 266: Activity analysis: Qualified for detection - proceeding with optimized analysis
Line 290: FT-140: Starting MCP-based Oracle activity detection
Line 291: FT-140: Starting MCP Oracle activity detection
Line 292: SystemMCP: Processing command: {"action":"oracle_detect_activities"...}
Line 298: WARNING: MCP Oracle detection returned error: Oracle cache not available
Line 302: FT-064: No Oracle context - skipping activity detection for non-Oracle persona
```

**Problem**: Activity detection **starts** (lines 290-292) before the Oracle check (line 302) determines it should be skipped.

## Root Cause Analysis

### 1. Multiple Entry Points for Activity Detection
The activity detection system has **multiple trigger points**:
- `_processBackgroundActivitiesWithQualification()` ✅ **Has Oracle check**
- `_shouldAnalyzeUserActivities()` ❌ **Missing Oracle check**
- Direct MCP command processing ❌ **Missing Oracle check**

### 2. Oracle Check Timing Issue
**Current Flow (WRONG):**
```
1. Qualify message for activity analysis
2. Start activity detection process
3. Begin MCP Oracle detection
4. Check Oracle availability ← TOO LATE
5. Skip if not available
```

**Correct Flow (NEEDED):**
```
1. Check Oracle availability FIRST ← SHOULD BE HERE
2. If disabled, skip entirely
3. If enabled, qualify and proceed
```

### 3. Missing Early Gate Check
The Oracle availability check in `_processBackgroundActivitiesWithQualification()` exists but there's **another path** that bypasses this check and triggers activity detection directly.

## Solution Design

### A) Add Early Oracle Gate Check

Add Oracle availability check **before** any activity detection logic starts, at the **qualification stage**.

**Location**: `ClaudeService.sendMessage()` - before calling `_processBackgroundActivitiesWithQualification()`

### B) Consolidate Oracle Checks

Ensure **all activity detection entry points** check Oracle availability first:

1. **Message qualification stage** ← NEW
2. **Background activities processing** ✅ Already exists
3. **MCP command processing** ← ENHANCE

### C) Early Return Pattern

Implement **early return** pattern to prevent any activity detection overhead for non-Oracle personas:

```dart
// Check Oracle availability FIRST
if (_systemMCP != null && !_systemMCP!.isOracleEnabled) {
  _logger.info('Activity analysis: Skipped - Oracle disabled for current persona');
  return; // EARLY EXIT - no processing overhead
}
```

## Implementation Plan

### Phase 1: Add Early Oracle Gate (30 minutes)

**File**: `lib/services/claude_service.dart`

**Location**: In `sendMessage()` method, before `_processBackgroundActivitiesWithQualification()` call

**Change**:
```dart
// FT-194: Early Oracle gate - prevent activity detection for non-Oracle personas
if (_systemMCP != null && !_systemMCP!.isOracleEnabled) {
  _logger.info('Activity analysis: Skipped - Oracle disabled for current persona');
  return; // Skip all activity detection processing
}

// Only proceed with activity detection if Oracle is enabled
await _processBackgroundActivitiesWithQualification(userMessage, qualificationResponse, messageId);
```

### Phase 2: Enhance Activity Qualification Check (15 minutes)

**File**: `lib/services/claude_service.dart`

**Method**: `_shouldAnalyzeUserActivities()`

**Enhancement**: Add Oracle availability check to the qualification logic:
```dart
bool _shouldAnalyzeUserActivities(String qualificationResponse) {
  // FT-194: First check if Oracle is available for this persona
  if (_systemMCP != null && !_systemMCP!.isOracleEnabled) {
    return false; // Never analyze activities for non-Oracle personas
  }
  
  // Existing qualification logic...
}
```

### Phase 3: Strengthen MCP Command Validation (15 minutes)

**File**: `lib/services/system_mcp_service.dart`

**Enhancement**: Add more explicit logging for blocked Oracle commands:
```dart
case 'oracle_detect_activities':
  if (!_oracleEnabled) {
    _logger.info('SystemMCP: Oracle activity detection blocked - Oracle disabled for this persona');
    return _errorResponse('Oracle activity detection not available for this persona');
  }
```

### Phase 4: Testing and Validation (30 minutes)

1. Test Philosopher persona - should show **no activity detection logs**
2. Test Oracle Coach persona - should show **normal activity detection**
3. Verify **early return** prevents unnecessary processing overhead

## Expected Log Output After Fix

### For Philosopher Persona (aristiosPhilosopher45):
```
flutter: Activity analysis: Skipped - Oracle disabled for current persona
// NO activity detection logs should appear
```

### For Oracle Coach Persona (ariOracleCoach45):
```
flutter: Activity analysis: Qualified for detection - proceeding with optimized analysis
flutter: FT-140: Starting MCP-based Oracle activity detection
// Normal activity detection continues...
```

## Success Metrics

### Immediate Validation
- ✅ **No activity detection logs** for Philosopher persona
- ✅ **Early return** prevents unnecessary processing
- ✅ **Normal activity detection** for Oracle-enabled personas

### Performance Benefits
- ✅ **Reduced API calls** for non-Oracle personas
- ✅ **Lower processing overhead** for pure conversational personas
- ✅ **Cleaner logs** without Oracle-related warnings

## Technical Implementation Details

### File Changes Required
1. `lib/services/claude_service.dart` - Add early Oracle gate and enhance qualification
2. `lib/services/system_mcp_service.dart` - Strengthen MCP command validation
3. No configuration changes needed - uses existing `oracleEnabled` flag

### Backward Compatibility
- ✅ No breaking changes to existing functionality
- ✅ Oracle-enabled personas continue working normally
- ✅ Only affects non-Oracle personas by preventing unnecessary processing

## Risk Mitigation

### Potential Issues
1. **Over-blocking** - Mitigated by checking `_systemMCP!.isOracleEnabled` flag accurately
2. **Logic conflicts** - Mitigated by consolidating all Oracle checks to use same flag
3. **Performance regression** - Mitigated by early return pattern reducing overhead

### Rollback Plan
- Revert changes to `claude_service.dart` and `system_mcp_service.dart`
- All changes are code-based, no configuration impact
- Existing Oracle toggle mechanism remains intact

## Root Cause Summary

The issue occurs because **activity detection qualification** happens **before** Oracle availability is checked. The system qualifies the message for activity analysis, starts the detection process, and only **during MCP command processing** discovers that Oracle is disabled.

**The fix moves the Oracle check to the earliest possible point** - before any activity detection logic begins - ensuring non-Oracle personas never enter the activity detection pipeline at all.

This provides both **correct behavior** (no activity detection for Philosopher) and **performance benefits** (no unnecessary processing overhead).
