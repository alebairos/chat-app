# FT-187: Fix Black Screen After Persona Selection

**Feature ID:** FT-187  
**Priority:** High  
**Category:** Bug Fix  
**Effort:** 15 minutes  

## Problem

Black screen appears when returning from PersonaSelectionScreen to ChatScreen after selecting a persona. This prevents users from continuing their conversation after changing personas.

## Root Cause

The `profile_screen.dart` contains an aggressive navigation command in the `onCharacterSelected` callback:

```dart
onCharacterSelected: () {
  setState(() {});
  // Trigger persona change check in chat screen
  Navigator.of(context).popUntil((route) => route.isFirst);
},
```

The `Navigator.popUntil((route) => route.isFirst)` line pops all navigation routes back to the first route, disrupting the normal navigation flow and causing the ChatScreen to appear black.

## Solution

Remove the problematic navigation line and revert to the working main branch implementation:

```dart
onCharacterSelected: () {
  setState(() {});
},
```

## Implementation

### Files to Change
- `lib/screens/profile_screen.dart`

### Changes Required
1. Remove the `Navigator.of(context).popUntil((route) => route.isFirst);` line
2. Remove the comment `// Trigger persona change check in chat screen`
3. Keep only the `setState(() {});` call

## Testing

1. Navigate to Profile → Persona Selection
2. Select any persona
3. Verify ChatScreen appears normally (not black)
4. Verify persona change is reflected in the app header
5. Verify conversation continues normally

## Success Criteria

- ✅ No black screen after persona selection
- ✅ Normal navigation flow maintained
- ✅ Persona changes are properly reflected
- ✅ ChatScreen functionality remains intact
