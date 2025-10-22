# FT-216: Prevent Empty Profile Names in UI

## Problem Statement

The profile name edit dialog allows users to save empty names, which contradicts the backend logic that prevents clearing names. The Save button remains enabled even when the input field is empty or contains only whitespace.

- **Priority**: Medium
- **Category**: UI/UX Bug Fix
- **Effort**: 15 minutes

## Current Behavior
- User can submit empty profile name
- Save button is always enabled regardless of input
- Backend `ProfileService.setProfileName('')` returns early without clearing

## Expected Behavior
- Save button should be disabled when input is empty or whitespace-only
- User must provide a valid name to save changes
- Clear validation feedback for empty input

## Solution

Update `ProfileService.validateProfileName()` to reject empty names:

```dart
static String? validateProfileName(String name) {
  final trimmedName = name.trim();

  if (trimmedName.isEmpty) {
    return 'Name cannot be empty';
  }

  if (trimmedName.length > 50) {
    return 'Name must be 50 characters or less';
  }

  if (trimmedName.contains(RegExp(r'[<>"\\/]'))) {
    return 'Name contains invalid characters';
  }

  return null; // Valid
}
```

## Implementation

**File**: `lib/services/profile_service.dart`
- Add empty check to `validateProfileName()` method
- Return error message for empty/whitespace-only input

## Acceptance Criteria

- [ ] Save button disabled when profile name field is empty
- [ ] Error message "Name cannot be empty" shown for empty input
- [ ] User must enter valid name to save changes
- [ ] Existing validation (length, characters) still works

## Testing

```dart
test('validateProfileName rejects empty names', () {
  expect(ProfileService.validateProfileName(''), 'Name cannot be empty');
  expect(ProfileService.validateProfileName('   '), 'Name cannot be empty');
  expect(ProfileService.validateProfileName('Valid'), null);
});
```
