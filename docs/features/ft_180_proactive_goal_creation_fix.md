# FT-180: Proactive Goal Creation Fix

**Feature ID:** FT-180  
**Priority:** High  
**Category:** Bug Fix  
**Effort Estimate:** 15 minutes  

## Problem Statement

Personas fail to create goals when users commit to improvement plans, despite having `create_goal` MCP function available.

**Observed Issue:**
- User discusses sleep improvement and commits to routine ("sim, me lembre")
- Persona provides excellent advice but doesn't create ODM1 "Dormir melhor" goal
- Goals tab shows old OCX1 "Correr X Km" instead of relevant sleep goal

**Root Cause:** MCP `create_goal` instructions only trigger on explicit goal requests, missing implicit commitment signals.

## Solution

Enhance `create_goal` MCP function with proactive triggers for commitment recognition.

## Technical Implementation

**File:** `assets/config/mcp_base_config.json`

**Enhancement:** Add proactive triggers to `when_to_use` array:

```json
"when_to_use": [
  // Existing triggers...
  "PROACTIVE: User agrees to follow advice/plan for improvement (\"sim\", \"bora\", \"vamos fazer\", \"pode ser\")",
  "PROACTIVE: User commits to lifestyle changes you've suggested (sleep routine, exercise plan, etc.)",
  "PROACTIVE: User asks for reminders about improvement activities you've discussed"
],
"MANDATORY_BEHAVIOR": "When user commits to improvement plan you've suggested, IMMEDIATELY create the corresponding goal. Don't wait for explicit goal creation request."
```

## Expected Results

**Before Fix:**
```
User: "sim, me lembre" (after sleep advice)
Persona: Provides reminder, no goal created
Goals Tab: Shows old OCX1 "Correr X Km"
```

**After Fix:**
```
User: "sim, me lembre" (after sleep advice)  
Persona: Creates {"action": "create_goal", "objective_code": "ODM1", "objective_name": "Dormir melhor"}
Goals Tab: Shows "Dormir melhor" goal
```

## Validation

Test with sleep improvement conversation:
1. User discusses sleep issues
2. Persona provides sleep advice
3. User commits ("sim", "bora", etc.)
4. Verify ODM1 goal appears in Goals tab

## Dependencies

- Requires existing `create_goal` MCP function (FT-174)
- Uses Oracle framework objectives (ODM1, OPP1, etc.)
- No code changes required - configuration only

## Impact

- **Immediate:** Fixes goal creation gap in current conversations
- **Broader:** Improves persona proactivity for all improvement areas
- **User Experience:** Goals tab reflects actual user commitments
