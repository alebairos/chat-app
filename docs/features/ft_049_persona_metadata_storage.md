# Feature Specification: Persona Metadata Storage for Messages

## Overview

This feature specification outlines the implementation of persona metadata storage in chat messages to enable accurate export functionality and enhanced UI persona display. Currently, AI messages are saved without persona information, making it impossible to identify which persona (Ari, Sergeant Oracle, I-There) wrote each message.

## Feature Summary

**Feature ID:** FT-049  
**Priority:** High (Blocker for FT-048)  
**Category:** Data Storage & Architecture  
**Estimated Effort:** 2-3 days  

### User Story
> As a user, I want each AI message to remember which persona wrote it, so that when I export my chat history or view messages, I can see the correct persona name and icon for each response, even after switching between different AI personalities.

## Requirements

### Functional Requirements

#### FR-001: Persona Metadata Storage
- **Objective:** Store persona information with each AI message at the time of creation
- **Data Fields:** Add `personaKey` and `personaDisplayName` to `ChatMessageModel`
- **Capture Point:** When AI responses are saved to database in `chat_screen.dart`
- **Scope:** All new AI messages must include persona metadata

#### FR-002: Dynamic Persona Display in Chat
- **Current State:** Hardcoded icon (`Icons.military_tech`) in `ChatMessage` widget (line 137)
- **New Behavior:** Display persona-specific icon and color based on stored message metadata
- **Fallback:** Use current active persona for legacy messages without metadata
- **Visual Consistency:** Match persona icons from `CustomChatAppBar` and `ChatScreen`

#### FR-003: Database Schema Migration
- **Migration Required:** Add new fields to existing Isar schema
- **Backward Compatibility:** Handle existing messages without persona data
- **Data Integrity:** Ensure no message loss during migration
- **Performance:** Migration should not significantly impact app startup time

#### FR-004: Legacy Message Handling
- **Identification:** Messages saved before this feature implementation
- **Display Strategy:** Show generic "AI Assistant" or current persona for old messages
- **Export Strategy:** Handle gracefully in chat export functionality
- **User Communication:** Optionally inform users about legacy message limitations

### Non-Functional Requirements

#### NFR-001: Performance
- **Storage Impact:** Minimal increase in database size (~50 bytes per message)
- **Query Performance:** No significant impact on message retrieval speed
- **Migration Speed:** Complete migration within 10 seconds for 10,000 messages
- **UI Performance:** No lag when displaying persona-specific elements

#### NFR-002: Data Consistency
- **Field Validation:** Ensure valid persona keys are stored
- **Null Handling:** Graceful handling of missing persona metadata
- **Concurrent Access:** Safe storage during rapid message exchanges
- **Schema Versioning:** Proper Isar schema version management

#### NFR-003: Maintainability
- **Code Organization:** Clean separation of persona logic
- **Configuration Driven:** Use existing persona configuration system
- **Testability:** Unit tests for all persona metadata functionality
- **Documentation:** Clear code comments and documentation

## Technical Implementation

### Data Model Changes

#### Updated ChatMessageModel
```dart
@collection
class ChatMessageModel {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime timestamp;

  @Index()
  String text;

  bool isUser;

  @enumerated
  MessageType type;

  List<byte>? mediaData;

  String? mediaPath;

  @Index()
  int? durationInMillis;

  // NEW FIELDS for persona metadata
  @Index()
  String? personaKey;          // e.g., 'ariLifeCoach', 'sergeantOracle', 'iThereClone'
  
  String? personaDisplayName;  // e.g., 'Ari Life Coach', 'Sergeant Oracle', 'I-There'

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.type,
    required this.timestamp,
    this.mediaData,
    this.mediaPath,
    Duration? duration,
    this.personaKey,           // NEW
    this.personaDisplayName,   // NEW
  }) : durationInMillis = duration?.inMilliseconds;

  // Additional constructor for AI messages with persona
  ChatMessageModel.aiMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    required this.personaKey,
    required this.personaDisplayName,
    this.mediaData,
    this.mediaPath,
    Duration? duration,
  }) : isUser = false,
       durationInMillis = duration?.inMilliseconds;
  
  // ... existing methods remain unchanged
}
```

#### Isar Schema Migration
```dart
// Schema version will increment from current to handle migration
const ChatMessageModelSchema = CollectionSchema(
  name: r'ChatMessageModel',
  id: 3821037901158827866,  // Will need to be updated
  properties: {
    // ... existing properties ...
    r'personaKey': PropertySchema(
      id: 7,  // Next available ID
      name: r'personaKey',
      type: IsarType.string,
    ),
    r'personaDisplayName': PropertySchema(
      id: 8,  // Next available ID  
      name: r'personaDisplayName',
      type: IsarType.string,
    ),
  },
  // ... rest of schema
);
```

### Storage Service Updates

#### Enhanced ChatStorageService
```dart
class ChatStorageService {
  // Updated saveMessage method
  Future<void> saveMessage({
    required String text,
    required bool isUser,
    required MessageType type,
    Uint8List? mediaData,
    String? mediaPath,
    Duration? duration,
    String? personaKey,        // NEW parameter
    String? personaDisplayName, // NEW parameter
  }) async {
    final isar = await db;

    // Convert absolute path to relative path if needed
    String? relativePath;
    if (type == MessageType.audio && mediaPath != null) {
      // ... existing path logic ...
    }

    final message = ChatMessageModel(
      text: text,
      isUser: isUser,
      type: type,
      timestamp: DateTime.now(),
      mediaData: mediaData?.toList(),
      mediaPath: relativePath,
      duration: duration,
      personaKey: personaKey,           // NEW
      personaDisplayName: personaDisplayName, // NEW
    );

    await isar.writeTxn(() async {
      await isar.chatMessageModels.put(message);
    });
  }

  // New convenience method for AI messages
  Future<void> saveAIMessage({
    required String text,
    required MessageType type,
    required String personaKey,
    required String personaDisplayName,
    Uint8List? mediaData,
    String? mediaPath,
    Duration? duration,
  }) async {
    await saveMessage(
      text: text,
      isUser: false,
      type: type,
      mediaData: mediaData,
      mediaPath: mediaPath,
      duration: duration,
      personaKey: personaKey,
      personaDisplayName: personaDisplayName,
    );
  }

  // ... existing methods remain unchanged
}
```

### Chat Screen Integration

#### Updated Message Saving Logic
```dart
// In _sendMessage() method (around line 484):
final aiMessageModel = ChatMessageModel(
  text: response.text,
  isUser: false,
  type: messageType,
  timestamp: DateTime.now(),
  mediaPath: response.audioPath,
  duration: response.audioDuration,
  personaKey: _configLoader.activePersonaKey,           // NEW
  personaDisplayName: await _configLoader.activePersonaDisplayName, // NEW
);

// Alternative approach using new saveAIMessage method:
await _storageService.saveAIMessage(
  text: response.text,
  type: messageType,
  personaKey: _configLoader.activePersonaKey,
  personaDisplayName: await _configLoader.activePersonaDisplayName,
  mediaPath: response.audioPath,
  duration: response.audioDuration,
);
```

### UI Component Updates

#### Enhanced ChatMessage Widget
```dart
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? audioPath;
  final Duration? duration;
  final bool isTest;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;
  
  // NEW fields for persona display
  final String? personaKey;
  final String? personaDisplayName;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            isTest
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Placeholder(),
                  )
                : CircleAvatar(
                    backgroundColor: _getPersonaColor(),
                    child: Icon(
                      _getPersonaIcon(),
                      color: Colors.white,
                    ),
                  ),
            const SizedBox(width: 8),
          ],
          // ... rest of widget remains similar
        ],
      ),
    );
  }

  // NEW methods for persona-specific display
  IconData _getPersonaIcon() {
    if (personaKey == null) {
      // Fallback for legacy messages
      return Icons.smart_toy;
    }
    
    final Map<String, IconData> iconMap = {
      'ariLifeCoach': Icons.psychology,
      'sergeantOracle': Icons.military_tech,
      'iThereClone': Icons.face,
    };
    return iconMap[personaKey] ?? Icons.smart_toy;
  }

  Color _getPersonaColor() {
    if (personaKey == null) {
      // Fallback for legacy messages
      return Colors.deepPurple;
    }
    
    final Map<String, Color> colorMap = {
      'ariLifeCoach': Colors.teal,
      'sergeantOracle': Colors.deepPurple,
      'iThereClone': Colors.blue,
    };
    return colorMap[personaKey] ?? Colors.deepPurple;
  }
}
```

#### Updated Message Creation in ChatScreen
```dart
ChatMessage _createChatMessage(ChatMessageModel model) {
  return ChatMessage(
    key: ValueKey(model.id),
    text: model.text,
    isUser: model.isUser,
    audioPath: model.mediaPath,
    duration: model.duration,
    personaKey: model.personaKey,           // NEW
    personaDisplayName: model.personaDisplayName, // NEW
    onDelete: () => _deleteMessage(model.id),
    onEdit: (text) => _showEditDialog(model.id.toString(), text),
  );
}
```

### Migration Strategy

#### Database Migration Process
```dart
class ChatStorageService {
  Future<void> migrateToPersonaMetadata() async {
    final isar = await db;
    
    // Check if migration is needed
    final firstMessage = await isar.chatMessageModels
        .where()
        .limit(1)
        .findFirst();
    
    if (firstMessage?.personaKey != null) {
      // Migration already completed
      return;
    }
    
    // Perform migration for legacy messages
    final allMessages = await isar.chatMessageModels
        .where()
        .filter()
        .isUserEqualTo(false) // Only AI messages need persona info
        .findAll();
    
    await isar.writeTxn(() async {
      for (final message in allMessages) {
        // For legacy messages, we can't determine exact persona
        // Use a generic fallback
        final updatedMessage = message.copyWith(
          personaKey: 'unknown',
          personaDisplayName: 'AI Assistant',
        );
        await isar.chatMessageModels.put(updatedMessage);
      }
    });
  }
}
```

## Implementation Phases

### Phase 1: Data Model and Storage (Day 1)
- [ ] Update `ChatMessageModel` with persona fields
- [ ] Regenerate Isar schema with new fields
- [ ] Update `ChatStorageService.saveMessage()` method
- [ ] Add `saveAIMessage()` convenience method
- [ ] Implement database migration logic
- [ ] Write unit tests for storage changes

### Phase 2: Chat Screen Integration (Day 1-2)
- [ ] Update AI message saving in `_sendMessage()` method
- [ ] Update AI message saving in `_handleAudioMessage()` method
- [ ] Capture current persona metadata during message creation
- [ ] Test persona data storage with all message types
- [ ] Verify migration works with existing messages

### Phase 3: UI Display Enhancement (Day 2)
- [ ] Update `ChatMessage` widget to accept persona fields
- [ ] Implement persona-specific icon and color display
- [ ] Update `_createChatMessage()` method in chat screen
- [ ] Add fallback display for legacy messages
- [ ] Test UI with different persona combinations

### Phase 4: Testing and Polish (Day 2-3)
- [ ] Comprehensive testing with persona switching
- [ ] Test migration with large message histories
- [ ] Performance testing for message loading
- [ ] UI testing for all persona types
- [ ] Integration testing with export functionality (FT-048)

## Testing Strategy

### Unit Tests
```dart
// Test persona metadata storage
test('should save AI message with persona metadata', () async {
  await chatStorage.saveAIMessage(
    text: 'Hello from Ari',
    type: MessageType.text,
    personaKey: 'ariLifeCoach',
    personaDisplayName: 'Ari Life Coach',
  );
  
  final messages = await chatStorage.getMessages(limit: 1);
  expect(messages.first.personaKey, 'ariLifeCoach');
  expect(messages.first.personaDisplayName, 'Ari Life Coach');
});

// Test legacy message handling
test('should handle legacy messages without persona data', () {
  final legacyMessage = ChatMessageModel(
    text: 'Legacy message',
    isUser: false,
    type: MessageType.text,
    timestamp: DateTime.now(),
    // personaKey and personaDisplayName are null
  );
  
  final chatMessage = ChatMessage(
    text: legacyMessage.text,
    isUser: legacyMessage.isUser,
    personaKey: legacyMessage.personaKey,
    personaDisplayName: legacyMessage.personaDisplayName,
  );
  
  // Should not crash and should show fallback icon/color
  expect(chatMessage._getPersonaIcon(), Icons.smart_toy);
});
```

### Integration Tests
```dart
testWidgets('should display correct persona icon for AI messages', (tester) async {
  final message = ChatMessageModel.aiMessage(
    text: 'Test message',
    type: MessageType.text,
    timestamp: DateTime.now(),
    personaKey: 'ariLifeCoach',
    personaDisplayName: 'Ari Life Coach',
  );
  
  await tester.pumpWidget(ChatMessage(
    text: message.text,
    isUser: message.isUser,
    personaKey: message.personaKey,
    personaDisplayName: message.personaDisplayName,
  ));
  
  expect(find.byIcon(Icons.psychology), findsOneWidget);
});
```

### Migration Tests
```dart
test('should migrate legacy messages successfully', () async {
  // Create legacy messages without persona data
  await chatStorage.saveMessage(
    text: 'Legacy AI message',
    isUser: false,
    type: MessageType.text,
  );
  
  // Run migration
  await chatStorage.migrateToPersonaMetadata();
  
  // Verify migration results
  final messages = await chatStorage.getMessages(limit: 1);
  expect(messages.first.personaKey, 'unknown');
  expect(messages.first.personaDisplayName, 'AI Assistant');
});
```

## Error Scenarios

| Scenario | Handling | User Impact |
|----------|----------|-------------|
| Migration fails | Log error, continue with fallbacks | Legacy messages show generic icon |
| Invalid persona key | Store 'unknown' key, log warning | Message shows fallback icon |
| Null persona data | Use fallback values | Graceful degradation |
| Schema update fails | App continues with old schema | New features unavailable |
| Storage permission denied | Show error message, retry | User prompted to fix permissions |

## Acceptance Criteria

### Core Functionality
- [ ] All new AI messages include accurate persona metadata
- [ ] Persona-specific icons and colors display correctly in chat
- [ ] Legacy messages display gracefully with fallback styling
- [ ] Database migration completes without data loss
- [ ] Chat export (FT-048) can identify message personas accurately

### User Experience
- [ ] No visible lag when displaying persona-specific elements
- [ ] Consistent persona styling across all UI components
- [ ] Clear visual distinction between different personas
- [ ] Smooth transition for users with existing message history

### Technical Quality
- [ ] No performance degradation in message loading
- [ ] Database size increase is minimal and acceptable
- [ ] All unit and integration tests pass
- [ ] Code follows existing architectural patterns

### Data Integrity
- [ ] No message loss during migration process
- [ ] Persona metadata is correctly associated with each AI message
- [ ] User messages remain unaffected by changes
- [ ] Concurrent message saving works correctly

## Dependencies

### Internal Dependencies
- **ConfigLoader:** For getting current persona key and display name
- **ChatStorageService:** Core storage service requiring updates
- **ChatMessageModel:** Data model requiring schema changes
- **Isar Database:** Schema migration and field additions

### External Dependencies
- **Isar Package:** Must support schema migration for new fields
- **Flutter Framework:** UI updates for enhanced chat display

## Risks and Mitigation

### Risk: Data Loss During Migration
**Mitigation:** 
- Backup existing database before migration
- Test migration thoroughly with sample data
- Implement rollback mechanism if migration fails

### Risk: Performance Impact
**Mitigation:**
- Index new persona fields for fast queries
- Test with large message histories (10k+ messages)
- Monitor app startup time during migration

### Risk: UI Inconsistency
**Mitigation:**
- Use consistent persona mapping across all components
- Create shared utility functions for persona styling
- Comprehensive UI testing with all persona types

## Future Considerations

1. **Persona Analytics:** Track which personas are used most frequently
2. **Message Search:** Enable searching by persona type
3. **Bulk Persona Updates:** Allow users to update legacy message personas
4. **Persona History:** Show conversation timeline with persona switches
5. **Export Enhancements:** Enable persona-filtered exports

## Related Features

- **FT-048: Chat Export:** Direct dependency requiring persona metadata
- **FT-030: Dynamic Chat Header:** Shared persona display logic
- **Character/Persona Management:** Source of persona configuration data
- **Audio Assistant System:** AI messages with voice responses need persona tracking

---

**Document Version:** 1.0  
**Last Updated:** January 15, 2025  
**Author:** AI Assistant  
**Reviewers:** TBD  
**Dependencies:** Blocks FT-048 (Chat Export)
