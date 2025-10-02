# FT-173: User Profile Name

## Feature Information
- **Feature ID**: FT-173
- **Category**: User Experience
- **Priority**: Medium
- **Effort Estimate**: 0.5 hours
- **Status**: Pending

## Problem Statement

### Current Issue
AI personas use a hardcoded name "Alexandre" in journal entries and interactions, making the experience less personal for other users.

### User Need
Users want AI personas to address them by their actual name for a more personalized and engaging experience.

## Solution

### Minimal Implementation
Add a user profile name field that allows users to set how AI personas address them.

### Core Requirements
1. **Profile Name Field**: Add editable name field to Profile screen
2. **Persistent Storage**: Store user name using SharedPreferences
3. **Journal Integration**: Use dynamic name in journal generation instead of hardcoded "Alexandre"
4. **Default Behavior**: Graceful fallback when no name is set

## Implementation

### UI Changes
**File**: `lib/screens/profile_screen.dart`

Add name field above persona selection in "Your Guide" section:
```dart
ListTile(
  leading: Icon(Icons.account_circle),
  title: Text(profileName.isEmpty ? 'Add your name' : profileName),
  subtitle: Text('How AI personas address you'),
  trailing: Icon(Icons.edit),
  onTap: () => _showNameEditDialog(),
)
```

### Storage Service
**New File**: `lib/services/profile_service.dart`

```dart
class ProfileService {
  static const String _profileNameKey = 'user_profile_name';
  
  static Future<String> getProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileNameKey) ?? '';
  }
  
  static Future<void> setProfileName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameKey, name);
  }
}
```

### Journal Integration
**File**: `lib/features/journal/services/journal_generation_service.dart`

Update `_buildSimplePrompt()` method:
```dart
static String _buildSimplePrompt(DateTime date, List<ChatMessageModel> messages, 
    List<ActivityModel> activities, String userName) {
  final name = userName.isEmpty ? 'Alexandre' : userName;
  return '''You are I-There speaking directly to $name about their day...''';
}
```

### Name Input Dialog
Simple text input dialog with validation:
- Maximum 50 characters
- Trim whitespace
- Cancel/Save buttons
- Real-time UI update

## Acceptance Criteria

- [ ] User can set their name in Profile screen
- [ ] Name persists between app sessions
- [ ] Journal entries use the user's name instead of "Alexandre"
- [ ] Empty name falls back to "Alexandre" gracefully
- [ ] Name input has basic validation (length, trimming)
- [ ] UI updates immediately after name change

## Future Expansion

This minimal implementation provides foundation for:
- Avatar support
- Multiple profile preferences
- Persona-specific name variations
- Full profile management system

## Technical Notes

### Dependencies
- Uses existing `shared_preferences` package
- No database schema changes required
- Minimal impact on existing codebase

### Risk Assessment
- **Very Low Risk**: Simple preference storage
- **No Breaking Changes**: Fallback maintains current behavior
- **Easy Rollback**: Can be disabled without data loss
