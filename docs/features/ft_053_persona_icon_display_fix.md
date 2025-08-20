# Feature ft_053: Persona Icon Display Fix

## Feature Fix Document

### Executive Summary

This document outlines the fix for a critical bug where AI messages always display the Sergeant Oracle icon regardless of which persona is actually selected. While the typing indicator correctly shows the selected persona, the final message reverts to showing the Sergeant's military tech icon. This fix ensures that each AI message displays the appropriate icon for the persona that generated it.

### Bug Description

**Current Behavior:**
1. User selects a persona (e.g., Ari Life Coach)
2. Typing indicator correctly shows "Ari Life Coach is typing..." with appropriate icon
3. When message appears, it shows the Sergeant Oracle icon (military_tech) regardless of selected persona
4. This happens for all personas - they all show as Sergeant Oracle

**Expected Behavior:**
1. Each AI message should display the icon of the persona that generated it
2. Icons should match the persona consistently throughout the conversation
3. Historical messages should maintain correct persona icons

### Root Cause Analysis

The investigation revealed three key issues:

#### 1. Missing Persona Metadata in ChatMessage Widget
The `ChatMessage` widget doesn't accept persona information:
```dart
// Current ChatMessage constructor - missing persona fields
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? audioPath;
  final Duration? duration;
  // personaKey and personaDisplayName are NOT here
}
```

#### 2. Persona Data Not Passed from Model to Widget
In `chat_screen.dart`, the `_createChatMessage` method doesn't pass persona metadata:
```dart
ChatMessage _createChatMessage(ChatMessageModel model) {
  return ChatMessage(
    key: ValueKey(model.id),
    text: model.text,
    isUser: model.isUser,
    audioPath: model.mediaPath,
    duration: model.duration,
    // persona metadata exists in model but not passed to widget
  );
}
```

#### 3. Hardcoded Sergeant Oracle Icon
The avatar display is hardcoded in `ChatMessage`:
```dart
const CircleAvatar(
  backgroundColor: Colors.deepPurple,
  child: Icon(Icons.military_tech, color: Colors.white),
),
```

### Technical Solution

#### 1. Update ChatMessage Widget Structure

**File:** `lib/widgets/chat_message.dart`

Add persona metadata fields:
```dart
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? audioPath;
  final Duration? duration;
  final bool isTest;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;
  final String? personaKey;        // NEW: e.g., 'ariLifeCoach'
  final String? personaDisplayName; // NEW: e.g., 'Ari Life Coach'

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.audioPath,
    this.duration,
    this.isTest = false,
    this.onDelete,
    this.onEdit,
    this.personaKey,        // NEW
    this.personaDisplayName, // NEW
    super.key,
  });
```

Update the `copyWith` method:
```dart
ChatMessage copyWith({
  String? text,
  bool? isUser,
  String? audioPath,
  Duration? duration,
  bool? isTest,
  VoidCallback? onDelete,
  Function(String)? onEdit,
  String? personaKey,        // NEW
  String? personaDisplayName, // NEW
}) {
  return ChatMessage(
    text: text ?? this.text,
    isUser: isUser ?? this.isUser,
    audioPath: audioPath ?? this.audioPath,
    duration: duration ?? this.duration,
    isTest: isTest ?? this.isTest,
    onDelete: onDelete ?? this.onDelete,
    onEdit: onEdit ?? this.onEdit,
    personaKey: personaKey ?? this.personaKey,               // NEW
    personaDisplayName: personaDisplayName ?? this.personaDisplayName, // NEW
  );
}
```

#### 2. Add Persona Icon and Color Methods

Add these helper methods to `ChatMessage` widget:
```dart
Color _getPersonaColor(String? personaKey) {
  if (personaKey == null) return Colors.deepPurple; // default to Sergeant
  
  final Map<String, Color> colorMap = {
    'ariLifeCoach': Colors.teal,
    'sergeantOracle': Colors.deepPurple,
    'iThereClone': Colors.blue,
    // Add more personas as needed
  };
  
  return colorMap[personaKey] ?? Colors.grey;
}

IconData _getPersonaIcon(String? personaKey) {
  if (personaKey == null) return Icons.military_tech; // default to Sergeant
  
  final Map<String, IconData> iconMap = {
    'ariLifeCoach': Icons.psychology,
    'sergeantOracle': Icons.military_tech,
    'iThereClone': Icons.face,
    // Add more personas as needed
  };
  
  return iconMap[personaKey] ?? Icons.smart_toy;
}
```

#### 3. Update Avatar Display Logic

Replace the hardcoded avatar section:
```dart
if (!isUser) ...[
  isTest
      ? const SizedBox(
          width: 40,
          height: 40,
          child: Placeholder(),
        )
      : CircleAvatar(
          backgroundColor: _getPersonaColor(personaKey),
          child: Icon(
            _getPersonaIcon(personaKey),
            color: Colors.white,
          ),
        ),
  const SizedBox(width: 8),
],
```

#### 4. Update ChatScreen to Pass Persona Data

**File:** `lib/screens/chat_screen.dart`

Update the `_createChatMessage` method:
```dart
ChatMessage _createChatMessage(ChatMessageModel model) {
  // Only log if startup logging is enabled
  if (_logger.isStartupLoggingEnabled()) {
    _logger.logStartup('Creating ChatMessage widget:');
    _logger.logStartup('- ID: ${model.id}');
    _logger.logStartup('- Text: ${model.text}');
    _logger.logStartup('- Is user: ${model.isUser}');
    _logger.logStartup('- Persona: ${model.personaKey}'); // NEW
  }

  return ChatMessage(
    key: ValueKey(model.id),
    text: model.text,
    isUser: model.isUser,
    audioPath: model.mediaPath,
    duration: model.duration,
    personaKey: model.personaKey,               // NEW
    personaDisplayName: model.personaDisplayName, // NEW
    onDelete: () => _deleteMessage(model.id),
    onEdit: model.isUser
        ? (text) {
            _logger.debug('Edit callback for message:');
            _logger.debug('- ID: ${model.id}');
            _logger.debug('- Current text: $text');
            _showEditDialog(model.id.toString(), text);
          }
        : null,
  );
}
```

### Testing Requirements

#### 1. Unit Tests
- Test persona icon mapping for all personas
- Test color mapping for all personas
- Test default behavior when persona is null
- Test copyWith method preserves persona data

#### 2. Widget Tests
- Test ChatMessage renders correct icon for each persona
- Test ChatMessage renders correct color for each persona
- Test user messages don't show persona icons

#### 3. Integration Tests
- Test switching between personas shows correct icons
- Test loading historical messages shows correct personas
- Test new messages display correct persona icons

#### 4. Manual Testing Checklist
- [ ] Select Ari Life Coach → Send message → Shows psychology icon in teal
- [ ] Select Sergeant Oracle → Send message → Shows military_tech icon in deep purple
- [ ] Select I-There → Send message → Shows face icon in blue
- [ ] Load app with existing messages → All show correct persona icons
- [ ] Switch personas mid-conversation → New messages show new persona icon
- [ ] Typing indicator matches final message icon

### Migration Considerations

**Existing Messages:**
- Messages saved after ft_049 implementation have persona metadata
- Messages saved before ft_049 will show default Sergeant Oracle icon
- No data migration needed - graceful fallback to default

### Implementation Checklist

- [ ] Update ChatMessage widget with persona fields
- [ ] Add persona icon/color helper methods
- [ ] Update avatar display logic in ChatMessage
- [ ] Update _createChatMessage to pass persona data
- [ ] Test with all three personas
- [ ] Verify typing indicator still works correctly
- [ ] Test with historical messages
- [ ] Update any ChatMessage widget tests

### Rollout Plan

1. **Implementation** (30 minutes)
   - Update ChatMessage widget
   - Update ChatScreen
   - Run existing tests

2. **Testing** (30 minutes)
   - Manual testing with all personas
   - Verify historical messages
   - Test edge cases

3. **Deployment**
   - No database migration needed
   - No configuration changes needed
   - Backward compatible with existing messages

### Success Criteria

- All AI messages display the correct persona icon
- Icon colors match the persona appropriately
- Historical messages with persona metadata show correct icons
- Messages without persona metadata gracefully fallback to Sergeant Oracle
- No performance impact from icon selection logic
- Typing indicator continues to work correctly

### Future Enhancements

1. **Dynamic Persona Icons**
   - Load icon configuration from persona JSON files
   - Support custom icons for new personas
   - Icon theme customization

2. **Persona Badges**
   - Add small badge to indicate persona type
   - Show persona name on hover/long press
   - Persona switching animation

3. **Icon Consistency**
   - Use same icon logic in persona selector
   - Consistent icons across all UI components
   - Icon size and style standardization
