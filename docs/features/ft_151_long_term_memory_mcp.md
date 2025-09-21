# FT-151: Long-Term Memory MCP Functions

## Overview
Add MCP functions that leverage FT-150's `sourceMessageId` traceability to provide LLM with conversation-activity memory and pattern recognition capabilities.

## Dependencies
- **FT-150**: Activity Message Traceability (required)
- Existing MCP infrastructure in `SystemMCPService`
- Existing `ChatStorageService` and `ActivityMemoryService`

## Problem Statement
Current MCP functions provide data without context. LLM cannot reference specific conversations that led to activities or identify behavioral patterns, limiting conversational continuity and personalization.

## Solution
Add 5 focused MCP functions that transform FT-150's traceability into actionable memory intelligence.

## MCP Functions

### 1. `get_activity_source`
**Purpose**: Find conversation that triggered specific activity  
**Parameters**: `activity_id` (int)  
**Returns**: Activity details + source message + time correlation  
**Usage**: *"That workout came from when you said 'feeling sluggish' 2 hours ago"*

### 2. `get_message_activities` 
**Purpose**: Find activities triggered by specific message  
**Parameters**: `message_id` (int)  
**Returns**: Message details + triggered activities + success rate  
**Usage**: *"That message triggered 3 activities: exercise, hydration, meditation"*

### 3. `get_conversation_patterns`
**Purpose**: Analyze conversation → activity correlations  
**Parameters**: `days` (int, default 7), `min_occurrences` (int, default 2)  
**Returns**: Keyword-activity patterns with examples and frequency  
**Usage**: *"You tend to exercise after mentioning 'energy' (5 times) or 'tired' (4 times)"*

### 4. `get_activity_stats_enhanced`
**Purpose**: Enhanced activity stats with conversation context  
**Parameters**: `days` (int, default 0), `include_context` (bool, default true)  
**Returns**: Standard stats + source message previews + timing analysis  
**Usage**: *"Today's 5 activities came from 3 conversations. Your 'tired' message led to exercise + hydration"*

### 5. `search_conversations_by_activity`
**Purpose**: Reverse search - find conversations by activity type  
**Parameters**: `activity_type` (string), `dimension` (string), `days` (int, default 7)  
**Returns**: Conversations that led to specific activity types  
**Usage**: *"Your exercise activities usually come from conversations about 'motivation' or 'energy'"*

## Technical Implementation

### Integration Point
Add cases to existing `SystemMCPService.processCommand()` switch statement.

### Data Flow
```
LLM Request → MCP Function → ActivityMemoryService + ChatStorageService → Correlated Data → JSON Response
```

### Helper Methods
- `_extractKeywords()`: Simple keyword extraction from messages
- `_calculateTimeBetween()`: Time correlation between message and activity
- `_formatTimeAgo()`: Human-readable time differences

### System Prompt Enhancement
Update MCP documentation to include new functions and usage patterns.

## Success Criteria
- LLM can reference specific past conversations naturally
- LLM identifies and mentions behavioral patterns
- Conversation continuity improves with contextual references
- Zero performance impact on existing MCP functions

## Constraints
- **Scope**: Only leverage existing FT-150 data, no new storage
- **Performance**: Limit queries to recent data (max 100 activities)
- **Privacy**: No sensitive data exposure beyond existing chat/activity access

## Effort Estimate
**3 hours** (5 MCP functions + system prompt updates + helper methods)

## Future Enhancements (Out of Scope)
- Advanced pattern recognition algorithms
- Predictive recommendations
- Conversation sentiment analysis
- Multi-dimensional correlation analysis
