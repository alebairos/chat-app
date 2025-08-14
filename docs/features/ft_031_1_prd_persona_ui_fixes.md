# FT-031: Persona UI Fixes and I-There Rename

## Problem Statement

Multiple UI issues identified in the dynamic persona system after implementing FT-030:

1. **Header Title/Subtitle Still Inverted**: Despite implementing FT-030, the chat header still shows persona name as main title instead of "AI Personas" as main title with persona name as subtitle.

2. **Incorrect Typing Indicator**: When a persona is responding, the typing indicator shows `Instance of 'Future<String>' is typing...` instead of the actual persona display name.

3. **Daymi Clone → I-There Rename**: The "Daymi Clone" persona needs to be renamed to "I-There" throughout the system while maintaining the same personality and behavior.

## Current Issues (Screenshots Evidence)

### Issue 1: Header Layout
- **Expected**: "AI Personas" (main title) / "I-There" (subtitle)
- **Actual**: "Daymi Clone" (main title) / "AI Personas" / "Ari - Life Coach" (confused layout)

### Issue 2: Typing Indicator
- **Expected**: "I-There is typing..."
- **Actual**: "Instance of 'Future<String>' is typing..."

### Issue 3: Persona Name
- **Current**: "Daymi Clone" 
- **Required**: "I-There"

## Technical Analysis

### Root Causes

1. **Header Issue**: The FutureBuilder implementation may not be properly handling the title/subtitle hierarchy or there's a layout conflict.

2. **Typing Indicator**: The code is directly using `_configLoader.activePersonaDisplayName` (which is a Future) instead of awaiting it or using the cached value.

3. **Rename Requirements**: Need to update:
   - `personas_config.json` displayName
   - Any hardcoded references
   - Documentation/configs as needed

## Proposed Solution

### 1. Fix Header Layout (FT-030 Completion)
- **File**: `lib/widgets/chat_app_bar.dart`
- **Fix**: Ensure proper Column layout with correct text hierarchy
- **Verification**: Main title = "AI Personas", Subtitle = current persona name

### 2. Fix Typing Indicator
- **File**: `lib/screens/chat_screen.dart` 
- **Current Code**: `'${_configLoader.activePersonaDisplayName} is typing...'`
- **Fix**: Use cached persona name or await the Future properly
- **Options**:
  - Cache the display name in widget state
  - Use FutureBuilder for typing indicator
  - Store resolved name in a synchronous variable

### 3. Rename Daymi Clone → I-There
- **File**: `assets/config/personas_config.json`
- **Change**: `"displayName": "Daymi Clone"` → `"displayName": "I-There"`
- **Scope**: Display name only (keep internal key as `daymiClone` for consistency)

## Implementation Plan

### Phase 1: Header Fix (High Priority)
1. **Investigate** current AppBar implementation
2. **Fix** title/subtitle hierarchy in chat_app_bar.dart
3. **Test** header displays correctly: "AI Personas" / "I-There"

### Phase 2: Typing Indicator Fix (High Priority)  
1. **Identify** where typing indicator is rendered
2. **Replace** Future usage with cached/resolved string
3. **Test** typing shows "I-There is typing..."

### Phase 3: Rename (Medium Priority)
1. **Update** personas_config.json displayName
2. **Verify** no hardcoded "Daymi Clone" references
3. **Test** persona shows as "I-There" everywhere

## Acceptance Criteria

### ✅ Header Layout
- [x] Main title displays "AI Personas"
- [x] Subtitle displays current persona name (e.g., "I-There")
- [x] Layout is clean and properly formatted
- [x] Works for all personas (Ari, Sergeant Oracle, I-There)

### ✅ Typing Indicator  
- [x] Shows proper persona name: "I-There is typing..."
- [x] No "Instance of 'Future<String>'" errors
- [x] Updates correctly when switching personas

### ✅ Persona Rename
- [x] "Daymi Clone" renamed to "I-There" in all UI
- [x] Persona selection screen shows "I-There"
- [x] Chat header shows "I-There" as subtitle
- [x] Typing indicator shows "I-There is typing..."
- [x] Same personality/behavior maintained

### ✅ System Integration
- [x] Hot reload/restart preserves correct display
- [x] Persona switching works seamlessly  
- [x] No compilation errors or warnings
- [x] All three personas work correctly

## Testing Strategy

### Manual Testing
1. **Header Test**: Launch app, verify header shows "AI Personas" / current persona
2. **Typing Test**: Send message, verify typing indicator shows correct name
3. **Switch Test**: Change personas, verify header updates correctly
4. **Rename Test**: Select I-There, verify name appears everywhere

### Integration Testing
1. **Cross-Persona**: Test header/typing with all three personas
2. **State Persistence**: Test after hot reload/restart
3. **Error Handling**: Verify graceful degradation if name loading fails

## Dependencies
- No external dependencies
- Builds on FT-030 (Dynamic Chat Header)
- May require testing framework updates for new persona name

## Risks and Mitigation
- **Risk**: Header layout conflicts with different screen sizes
- **Mitigation**: Test on various device sizes, use responsive design
- **Risk**: Breaking existing persona switching logic
- **Mitigation**: Thorough testing of persona state management

## Success Metrics
- Zero UI layout issues in header
- Zero "Future<String>" errors in logs
- 100% consistent persona name display across app
- User can seamlessly interact with "I-There" persona

---

**Priority**: High  
**Effort**: 2-4 hours  
**Dependencies**: FT-030  
**Affects**: UI, UX, Persona Management
