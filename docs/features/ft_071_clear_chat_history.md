# FT-071 Clear Chat History

**Feature ID**: FT-071  
**Priority**: Medium  
**Category**: Data Management/UI  
**Effort Estimate**: 30 minutes  
**Dependencies**: FT-048 (Export), FT-070 (Import), ChatStorageService  
**Status**: Specification  

## Overview

Add a "Clear Chat History" option to the Chat Management section that removes all chat messages while preserving activity data. This provides users with a clean slate for testing imports and starting fresh conversations while maintaining their valuable FT-064 activity tracking data.

## Problem Statement

Users need an easy way to clear their chat history for:
1. **Testing imports** - Clean slate to verify import functionality works correctly
2. **Fresh start** - Beginning new conversations without losing tracked activities
3. **Development/debugging** - Quick database reset during feature testing

Currently, users have no UI method to clear messages while preserving activities.

## Background

This feature complements the import/export functionality (FT-048, FT-070) by providing the complete data management trilogy:
- **Export** - Save conversation history
- **Import** - Restore conversation history  
- **Clear** - Reset conversation history (while preserving activities)

## Functional Requirements

### Core Functionality
- **FR-071-01**: Add "Clear Chat History" button in Chat Management section
- **FR-071-02**: Clear all ChatMessageModel entries from Isar database
- **FR-071-03**: Preserve all ActivityModel entries (critical for FT-064)
- **FR-071-04**: Clear associated audio files from storage
- **FR-071-05**: Refresh UI to show empty chat state after clearing

### User Safety
- **FR-071-06**: Show confirmation dialog before clearing
- **FR-071-07**: Provide clear explanation of what will be cleared vs preserved
- **FR-071-08**: Allow user to cancel the operation
- **FR-071-09**: Show success confirmation after completion

### UI Integration
- **FR-071-10**: Place after Import button in Chat Management section
- **FR-071-11**: Use orange warning icon to indicate destructive action
- **FR-071-12**: Match existing Card styling and interaction patterns
- **FR-071-13**: Trigger app state refresh after clearing

## Non-Functional Requirements

### Simplicity (Minimalism)
- **NFR-071-01**: Single confirmation dialog - no multi-step process
- **NFR-071-02**: Clear success/error messaging via SnackBar
- **NFR-071-03**: No progress indicators or complex animations

### Correctness
- **NFR-071-04**: Atomic operation - all-or-nothing clearing
- **NFR-071-05**: Verify activity preservation with count check
- **NFR-071-06**: Proper error handling with user feedback
- **NFR-071-07**: Complete audio file cleanup to free storage

### User-Centricity
- **NFR-071-08**: Clear explanation of what's preserved vs deleted
- **NFR-071-09**: Immediate visual feedback in chat interface
- **NFR-071-10**: Intuitive placement in logical workflow sequence

## User Stories

### US-071-001: Clear for Fresh Start
**As a** user who wants to start fresh conversations  
**I want to** clear my chat history while keeping my activity tracking data  
**So that** I can begin new conversations without losing my productivity insights  

**Acceptance Criteria:**
- Clear button is easily discoverable in Chat Management
- Confirmation dialog explains what will be deleted vs preserved
- All messages are removed but activities remain intact
- Chat interface shows empty state after clearing

### US-071-002: Clear for Import Testing  
**As a** developer testing the import functionality  
**I want to** quickly clear existing messages before importing  
**So that** I can verify import results without interference from existing data  

**Acceptance Criteria:**
- Clear operation completes in under 2 seconds
- All message and audio data is completely removed
- Activity data remains untouched for FT-064 testing
- UI refreshes automatically to show cleared state

## Technical Implementation

### UI Integration
**Location**: `lib/screens/character_selection_screen.dart`  
**Section**: `_buildChatManagementSection()` after Import Card  

```dart
// Clear Chat History option
Card(
  child: ListTile(
    leading: const Icon(Icons.delete_outline, color: Colors.orange),
    title: const Text('Clear Chat History'),
    subtitle: const Text('Remove all messages (keeps activity data)'),
    trailing: const Icon(Icons.chevron_right),
    onTap: _clearChatHistory,
  ),
),
```

### Confirmation Dialog
```dart
Future<bool?> _showClearConfirmation() async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear Chat History'),
      content: const Text(
        'This will remove all messages but keep your activity data. Continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
}
```

### Clear Implementation
```dart
Future<void> _clearChatHistory() async {
  // 1. Show confirmation
  final confirm = await _showClearConfirmation();
  if (confirm != true) return;
  
  try {
    // 2. Clear database and audio files
    final chatStorage = ChatStorageService();
    final isar = await chatStorage.db;
    
    // Preserve activity count for verification
    final activityCount = await isar.activityModels.count();
    
    // Clear messages and audio files
    await isar.writeTxn(() async {
      await isar.chatMessageModels.clear();
    });
    await _clearAudioFiles();
    
    // Verify activities preserved
    final finalActivityCount = await isar.activityModels.count();
    if (finalActivityCount != activityCount) {
      throw Exception('Activities were not preserved during clear');
    }
    
    // 3. Refresh UI and show success
    widget.onCharacterSelected();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Chat history cleared (activity data preserved)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    // 4. Show error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Clear failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### Audio File Cleanup
```dart
Future<void> _clearAudioFiles() async {
  // Clear audio files to free storage space
  // Implementation will use existing audio directory service
}
```

## Dependencies

### Required Services
- **ChatStorageService**: Database operations
- **Audio file management**: File system cleanup (existing service)
- **UI refresh mechanism**: `widget.onCharacterSelected()`

### Required Imports
```dart
// Already present in character_selection_screen.dart:
import '../services/chat_storage_service.dart';
import '../models/activity_model.dart';
// No new dependencies needed
```

## Testing Requirements

### Unit Tests
- Confirmation dialog display and interaction
- Activity preservation verification
- Error handling scenarios
- Audio file cleanup verification

### Integration Tests
- Full clear operation workflow
- UI state refresh after clearing
- Combination with import/export operations

### Manual Testing
- Clear operation in various chat states (empty, full, mixed)
- Activity data verification before/after
- Audio file cleanup verification
- UI responsiveness and feedback

## Acceptance Criteria

### Core Functionality
- [ ] Clear button appears in Chat Management after Import
- [ ] Confirmation dialog explains what's preserved vs deleted
- [ ] All ChatMessageModel entries removed from database
- [ ] All ActivityModel entries preserved
- [ ] Audio files cleared from storage
- [ ] UI refreshes to show empty chat state

### User Experience
- [ ] Orange warning icon indicates destructive action
- [ ] Clear explanation in subtitle text
- [ ] Immediate feedback via SnackBar
- [ ] Cancel option works correctly
- [ ] No loading states or complex animations

### Error Handling
- [ ] Activity preservation failure throws error
- [ ] Database errors show user-friendly messages
- [ ] UI remains stable if operation fails

## Success Metrics

### Performance
- **Clear operation**: < 2 seconds completion time
- **Audio cleanup**: Complete file removal
- **UI refresh**: Immediate visual feedback

### Reliability
- **Activity preservation**: 100% success rate
- **Error recovery**: Graceful failure handling
- **User feedback**: Clear success/error messaging

## Notes

### Design Principles Applied
- **Minimalism**: Single confirmation, simple feedback
- **Correctness**: Activity preservation verification, atomic operations
- **User-Centricity**: Clear explanations, immediate feedback, cancel option

### Workflow Integration
This completes the data management trilogy:
1. **Export** → Save your conversations
2. **Import** → Restore conversations  
3. **Clear** → Start fresh (keep activities)

Perfect for development, testing, and user workflow needs.

### Future Considerations
- Could add "Clear Activities Only" option if needed
- Could add selective clearing (date ranges, personas)
- Not needed for initial implementation - keep it simple

---

**Feature Specification Complete**  
**Ready for Implementation**: Yes  
**Estimated Implementation Time**: 30 minutes
