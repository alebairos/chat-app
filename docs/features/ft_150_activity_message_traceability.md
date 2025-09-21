# FT-150: Activity Message Traceability

## Overview
Add direct traceability between detected activities and their source chat messages by storing message ID references in ActivityModel.

## Problem Statement
Currently, activities are detected from user messages but lose the connection to their source message, making debugging, user experience, and audit trails difficult.

## Solution
Add `sourceMessageId` field to `ActivityModel` to create a direct link to the originating `ChatMessageModel`.

## Technical Implementation

### Database Schema Changes
```dart
// ActivityModel addition
@Index()
int? sourceMessageId; // Links to ChatMessageModel.id
```

### Detection Pipeline Updates
1. **ChatScreen**: Pass message ID to ClaudeService
2. **ClaudeService**: Forward message ID to activity detection
3. **ActivityMemoryService.logActivity()**: Accept and store `sourceMessageId`
4. **IntegratedMCPProcessor**: Pass message ID through detection chain

### Helper Methods
```dart
// ActivityModel
Future<ChatMessageModel?> getSourceMessage() async { ... }

// ActivityMemoryService  
static Future<List<ActivityModel>> getActivitiesFromMessage(int messageId) async { ... }
```

## Implementation Priority
**Phase 1**: Core traceability (schema + detection pipeline)
**Phase 2**: Helper methods and queries
**Phase 3**: UI integration ("View source message" links)

## Backward Compatibility
- `sourceMessageId` is nullable for existing activities
- No breaking changes to existing APIs
- Graceful handling of deleted source messages

## Success Criteria
- All new activities have `sourceMessageId` populated
- Can query activities by source message
- Can retrieve source message from activity
- Zero performance impact on detection pipeline

## Effort Estimate
**2-3 hours** (schema migration + pipeline updates + basic helpers)
