# FT-160: Message Timestamps Display

**Feature ID**: FT-160  
**Priority**: Low  
**Category**: UX Enhancement  
**Effort**: 1 hour  

## Overview

Add Discord-style timestamps to chat messages for better conversation context and debugging capabilities.

## Current State

Messages are displayed without any timestamp information, making it difficult for users to understand conversation timing and context.

## Proposed Solution

Display timestamps below each message using Discord-style format: `YYYY/MM/DD, HH:MM`

### Visual Design
```
┌─────────────────────────────┐
│ How's your day going?       │
└─────────────────────────────┘
2025/09/29, 13:00

┌─────────────────────────────┐
│ I'm doing great, thanks!    │
└─────────────────────────────┘
2025/09/29, 13:01
```

## Functional Requirements

### FR-160.1: Timestamp Display
- Display timestamp below each message bubble
- Format: `YYYY/MM/DD, HH:MM` (24-hour format)
- Style: 11px font, gray color, left-aligned
- Spacing: 4px padding from message bubble

### FR-160.2: Data Integration
- Use existing `ChatMessageModel.timestamp` field
- Pass timestamp from `_createChatMessage` to `ChatMessage` widget
- No database changes required

## Non-Functional Requirements

### NFR-160.1: Performance
- No impact on message rendering performance
- Timestamp formatting should be lightweight

### NFR-160.2: Consistency
- Same format for all messages regardless of age
- Consistent with system's enhanced date format for AI context

## Technical Implementation

### Files to Modify
1. `lib/widgets/chat_message.dart` - Add timestamp parameter and display
2. `lib/screens/chat_screen.dart` - Pass timestamp in `_createChatMessage`

### Dependencies
- `intl` package (already included in project)

## Acceptance Criteria

- [ ] All chat messages display timestamps in `YYYY/MM/DD, HH:MM` format
- [ ] Timestamps are visually consistent and non-intrusive
- [ ] No performance impact on message rendering
- [ ] Timestamps match database stored values
- [ ] Works for both user and AI messages
- [ ] Works for both text and audio messages

## Out of Scope

- Relative time formatting (e.g., "2 minutes ago")
- Timestamp grouping or hiding for consecutive messages
- Timezone conversion or display
- Timestamp editing or modification

## Risk Assessment

**Low Risk**: Simple UI enhancement using existing data with no complex logic or external dependencies.
