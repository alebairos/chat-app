# FT-202: Fix Persona Over-Introduction in Every Message

## Problem Statement

AI personas are introducing themselves in every message instead of maintaining conversation continuity, causing repetitive and unnatural interactions.

### Current Broken Behavior
**Every Message**: "oi, sou o I-There - seu reflexo que vive no Mirror Realm..."
- AI re-introduces itself constantly
- Treats each message as first interaction
- Ignores conversation history context

### Expected Behavior
- **First Message**: Natural introduction
- **Subsequent Messages**: Continue conversation without re-introduction
- **Only Re-introduce**: When directly asked or after persona switch

## Evidence from Logs

**Line 950**: `Original AI response: oi, sou o I-There - seu reflexo que vive no Mirror Realm. que bom que você está satisfeito com a precisão dos registros!`

The AI is starting with identity statement even in continuation messages.

## Root Cause Analysis

**File**: `assets/config/multi_persona_config.json` (line 7)

The `identityContextTemplate` is too aggressive:
```json
"identityContextTemplate": "## CRITICAL: YOUR IDENTITY\nYou are {{displayName}} ({{personaKey}}).\nThis is your CURRENT and ACTIVE identity.\n\nIMPORTANT IDENTITY RULES:\n- When asked \"com quem eu falo?\" respond EXACTLY: \"{{displayName}}\"\n..."
```

**Problem**: The "CRITICAL" emphasis makes AI think it must constantly re-establish identity.

**Contributing Factor**: FT-200 removes conversation history injection, so AI lacks context about previous interactions.

## Solution

### Replace Aggressive Identity Template
Change from **identity-obsessed** to **context-aware** approach:

```json
"identityContextTemplate": "You are {{displayName}} ({{personaKey}}).

## CONVERSATION CONTINUITY
- If this appears to be your first interaction, introduce yourself naturally according to your persona style
- If continuing an ongoing conversation, maintain natural flow without re-introduction
- Only state your identity when directly asked (\"com quem eu falo?\") or when clarification is needed

## IDENTITY GUIDELINES
- Respond to identity questions with: \"{{displayName}}\"
- Maintain your authentic communication style and symbols
- Do not copy other personas' styles from conversation history
- Let conversation context guide whether introduction is needed"
```

### Key Changes
1. **Remove "CRITICAL" emphasis** - reduces identity obsession
2. **Add conversation continuity logic** - teaches when to introduce vs continue
3. **Context-aware instructions** - AI decides based on conversation flow
4. **Natural interaction guidance** - promotes normal conversation patterns

## Implementation

### Phase 1: Update Configuration
- Modify `multi_persona_config.json` identity template
- Test with I-There persona first
- Verify natural conversation flow

### Phase 2: Validation
- Confirm first messages include introduction
- Verify subsequent messages continue naturally
- Test identity questions still work correctly

## Acceptance Criteria

### Functional Requirements
- [ ] First message includes natural persona introduction
- [ ] Subsequent messages continue without re-introduction
- [ ] Identity questions ("com quem eu falo?") answered correctly
- [ ] Persona switching triggers appropriate re-introduction

### User Experience Requirements
- [ ] Natural conversation flow maintained
- [ ] No repetitive identity statements
- [ ] Personas feel more human and contextual
- [ ] Multi-persona conversations flow smoothly

## Testing Strategy

### Before Fix
```
User: "opa"
AI: "oi, sou o I-There - seu reflexo que vive no Mirror Realm..."

User: "legal"  
AI: "oi, sou o I-There - seu reflexo que vive no Mirror Realm..." ❌ REPETITIVE
```

### After Fix
```
User: "opa"
AI: "oi, sou o I-There - seu reflexo que vive no Mirror Realm..."

User: "legal"
AI: "que bom! fico curioso sobre..." ✅ NATURAL CONTINUATION
```

## Risk Assessment

### Low Risk
- **Configuration Change Only**: No code modifications required
- **Reversible**: Simple JSON template update
- **Isolated Impact**: Only affects identity context injection

### Mitigation
- **Gradual Testing**: Test with single persona first
- **Rollback Plan**: Revert to previous template if issues arise
- **Monitoring**: Watch for identity confusion or over-correction

## Success Metrics

### Before Fix
- Every message starts with persona introduction
- Repetitive and robotic conversation feel
- Users notice unnatural interaction patterns

### After Fix
- Natural conversation continuity maintained
- Personas introduce themselves appropriately
- Smooth multi-persona conversation transitions
- Users experience more human-like interactions

## Dependencies

- `multi_persona_config.json` configuration file
- Multi-persona identity injection system
- FT-200 conversation database queries (context)

## Timeline

- **Analysis**: ✅ Complete
- **Configuration Update**: 5 minutes
- **Testing**: 15 minutes
- **Validation**: 10 minutes
- **Total Effort**: 30 minutes

---

**Priority**: High
**Category**: Bug Fix
**Effort**: Small (30 minutes)
**Impact**: High (improves conversation naturalness)
