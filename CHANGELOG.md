# Changelog

All notable changes to this project will be documented in this file.

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
