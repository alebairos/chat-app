# FT-170: Journal Button Text Alignment Fix

## Feature Information
- **Feature ID**: FT-170
- **Category**: UI Bug Fix
- **Priority**: Medium
- **Effort Estimate**: 0.25 hours
- **Status**: Pending

## Problem Statement

### Current Issue
The "Gerar Novamente" button text appears left-aligned instead of centered within the button, creating an inconsistent UI appearance.

### Visual Evidence
Screenshot shows the button text is not properly centered, appearing to lean towards the left side of the button.

### Root Cause Analysis
The issue is with `ElevatedButton.icon()` internal layout:

**File**: `lib/features/journal/screens/journal_screen.dart`
**Lines**: 185-214

```dart
ElevatedButton.icon(
  icon: const Icon(Icons.auto_awesome, size: 18),
  label: Text("Gerar Novamente"),
  style: ElevatedButton.styleFrom(
    alignment: Alignment.center, // ❌ This affects button position, not content
  ),
)
```

**Problem**: `ElevatedButton.icon()` uses an internal `Row` layout for icon + text. The `alignment: Alignment.center` in `styleFrom()` controls the **button's position** within its parent container, **not the internal content alignment**.

## Solution

### Approach
Add explicit content alignment to center the icon + text within the button using `mainAxisAlignment` and `mainAxisSize` properties.

### Implementation Strategy
Use the `style` property to control the internal button content layout, specifically targeting the `Row` that contains the icon and text.

### Code Changes

**File**: `lib/features/journal/screens/journal_screen.dart`

**Before** (lines 208-213):
```dart
style: ElevatedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  backgroundColor: Theme.of(context).primaryColor,
  foregroundColor: Colors.white,
  alignment: Alignment.center, // ❌ Only affects button position
),
```

**After**:
```dart
style: ElevatedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  backgroundColor: Theme.of(context).primaryColor,
  foregroundColor: Colors.white,
  alignment: Alignment.center,
  // ✅ Add internal content alignment
  textStyle: const TextStyle(fontSize: 14),
).copyWith(
  // ✅ Control internal Row alignment for icon + text
  alignment: MaterialStateProperty.all(Alignment.center),
  padding: MaterialStateProperty.all(
    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  ),
),
```

### Alternative Approach (Simpler)
Replace `ElevatedButton.icon()` with regular `ElevatedButton()` and manually create the icon + text layout:

```dart
ElevatedButton(
  onPressed: _isGenerating ? null : _generateJournalEntry,
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    backgroundColor: Theme.of(context).primaryColor,
    foregroundColor: Colors.white,
    alignment: Alignment.center,
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min, // ✅ Shrink to content
    mainAxisAlignment: MainAxisAlignment.center, // ✅ Center content
    children: [
      _isGenerating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome, size: 18),
      const SizedBox(width: 8), // Spacing between icon and text
      Text(
        _isGenerating
            ? (_selectedLanguage == 'pt_BR'
                ? 'Gerando ambos idiomas...'
                : 'Generating both languages...')
            : (_currentJournalEntry == null
                ? (_selectedLanguage == 'pt_BR'
                    ? 'Gerar Diário'
                    : 'Generate Journal')
                : (_selectedLanguage == 'pt_BR'
                    ? 'Gerar Novamente'
                    : 'Regenerate')),
        style: const TextStyle(fontSize: 14),
      ),
    ],
  ),
)
```

## Expected Results

### Visual Improvements
1. **Centered Text**: Button text appears perfectly centered within the button
2. **Consistent Spacing**: Icon and text have proper, balanced spacing
3. **Professional Appearance**: Button looks polished and well-aligned

### Technical Benefits
1. **Predictable Layout**: Manual control over internal button layout
2. **Consistent Behavior**: Same alignment behavior across all button states
3. **Maintainable Code**: Clear, explicit layout definition

## Implementation Notes

### Recommended Approach
Use the **Alternative Approach** (regular `ElevatedButton` with manual `Row`) because:
- More explicit control over layout
- Easier to debug and maintain
- Consistent with Flutter best practices
- No complex `MaterialStateProperty` overrides needed

### Risk Assessment
- **Very Low Risk**: Simple UI layout change
- **No Breaking Changes**: Same functionality, better appearance
- **Performance**: No impact, same widget complexity

## Acceptance Criteria

- [ ] Button text appears perfectly centered within the button
- [ ] Icon and text have consistent, balanced spacing
- [ ] Button appearance is consistent across all states (generate/regenerate/loading)
- [ ] No layout issues on different screen sizes
- [ ] Button maintains proper touch target size
