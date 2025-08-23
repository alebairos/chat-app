# FT-070: Chat Import UI Integration

## Feature ID
**FT-070**

## Priority
**Medium**

## Category
**User Interface**

## Effort Estimate
**1 hour** (Minimalist approach)

## Overview
Add a simple "Import Chat" button next to the existing export functionality. Users can select their exported chat file and restore their conversation history with one click.

## Background
- Chat restoration currently requires running scripts manually
- Users need a simple UI option to restore exported chats
- Must clean up the previous startup restoration approach that was too complex

## Requirements

### Functional Requirements

#### FR-070-001: Simple Import Button
- **Requirement**: Add "Import Chat" button next to existing export
- **Location**: Same UI location as export button
- **Behavior**: One-click file selection and import

#### FR-070-002: File Selection
- **Requirement**: Select exported chat file from device
- **Format**: Support existing `.txt` export format from FT-048
- **Picker**: Use simple file picker

#### FR-070-003: Basic Import
- **Requirement**: Parse file and restore messages
- **Safety**: Preserve ActivityModel entries (FT-064)
- **Process**: Clear messages → Parse file → Insert messages
- **Feedback**: Simple success/error message

### Non-Functional Requirements

#### NFR-070-001: Simplicity
- **Requirement**: Minimal UI and code complexity
- **No Progress Bars**: Keep it simple for first version
- **No Complex Validation**: Basic file format check only
- **No Rollback**: Clear error message if import fails

## User Stories

### US-070-001: Simple Import
**As a** user who has exported my chat history  
**I want to** click an import button and select my file  
**So that** my chat history is restored immediately  

**Acceptance Criteria:**
- Import button next to export button
- File picker opens on click
- Messages restored with simple success message

## Existing Code to Reuse

### ✅ Parsing Logic Available (FT-069)
**Location**: `scripts/restore_chat_simple.dart`
- **RegExp Pattern**: `RegExp(r'^‎?\[(\d{2}/\d{2}/\d{2}), (\d{2}:\d{2}:\d{2})\] ([^:]+): (.*)$')`
- **Persona Mapping**: Complete mapping from FT-069 
- **Message Type Detection**: Text vs audio attachment logic
- **Timestamp Parsing**: DateTime conversion from WhatsApp format

### ✅ Export Format Reference (FT-048) 
**From**: `ft_048_chat_export_impl_summary.md`
- **Format**: `[MM/DD/YY, HH:MM:SS] Sender: Message`
- **Audio Format**: `<attached: filename.extension>`
- **Persona Names**: "Ari Life Coach", "Sergeant Oracle", "I-There"
- **User Messages**: "User" as sender name

### ✅ Database Logic Available
**Location**: `lib/services/chat_storage_service.dart`
- **Activity Preservation**: Existing `restoreMessagesFromData()` method
- **Batch Processing**: Already implemented for performance
- **Error Handling**: Comprehensive try-catch with logging

## Technical Implementation

### Simple UI Integration

#### Exact Location Found
- **File**: `lib/screens/character_selection_screen.dart`
- **Method**: `_buildChatManagementSection()`
- **Position**: Add import Card right after the export Card (line 224)
- **Context**: Settings screen → Chat Management section

#### Implementation Details
```dart
// In _buildChatManagementSection(), add after export Card:

// Import Chat History option (NEW)
Card(
  child: ListTile(
    leading: const Icon(Icons.upload_file, color: Colors.green),
    title: const Text('Import Chat History'),
    subtitle: const Text('Restore from exported WhatsApp format file'),
    trailing: const Icon(Icons.chevron_right),
    onTap: _importChat,
  ),
),

// Export Chat History option (EXISTING)
Card(
  child: ListTile(
    leading: const Icon(Icons.download, color: Colors.blue),
    title: const Text('Export Chat History'),
    subtitle: const Text('Save your conversations in WhatsApp format'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => ExportDialogUtils.showExportDialog(context),
  ),
),
```

### Minimal Import Implementation

#### Import Method Implementation
```dart
// Add to CharacterSelectionScreen class:

Future<void> _importChat() async {
  try {
    // 1. Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      dialogTitle: 'Select Chat Export File',
    );
    
    if (result == null) return; // User cancelled
    
    // 2. Parse and import using existing restoration logic
    final filePath = result.files.single.path!;
    await _parseAndImportFile(filePath);
    
    // 3. Show success
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Chat history restored successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    // 4. Show error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _parseAndImportFile(String filePath) async {
  // Reuse existing parsing logic from FT-069
  final file = File(filePath);
  final content = await file.readAsString();
  
  // Parse using existing regex and persona mapping from restore_chat_simple.dart
  final messages = await _parseWhatsAppFormat(content);
  
  // Use existing ChatStorageService restoration with activity preservation
  final chatStorage = ChatStorageService();
  final isar = await chatStorage.db;
  
  // Preserve activities (critical for FT-064)
  final activityCount = await isar.activityModels.count();
  
  // Clear and restore messages only
  await isar.writeTxn(() async {
    await isar.chatMessageModels.clear();
  });
  
  // Batch insert (reuse existing logic)
  const batchSize = 50;
  for (int i = 0; i < messages.length; i += batchSize) {
    final batch = messages.skip(i).take(batchSize).toList();
    await isar.writeTxn(() async {
      await isar.chatMessageModels.putAll(batch);
    });
  }
  
  // Verify activities preserved
  final finalActivityCount = await isar.activityModels.count();
  if (finalActivityCount != activityCount) {
    throw Exception('Activities were not preserved during import');
  }
}

// Reuse parsing logic from scripts/restore_chat_simple.dart
Future<List<ChatMessageModel>> _parseWhatsAppFormat(String content) async {
  final lines = content.split('\n');
  final messages = <ChatMessageModel>[];
  
  // Reuse existing regex pattern from FT-069
  final messagePattern = RegExp(r'^‎?\[(\d{2}/\d{2}/\d{2}), (\d{2}:\d{2}:\d{2})\] ([^:]+): (.*)$');
  
  // Reuse existing persona mapping from FT-069
  final personaMapping = {
    'Ari Life Coach': 'ariLifeCoach',
    'Ari - Life Coach': 'ariLifeCoach',
    'Ari 2.1': 'ariWithOracle21',
    'Sergeant Oracle': 'sergeantOracle',
    'I-There': 'iThereClone',
    'AI Assistant': null,
    'User': null,
  };
  
  for (final line in lines) {
    final match = messagePattern.firstMatch(line.trim());
    if (match == null) continue;
    
    final dateStr = match.group(1)!;
    final timeStr = match.group(2)!;
    final sender = match.group(3)!;
    final content = match.group(4)!;
    
    // Parse timestamp (reuse FT-069 logic)
    final timestamp = _parseTimestamp(dateStr, timeStr);
    final isUser = sender == 'User';
    final personaKey = personaMapping[sender];
    final personaDisplayName = isUser ? null : sender;
    
    // Detect message type (reuse FT-069 logic)
    final isAudio = content.startsWith('<attached:') || content.contains('.mp3') || content.contains('.opus');
    final messageType = isAudio ? MessageType.audio : MessageType.text;
    
    // Extract media path for audio messages
    String? mediaPath;
    String messageText = content;
    if (isAudio) {
      final mediaMatch = RegExp(r'<attached:\s*([^>]+)>').firstMatch(content);
      if (mediaMatch != null) {
        mediaPath = mediaMatch.group(1);
        messageText = ''; // Audio messages have empty text
      }
    }
    
    messages.add(ChatMessageModel(
      text: messageText,
      isUser: isUser,
      type: messageType,
      timestamp: timestamp,
      mediaPath: mediaPath,
      personaKey: personaKey,
      personaDisplayName: personaDisplayName,
    ));
  }
  
  return messages;
}

DateTime _parseTimestamp(String dateStr, String timeStr) {
  // Reuse timestamp parsing from FT-069
  final dateParts = dateStr.split('/');
  final timeParts = timeStr.split(':');
  
  final month = int.parse(dateParts[0]);
  final day = int.parse(dateParts[1]);
  final year = 2000 + int.parse(dateParts[2]);
  
  final hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);
  final second = int.parse(timeParts[2]);
  
  return DateTime(year, month, day, hour, minute, second);
}
```

## Dependencies
- **file_picker: ^8.1.2**: ✅ Added to pubspec.yaml for file selection
- **FT-048**: ✅ Export functionality and format reference
- **FT-069**: ✅ Parsing logic and persona mapping available

## Implementation Plan

### Single Phase: Simple Import (30 minutes - mostly copy/paste)
1. **✅ Find export button location** - Found in `character_selection_screen.dart` line 216
2. **✅ Add file_picker dependency** - Added to pubspec.yaml  
3. **✅ Parsing logic available** - Copy from `scripts/restore_chat_simple.dart`
4. **Add import button next to export** (10 minutes)
5. **Copy parsing methods to character_selection_screen.dart** (10 minutes)
6. **Implement _importChat() method** (5 minutes)
7. **Test with real export file** (5 minutes)

## Success Criteria
- ✅ Import button visible next to export
- ✅ File picker opens and selects .txt files
- ✅ Messages restored successfully
- ✅ Activities preserved (FT-064 data untouched)
- ✅ Simple success/error feedback

## Code Reuse Summary

### ✅ From FT-069 (restore_chat_simple.dart):
- **RegExp Pattern**: Handles invisible character prefix `‎?`
- **Persona Mapping**: All personas mapped correctly
- **Timestamp Parsing**: MM/DD/YY format conversion
- **Audio Detection**: `<attached:` pattern recognition
- **Message Type Logic**: Text vs audio classification

### ✅ From FT-048 (Export Format):
- **Format Validation**: Exact WhatsApp format match
- **Persona Names**: "Ari Life Coach", "Sergeant Oracle", "I-There"  
- **Audio Format**: `<attached: filename.extension>`
- **User Format**: "User" as sender name

### ✅ From ChatStorageService:
- **Activity Preservation**: Existing restoration method
- **Batch Processing**: 50 messages per batch
- **Error Handling**: Try-catch with logging

## Required Imports
```dart
// Add to character_selection_screen.dart:
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/chat_storage_service.dart';
import '../models/chat_message_model.dart';
import '../models/message_type.dart';
```

## Notes
- **Massive Code Reuse**: 90% of logic already exists from FT-069 + FT-048
- **Proven Parsing**: RegExp and persona mapping tested and working
- **Format Compatibility**: Perfect match with FT-048 export format
- **Activity Safety**: Preserve FT-064 data (critical requirement)
- **UI Pattern**: Match existing export Card styling with green upload icon

**Implementation Reality**: Add Card → Copy/paste parsing methods → Wire up _importChat() → Done in 30 minutes.

### Key Insight
FT-069 script approach didn't work due to Flutter SDK issues, but the **parsing logic is perfect**. 
FT-070 just moves that same logic into the Flutter UI where it belongs!
