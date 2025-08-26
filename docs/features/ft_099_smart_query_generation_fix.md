# FT-099: Smart Query Generation Fix

## Problem
Claude generates imprecise queries for specific day requests:
- User asks: "o que eu fiz no sábado?" (Saturday only)
- Claude generates: `days: 2` (gets Friday + Saturday data)
- Reports combined 2-day data as Saturday-only results

## Root Cause
Temporal mapping guidance is too generic - doesn't emphasize precise day calculation for specific day queries.

## Minimal Fix Strategy
Add explicit day calculation guidance with concrete examples to ensure Claude generates precise single-day queries.

## Implementation
**Location**: `lib/services/claude_service.dart`
**Method**: `_buildSystemPrompt()` - Enhance Context-Aware Temporal Mapping section

**Key Addition**: Explicit day calculation examples for common scenarios:
- Monday + "sábado" → `days: 3` (gets Saturday only)
- Emphasize single-day precision over day ranges

## Expected Outcome
- More precise query generation
- Reduced need for data filtering
- Accurate single-day activity reports

**Category**: Bug Fix / Query Precision
**Priority**: High  
**Effort**: 10 minutes
