# Changelog

All notable changes to this project will be documented in this file.

## [1.9.0] - 2025-09-29

### Added
- **FT-163**: Activity Queue Storage Fix
  - Fixed critical bug where Activity Queue System detected activities but never saved them to database
  - Completed FT-154 implementation by replacing logging-only code with actual database saves
  - Added proper ActivityMemoryService.logActivity() integration for queued activities
  - Enhanced error handling and Oracle activity validation in queue processing
  - Implemented comprehensive testing with manual test utilities

- **FT-162**: Clear Messages and Activities
  - Added "Clear Messages and Activities" shortcut button for complete database reset
  - Combines FT-071 (Clear Chat History) and FT-161 (Delete Activities) in single action
  - Provides comprehensive confirmation dialog explaining full scope of operation
  - Implements atomic behavior - both operations succeed or both fail with rollback
  - No code duplication - leverages existing clear methods

- **FT-161**: Delete Activities
  - Added "Clear Activity Data" functionality for granular data management
  - Enables selective deletion of activity tracking data while preserving chat messages
  - Provides independent control over activity history vs chat history
  - Includes comprehensive confirmation dialogs following FT-071 patterns
  - Auto-updates UI stats to reflect empty state after clearing

### Fixed
- Critical data loss bug in Activity Queue System during rate limit scenarios
- 100% activity detection loss where activities were detected but never persisted
- Incomplete TODO implementation in ActivityQueue._processActivityDetection()

### Enhanced
- Data management capabilities with granular control options
- User experience with convenient single-action database clearing
- Activity queue reliability with proper database persistence
- Testing workflows with clean database state preparation

### Technical
- Enhanced ActivityQueue with proper ActivityMemoryService integration
- Added comprehensive error handling in queue processing workflow
- Implemented atomic operations for combined data clearing
- Added manual testing utilities for activity queue validation

## [1.8.0] - 2025-09-29

### Added
- **FT-160**: Message Timestamps Display
  - Added Discord-style timestamps below each chat message
  - Format: `YYYY/MM/DD, HH:MM` (24-hour format) for better conversation context
  - Lightweight implementation using existing `ChatMessageModel.timestamp` field
  - Consistent styling: 11px font, gray color, left-aligned with 4px padding
  - Works for both user and AI messages, text and audio messages

### Enhanced
- Chat conversation context with visible message timing
- Debugging capabilities for conversation flow analysis
- User experience with better temporal awareness in chat history

### Technical
- Modified `lib/widgets/chat_message.dart` to display timestamps
- Updated `lib/screens/chat_screen.dart` to pass timestamp data
- Zero performance impact on message rendering
- Utilizes existing `intl` package for date formatting

## [1.7.1] - 2025-09-29

### Added
- **FT-159**: Proactive MCP Memory Retrieval Implementation
  - Enhanced MCP base configuration with proactive memory triggers
  - Added automatic memory retrieval for user queries about past conversations
  - Implemented trigger patterns for "lembra do plano", "remember the plan", "what did we discuss"
  - Increased conversation context limit from 50 to 200 messages
  - Added configurable full text option for comprehensive message retrieval
  - Enhanced cross-persona memory continuity

### Fixed
- Memory failures where AI couldn't access past conversations beyond recent context
- Date hallucination issues in temporal context processing
- Test failures and disabled hanging FT-150 test for stability
- Enhanced time context processing to ensure full date inclusion

### Enhanced
- Proactive memory retrieval eliminates "não consigo ver nas nossas conversas recentes" responses
- Unlimited historical access via enhanced `get_conversation_context` function
- Seamless persona switching with full conversation context
- Bulletproof memory system with zero gaps in conversation history

## [1.7.0] - 2025-09-28

### Added
- **FT-157**: Hybrid Temporal Awareness & Complete Coaching Memory Foundation
  - Fixed critical Claude API error: "messages.0.timestamp: Extra inputs are not permitted"
  - Implemented hybrid memory approach: immediate context (system prompt) + deep context (MCP function)
  - Added `get_conversation_context` MCP function for accessing deeper conversation history
  - Enhanced temporal intelligence with accurate time references (5 minutes ago vs "last night")
  - Natural cross-session memory continuity for Oracle coaching interactions
  - Zero performance impact with on-demand deep context loading

- **FT-156**: Activity Message Linking for Simple Coaching Memory
  - Connected detected activities to their source user messages for coaching context
  - Added `sourceMessageId` and `sourceMessageText` fields to ActivityModel
  - Enabled natural coaching references: "Lembro que você disse 'Acabei de beber água'"
  - Implemented unique message ID generation system
  - Enhanced MCP activity stats responses with message context
  - Comprehensive test coverage with 100% backward compatibility

### Fixed
- Claude API compatibility issues with timestamp fields in conversation history
- Incorrect temporal reasoning (5-minute gaps interpreted as "last night")
- Missing coaching context for activity-based conversations
- Limited Oracle memory access beyond recent 5 messages

### Enhanced
- Oracle coaching experience with natural conversation memory
- Activity detection system with message context preservation
- Temporal awareness with precise time calculations
- MCP system with conversation history access capabilities

### Technical
- Automatic Isar schema migration for new ActivityModel fields
- Zero data loss during schema updates
- Maintained backward compatibility for all existing functionality
- Added comprehensive error handling and fallback mechanisms

## [1.4.0] - 2024-09-20

### Added
- **FT-148**: Core behavioral rules and test cleanup - Finalized behavioral rules framework with comprehensive test coverage
- **FT-147**: Dimension display service fix - Fixed Oracle dimension code storage and display functionality  
- **FT-146**: Oracle-based dimension display fix - Enhanced dimension display using Oracle methodology
- **FT-145**: Enhanced activity detection regression fix - Improved multilingual activity detection with regression fixes
- **FT-144**: Persona configuration optimization - Optimized persona configuration management
- **FT-140**: MCP-integrated Oracle optimization - Implemented LLM Activity Pre-Selector and Progressive Detection with MCP integration

### Fixed
- Dimension display service properly stores Oracle dimension codes
- Activity detection accuracy improvements for multilingual content
- Persona configuration loading and management issues
- Oracle integration with MCP system enhancements

### Enhanced
- Test coverage and cleanup for behavioral rules system
- Activity detection performance and accuracy
- Oracle coaching capabilities with MCP integration
- Persona system reliability and configuration management

