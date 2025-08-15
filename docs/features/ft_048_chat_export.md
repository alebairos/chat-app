# Feature Specification: Chat History Export

## Overview

This feature specification outlines the implementation of chat history export functionality that allows users to download and export their conversation history in WhatsApp-compatible format.

## Feature Summary

**Feature ID:** FT-048  
**Priority:** Medium  
**Category:** Data Management  
**Estimated Effort:** 3-5 days  

### User Story
> As a user, I want to export my chat history so that I can backup my conversations, share them, or analyze them outside the app.

## Requirements

### Functional Requirements

#### FR-001: Export Button Integration
- **Location:** Add export functionality to the existing settings menu
- **Access:** Via settings icon in main app bar → Settings screen → "Export Chat History" option
- **Behavior:** Tapping the export option should trigger the export process

#### FR-002: WhatsApp-Compatible Format
The exported file must follow the exact WhatsApp chat export format as demonstrated in `/docs/daymi/_chat.txt`:

**Format Specification:**
```
[MM/DD/YY, HH:MM:SS] Sender Name: Message content
‎[MM/DD/YY, HH:MM:SS] Sender Name: ‎<attached: filename.extension>
```

**Format Rules:**
- Date format: `[MM/DD/YY, HH:MM:SS]` (e.g., `[08/08/25, 16:33:51]`)
- User messages: Use actual user name or "User"
- AI messages: Use the current active persona display name
- Media attachments: Use `‎<attached: filename.extension>` format
- Text messages: Display full message content
- Line numbers: Each line should be numbered (optional, for large exports)

#### FR-003: Export Content Scope
- **All Messages:** Export complete conversation history
- **Date Range:** Future enhancement - allow date range selection
- **Message Types:** Handle all message types (text, audio, image)
- **Chronological Order:** Messages exported in chronological order (oldest first)

#### FR-004: File Generation
- **Format:** Plain text file (.txt)
- **Naming:** `chat_export_YYYY-MM-DD_HH-MM-SS.txt`
- **Character Encoding:** UTF-8 to support international characters
- **File Size:** Handle large chat histories efficiently

#### FR-005: Export Delivery
- **Method:** Use platform's native sharing mechanism
- **Options:** 
  - Save to device storage
  - Share via email
  - Share via messaging apps
  - Share via cloud storage services
- **User Control:** Let user choose how to handle the exported file

### Non-Functional Requirements

#### NFR-001: Performance
- Export process should not block the UI
- Show progress indicator for large exports (>1000 messages)
- Complete export within 30 seconds for 10,000 messages

#### NFR-002: Memory Management
- Stream processing for large chat histories
- Avoid loading all messages into memory simultaneously
- Implement pagination for database queries

#### NFR-003: Error Handling
- Handle corrupted or missing media files gracefully
- Provide meaningful error messages to users
- Log export failures for debugging

#### NFR-004: Privacy & Security
- No data transmitted to external servers during export
- Export process happens entirely on device
- User controls where exported data is shared

## Technical Implementation

### Data Model Integration

**Current Data Structure:**
```dart
class ChatMessageModel {
  Id id;
  DateTime timestamp;
  String text;
  bool isUser;
  MessageType type; // text, audio, image
  List<byte>? mediaData;
  String? mediaPath;
  int? durationInMillis;
}
```

### Critical Issue: Persona Tracking

**Problem Identified:**
The current `ChatMessageModel` does **not** track which persona wrote each AI message. This creates a significant issue for export functionality because:

1. AI messages are saved without persona information (lines 484-497 in `chat_screen.dart`)
2. When users switch between personas (Ari, Sergeant Oracle, I-There), historical messages don't retain which persona created them
3. Export would incorrectly attribute all AI messages to the currently active persona

**Required Data Model Update:**
```dart
class ChatMessageModel {
  Id id;
  DateTime timestamp;
  String text;
  bool isUser;
  MessageType type;
  List<byte>? mediaData;
  String? mediaPath;
  int? durationInMillis;
  
  // NEW FIELD REQUIRED:
  String? personaKey;        // Store persona key (e.g., 'ariLifeCoach', 'iThereClone')
  String? personaDisplayName; // Store display name for export consistency
}
```

### Export Service Architecture

#### ExportService Class
```dart
class ChatExportService {
  Future<String> exportChatHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async;
  
  String _formatMessage(ChatMessageModel message);
  String _formatTimestamp(DateTime timestamp);
  String _formatMediaAttachment(ChatMessageModel message);
  String _getPersonaDisplayName(ChatMessageModel message);
  Future<void> _shareExportedFile(String filePath);
}
```

#### Persona Resolution Strategy
Since existing messages lack persona information, the export service will need to handle:

1. **New Messages:** Use stored `personaDisplayName` field
2. **Legacy Messages:** Apply fallback logic:
   - Use current active persona for recent messages (unsafe assumption)
   - Display as "AI Assistant" for messages without persona data
   - **Recommended:** Prompt user about data migration before export

#### Integration Points

1. **Settings Screen Enhancement:**
   - Add new settings screen or enhance character selection screen
   - Include "Export Chat History" option
   - Add appropriate icons and descriptions

2. **Main App Integration:**
   - Modify settings icon behavior to navigate to comprehensive settings
   - Add export service to dependency injection

### Message Format Mapping

| Message Type | Export Format | Sender Resolution |
|--------------|---------------|-------------------|
| Text (User) | `[MM/DD/YY, HH:MM:SS] User: Message content` | Always "User" |
| Text (AI) | `[MM/DD/YY, HH:MM:SS] Ari Life Coach: Message content` | From `personaDisplayName` or fallback |
| Audio (User) | `‎[MM/DD/YY, HH:MM:SS] User: ‎<attached: audio_XXXXX.opus>` | Always "User" |
| Audio (AI) | `‎[MM/DD/YY, HH:MM:SS] I-There: ‎<attached: audio_XXXXX.mp3>` | From `personaDisplayName` or fallback |
| Image | `‎[MM/DD/YY, HH:MM:SS] Sender: ‎<attached: image_XXXXX.jpg>` | Based on `isUser` flag |

**Persona Name Resolution Priority:**
1. `message.personaDisplayName` (for new messages with persona tracking)
2. Current active persona (fallback for recent legacy messages)
3. "AI Assistant" (fallback for old messages without clear persona context)

### Error Scenarios

| Scenario | Handling |
|----------|----------|
| No messages to export | Show user-friendly message |
| Corrupted media file | Show `<attached: [corrupted_file]>` |
| Database access error | Show error dialog with retry option |
| Storage permission denied | Request permissions or show guidance |
| Large export timeout | Break into chunks or show progress |

## User Experience Flow

### Happy Path
1. User taps settings icon in main app bar
2. User navigates to settings screen (new or enhanced)
3. User taps "Export Chat History" option
4. App shows progress indicator while generating export
5. App presents sharing options to user
6. User selects preferred sharing method
7. Export file is shared/saved successfully
8. User receives confirmation message

### Error Flows
- **No messages:** "No chat history to export" message
- **Permission denied:** Guide user to grant storage permissions
- **Export failed:** "Export failed. Please try again." with retry option

## Implementation Phases

### Phase 0: Data Model Migration (REQUIRED FIRST)
- [ ] Add `personaKey` and `personaDisplayName` fields to `ChatMessageModel`
- [ ] Update Isar schema and handle database migration
- [ ] Modify message saving logic in `chat_screen.dart` to include persona info
- [ ] Update `ChatStorageService.saveMessage()` to accept persona parameters
- [ ] Test persona tracking with new messages

### Phase 1: Core Export Functionality
- [ ] Create ChatExportService class
- [ ] Implement WhatsApp format conversion with persona name resolution
- [ ] Add basic export to file system
- [ ] Handle text messages only
- [ ] Implement legacy message fallback logic

### Phase 2: Media and UI Integration
- [ ] Handle audio and image message exports
- [ ] Create/enhance settings screen UI
- [ ] Add export button and navigation
- [ ] Implement progress indicators

### Phase 3: Sharing and Polish
- [ ] Integrate platform sharing capabilities
- [ ] Add error handling and user feedback
- [ ] Performance optimization for large exports
- [ ] Testing and bug fixes

### Phase 4: Future Enhancements
- [ ] Date range selection
- [ ] Export format options (JSON, CSV)
- [ ] Selective message export
- [ ] Cloud backup integration
- [ ] Data migration tool for legacy messages

## Dependencies

### Flutter Packages
- `share_plus`: For native sharing functionality
- `path_provider`: For file system access
- `permission_handler`: For storage permissions (if needed)

### Internal Dependencies
- `ChatStorageService`: For retrieving chat messages
- `ConfigLoader`: For getting persona display names
- Existing navigation and UI components

## Testing Strategy

### Unit Tests
- `ChatExportService` functionality
- Message formatting methods
- Error handling scenarios
- Date/time formatting

### Integration Tests
- End-to-end export flow
- Database query performance
- File generation and sharing
- Large dataset handling

### UI Tests
- Settings screen navigation
- Export button interaction
- Progress indicator behavior
- Error dialog presentation

## Security Considerations

1. **Data Privacy:** Exported files contain personal conversation data
2. **Storage Security:** Files saved to device storage are accessible by user
3. **Sharing Control:** User controls where and how data is shared
4. **No Cloud Processing:** All processing happens on-device

## Acceptance Criteria

### Core Functionality
- [ ] Export button accessible from settings
- [ ] Generated file follows exact WhatsApp format
- [ ] All message types handled correctly
- [ ] Chronological message ordering
- [ ] Proper timestamp formatting
- [ ] **Persona names displayed correctly for all messages**
- [ ] **Legacy messages handle persona attribution gracefully**
- [ ] **New messages always include accurate persona information**

### User Experience
- [ ] Intuitive navigation to export feature
- [ ] Clear progress feedback during export
- [ ] Native sharing options available
- [ ] Appropriate error messages
- [ ] No app crashes during export

### Performance
- [ ] Export completes within reasonable time
- [ ] No memory issues with large datasets
- [ ] UI remains responsive during export
- [ ] Progress indicator for long operations

### Quality
- [ ] UTF-8 encoding for international characters
- [ ] Proper handling of special characters
- [ ] Consistent date/time formatting
- [ ] Clean, readable output format

## Related Features

- **Character/Persona Management:** Export includes accurate persona names from stored data
- **Chat Storage Service:** Core dependency for message retrieval and persona data
- **Audio Message System:** Audio files included in export
- **Image Message System:** Image files included in export
- **FT-TBD: Persona Message Tracking:** New feature required to track persona info per message

## Blockers and Dependencies

### Critical Blocker: Persona Tracking
**This export feature cannot be properly implemented without first solving the persona tracking issue.**

**Current State:** AI messages are saved without persona information, making it impossible to accurately export conversations with correct persona attribution.

**Required Prerequisite:**
- Implement persona tracking in message storage (suggested as FT-049: Persona Message Tracking)
- This blocker affects the core functionality and user experience of the export feature

**Impact:** Without persona tracking, exported chats would incorrectly attribute all AI messages to the currently active persona, potentially confusing users who have used multiple personas throughout their conversation history.

## Future Considerations

1. **Advanced Filtering:** Export specific conversations or date ranges
2. **Multiple Formats:** JSON, CSV, or other structured formats
3. **Cloud Integration:** Direct export to cloud storage services
4. **Scheduled Exports:** Automatic periodic backups
5. **Import Functionality:** Import conversations from other apps
6. **Analytics:** Export usage tracking and optimization

---

**Document Version:** 1.0  
**Last Updated:** January 15, 2025  
**Author:** AI Assistant  
**Reviewers:** TBD
