# FT-069 Chat Import Restoration Script

**Feature ID**: FT-069  
**Priority**: High  
**Category**: Data Recovery/Script  
**Effort Estimate**: 1-2 hours  
**Dependencies**: FT-048 (Chat Export), ChatStorageService  
**Status**: Specification  

## Overview

Create a standalone Dart script that parses an exported WhatsApp-format chat file and restores the conversation history to the Isar database. This addresses accidental database clearing and provides a recovery mechanism for chat history.

## Problem Statement

The chat message database was accidentally cleared while activity data remained intact. An exported chat file exists that contains the complete conversation history in WhatsApp format. We need to restore this data to the database to recover the lost conversation.

## Functional Requirements

### Script Capabilities
- **FR-069-01**: Parse WhatsApp-format chat export files
- **FR-069-02**: Extract message content, timestamps, and sender information
- **FR-069-03**: Identify user vs AI messages from sender names
- **FR-069-04**: Map AI sender names to persona keys (Ari Life Coach → ariLifeCoach)
- **FR-069-05**: Handle audio attachment references (`<attached: filename.extension>`)
- **FR-069-06**: Restore messages to ChatMessageModel format in Isar database

### Data Processing
- **FR-069-07**: Parse timestamp format `[MM/DD/YY, HH:MM:SS]`
- **FR-069-08**: Convert to DateTime objects for database storage
- **FR-069-09**: Preserve chronological order during import
- **FR-069-10**: Handle special characters and UTF-8 encoding
- **FR-069-11**: Skip malformed or unparseable lines gracefully

### Database Integration
- **FR-069-12**: Connect to same Isar database as main app
- **FR-069-13**: Use existing ChatMessageModel schema
- **FR-069-14**: Batch insert messages for performance
- **FR-069-15**: Avoid duplicate message insertion
- **FR-069-16**: Preserve existing ActivityModel data (don't affect activities)

## Non-Functional Requirements

### Performance
- **NFR-069-01**: Process 1000+ messages within 30 seconds
- **NFR-069-02**: Memory-efficient streaming for large files
- **NFR-069-03**: Progress reporting for long imports

### Reliability
- **NFR-069-04**: Graceful handling of malformed lines
- **NFR-069-05**: Transaction safety (all-or-nothing import)
- **NFR-069-06**: Detailed logging of import process
- **NFR-069-07**: Verification of imported data integrity

## Technical Specifications

### Input Format (WhatsApp Export)
```
[01/15/25, 10:30:45] User: How can I improve my productivity?
[01/15/25, 10:31:12] Ari Life Coach: Great question! Let's start by...
[01/15/25, 10:32:30] User: ‎<attached: user_message.opus>
[01/15/25, 10:33:45] Sergeant Oracle: ‎<attached: ai_response.mp3>
```

### Parsing Logic
```dart
class ChatImportParser {
  static final RegExp messagePattern = RegExp(
    r'^\[(\d{2}/\d{2}/\d{2}), (\d{2}:\d{2}:\d{2})\] ([^:]+): (.*)$'
  );
  
  static MessageParseResult? parseLine(String line);
  static DateTime parseTimestamp(String date, String time);
  static bool isUserMessage(String sender);
  static String? mapPersonaName(String senderName);
  static MessageType detectMessageType(String content);
}
```

### Persona Mapping
```dart
final personaMapping = {
  'Ari Life Coach': 'ariLifeCoach',
  'Ari - Life Coach': 'ariLifeCoach', 
  'Ari 2.1': 'ariWithOracle21',
  'Sergeant Oracle': 'sergeantOracle',
  'I-There': 'iThereClone',
  'AI Assistant': null, // Legacy fallback
};
```

### Database Restoration
```dart
class ChatDatabaseRestorer {
  Future<void> restoreFromFile(String filePath);
  Future<void> clearExistingMessages(); // Optional
  Future<List<ChatMessageModel>> parseMessages(String content);
  Future<void> insertMessages(List<ChatMessageModel> messages);
  Future<void> verifyImport();
}
```

## Implementation Details

### Script Structure
**File**: `scripts/restore_chat.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:character_ai_clone/services/chat_storage_service.dart';
import 'package:character_ai_clone/models/chat_message_model.dart';
import 'package:character_ai_clone/models/message_type.dart';

Future<void> main(List<String> args) async {
  // Validate arguments
  if (args.isEmpty) {
    print('Usage: dart run scripts/restore_chat.dart <export_file_path>');
    return;
  }
  
  final filePath = args[0];
  
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run restoration
  final restorer = ChatDatabaseRestorer();
  await restorer.restoreFromFile(filePath);
}
```

### Parsing Algorithm
1. **Read file line by line** (memory efficient)
2. **Apply regex pattern** to extract components
3. **Parse timestamp** to DateTime
4. **Identify sender type** (User vs AI persona)
5. **Map persona names** to database keys
6. **Detect message type** (text vs audio attachment)
7. **Create ChatMessageModel** with proper fields
8. **Batch insert** to database

### Error Handling
- **Invalid file format**: Clear error message with expected format
- **Malformed timestamps**: Skip line with warning
- **Unknown personas**: Use fallback mapping
- **Database errors**: Rollback transaction
- **File not found**: Clear file path guidance

## Usage Examples

### Command Line Usage
```bash
# Restore from exported file
dart run scripts/restore_chat.dart ~/Downloads/chat_export_2025-08-22_14-34-48.txt

# With verification
dart run scripts/restore_chat.dart ~/Downloads/chat_export.txt --verify

# Clear existing messages first (optional)
dart run scripts/restore_chat.dart ~/Downloads/chat_export.txt --clear-first
```

### Expected Output
```
🔄 Starting chat restoration...
📁 Reading file: chat_export_2025-08-22_14-34-48.txt
📊 File contains 288 lines
🔍 Parsing messages...
   ✅ Parsed 144 user messages
   ✅ Parsed 144 AI messages (5 personas)
   ✅ Found 12 audio attachments
📝 Persona mapping:
   • Ari Life Coach: 89 messages
   • Ari 2.1: 45 messages  
   • Sergeant Oracle: 10 messages
💾 Inserting messages into database...
   ✅ Inserted 288 messages successfully
🔍 Verifying import...
   ✅ Database contains 288 messages
   ✅ Timestamp range: 2025-08-20 to 2025-08-22
   ✅ All personas mapped correctly
✅ Chat restoration complete!
```

## Testing Requirements

### Unit Tests
- Message line parsing accuracy
- Timestamp conversion correctness
- Persona mapping validation
- Message type detection

### Integration Tests
- End-to-end file import process
- Database transaction integrity
- Large file handling performance
- Error recovery scenarios

### Validation Tests
```dart
test('should parse WhatsApp format correctly') {
  final line = '[01/15/25, 10:30:45] Ari Life Coach: Hello there!';
  final result = ChatImportParser.parseLine(line);
  
  expect(result.timestamp, equals(DateTime(2025, 1, 15, 10, 30, 45)));
  expect(result.sender, equals('Ari Life Coach'));
  expect(result.content, equals('Hello there!'));
  expect(result.isUser, equals(false));
}
```

## Acceptance Criteria

### Core Functionality
- [ ] Script successfully parses WhatsApp export format
- [ ] Messages restored with correct timestamps and content
- [ ] User vs AI messages identified correctly
- [ ] Persona names mapped to database keys
- [ ] Audio attachment references preserved
- [ ] No corruption of existing ActivityModel data

### Data Integrity
- [ ] All messages from export file imported
- [ ] Chronological order preserved
- [ ] No duplicate messages created
- [ ] Persona attribution accurate
- [ ] Message types correctly identified

### Error Handling
- [ ] Invalid file formats handled gracefully
- [ ] Malformed lines skipped with warnings
- [ ] Database errors don't corrupt existing data
- [ ] Clear error messages for common issues

### Definition of Done
- [ ] Script completes without errors
- [ ] Chat history visible in app after restoration
- [ ] Message count matches export file
- [ ] All personas display correctly
- [ ] No impact on activity tracking data

## Recovery Strategy

### Immediate Recovery
1. **Run restoration script** with exported chat file
2. **Verify message count** matches original
3. **Test persona switching** to ensure correct attribution
4. **Confirm activities unaffected** (should still have 5 activities)

### Prevention Measures
1. **Remove dangerous scripts** from easy access
2. **Add confirmation prompts** to destructive operations
3. **Implement backup verification** before database operations
4. **Document safe testing procedures**

## Notes

This script serves as both an immediate recovery tool and a future-proofing mechanism. The implementation should prioritize data integrity and provide clear feedback about the restoration process.

The script design follows the existing FT-048 export format exactly, ensuring perfect compatibility between export and import operations.
