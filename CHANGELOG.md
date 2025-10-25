# Changelog

All notable changes to this project will be documented in this file.

## [2.3.3] - 2025-10-25

### Bug fixes and improvements
- Automated release via FT-214 Protected Branch Release Workflow
- Version bumped from previous release (patch increment)


## [2.3.2] - 2025-10-25

### Bug fixes and improvements
- Automated release via FT-214 Protected Branch Release Workflow
- Version bumped from previous release (patch increment)


## [2.3.1] - 2025-10-24

### Bug fixes and improvements
- Automated release via FT-214 Protected Branch Release Workflow
- Version bumped from previous release (patch increment)


## [2.3.0] - 2025-10-24

### New features and enhancements
- Automated release via FT-214 Protected Branch Release Workflow
- Version bumped from previous release (minor increment)


## [2.2.1] - 2025-10-22

### Bug fixes and improvements
- Automated release via FT-214 Protected Branch Release Workflow
- Version bumped from previous release (patch increment)


## [2.2.0] - 2025-10-22

### New features and enhancements
- Automated release via FT-214 Protected Branch Release Workflow
- Version bumped from previous release (minor increment)


## [2.1.0] - 2025-10-20

### 🎉 Major Release: Aristios 4.5 Persona & System Stability

This release introduces the advanced Aristios 4.5 persona with philosophical depth and Oracle 4.2 integration, along with critical system stability improvements and enhanced persona management.

### Added
- **FT-186**: Aristios 4.5 Persona Development
  - **Philosophical Integration**: 14 core beliefs from Ari 5 documentation with transformational language
  - **Three-Pillar Framework**: MEEDDS (Energia), PLOW (Habilidade), GLOWS (Conexão) strategies
  - **Progressive Development Coaching**: Phase-based coaching (Estabelecimento → Desenvolvimento → Expansão)
  - **Enhanced Communication Style**: Soul-centered approach with practical Oracle 4.2 guidance
  - **Complete Oracle Integration**: 265+ activities across 8 dimensions with philosophical context

- **FT-208**: Persona Mention Autocomplete Enhancements
  - **Increased Persona Limit**: From 5 to 10 personas in @mention autocomplete
  - **Comprehensive Debug Logging**: Enhanced persona filtering and loading diagnostics
  - **Callback System**: Real-time title updates when switching personas via @mention
  - **Tony 4.2 Visibility**: Now properly appears in autocomplete (was 6th of 6 enabled)

### Fixed
- **FT-211**: Database Singleton Architecture Reversion
  - **Reverted Singleton Changes**: Restored working database architecture for journal generation
  - **Test Compatibility**: Removed singleton dependencies causing test failures
  - **Journal Generation**: Fixed database connection errors preventing daily journal creation
  - **Persona Switching**: Restored reliable persona switching functionality

- **FT-187**: Navigation Black Screen Fix
  - **Removed Aggressive Navigation**: Fixed black screen issues during app navigation
  - **Improved User Experience**: Smoother transitions between screens and features

### Enhanced
- **Persona Management System**: More robust persona loading and switching mechanisms
- **Database Architecture**: Restored stable, non-singleton database patterns
- **Test Infrastructure**: Comprehensive test cleanup and compatibility improvements
- **System Stability**: Multiple critical fixes for production reliability

### Technical Improvements
- **Configuration Management**: Enhanced persona configuration loading and validation
- **Debug Infrastructure**: Comprehensive logging for persona and database operations  
- **Test Architecture**: Restored working test patterns without singleton dependencies
- **Error Handling**: Improved error recovery for database and persona operations

### Documentation
- **Complete System Architecture Analysis (FT-188)**: Comprehensive documentation of persona loading, message history, and activity detection systems
- **Aristios 4.5 Specifications**: Detailed philosophical framework and implementation guidelines
- **Database Reversion Analysis**: Complete documentation of singleton pattern issues and solutions

## [2.0.0] - 2025-10-01

### 🎉 Major Release: I-There Daily Journal System

This major release introduces a comprehensive daily journal feature that transforms the app from a simple chat interface into a reflective life companion. The I-There persona now generates personalized daily insights, marking a significant evolution in the user experience.

### Added
- **FT-165**: I-There Daily Journal - Complete Implementation
  - **New Journal Tab**: Added as 4th tab in bottom navigation with book icon
  - **Dual Language Support**: Portuguese (pt_BR) and English (en_US) journal generation
  - **I-There Persona Voice**: Characteristic lowercase "i" style with curious, reflective tone
  - **Daily Insights Generation**: Analyzes chat messages and activities for personality insights
  - **Date Navigation**: Browse previous journal entries with intuitive date picker
  - **Two-Tab Structure**: "Journal" (narrative) and "Detailed Summary" (structured data)
  - **Context Consistency**: References recent journal insights for personality continuity
  - **Oracle Framework Integration**: Activity interpretation using Oracle 4.2 methodology

### Technical Implementation
- **Complete Feature Module**: `lib/features/journal/` with full MVC architecture
  - **Models**: JournalEntryModel with Isar database integration and rich metadata
  - **Services**: JournalGenerationService, JournalStorageService with Claude integration
  - **Screens**: JournalScreen with date navigation and dual-tab interface
  - **Widgets**: Reusable components for entry display, language toggle, loading states
- **Database Schema**: New JournalEntryModel collection with indexing and metadata
- **Language Persistence**: User language preference storage and retrieval
- **Performance Optimization**: Efficient date-based queries and caching
- **Memory Fine-tuning Ready**: Metadata structure for future AI memory improvements

### User Experience Enhancements
- **Intuitive Navigation**: Seamless date browsing with previous/next arrows
- **Language Toggle**: Easy PT/EN switching with persistent preferences
- **Loading States**: Skeleton screens during journal generation
- **Graceful Handling**: Empty state management for days with no data
- **Responsive Design**: Optimized for various screen sizes and orientations
- **Accessibility**: Screen reader support and keyboard navigation

### Data Analysis Features
- **Activity Breakdown**: Dimension-based activity grouping and analysis
- **Time Pattern Recognition**: Most active time of day identification
- **Message Statistics**: Conversation volume and engagement metrics
- **Personality Insights**: Behavioral pattern recognition and reflection
- **Oracle Compliance**: Activity interpretation using established Oracle catalog

### Integration Improvements
- **Claude Service Enhancement**: Optimized prompts for consistent I-There voice generation
- **Activity Memory Service**: Enhanced data retrieval for journal context
- **Chat Storage Service**: Improved message filtering and date-based queries
- **Oracle Static Cache**: Efficient activity metadata lookup for journal generation

## [1.9.1] - 2025-09-30

### Added
- **FT-170**: Lyfe Plan - Comprehensive Design & Implementation Strategy
  - Complete design for calendar-centric life management system
  - Single plan, multiple goals architecture with Oracle 4.2 framework compliance
  - Hierarchical structure: Plan → Goals → Activities (from Oracle catalog)
  - Persona-driven coaching with unique delivery styles for same Oracle science
  - PDCA cycle integration (Plan → Do → Check → Act) for continuous improvement
  - Smart scheduling with recurrent vs spot activities

- **FT-164**: Background Message Processing Fix (Specification)
  - Comprehensive specification for fixing tab switching crashes during message processing
  - Database-first architecture design for seamless background conversation continuation
  - Modern chat app patterns (WhatsApp, Telegram) for persistent conversations
  - Solution for `setState() called after dispose()` exceptions during tab switches

### Enhanced
- **Persona Configuration**: Enabled only Oracle 4.2 personas for focused user experience
  - I-There 4.2, Aristos 4.2, Sergeant Oracle 4.2, Arya 4.2 active
  - Streamlined persona selection with Oracle framework consistency
  - Improved user experience with curated, high-quality persona options

### Documentation
- Comprehensive Lyfe Plan system architecture and implementation strategy
- Detailed persona integration patterns for Oracle 4.2 framework
- Background message processing technical specifications
- Implementation summaries for v1.9.0 features (FT-161, FT-162, FT-163)

### Technical
- Oracle 4.2 framework compliance across all active personas
- Calendar-first interface design for daily execution planning
- Toyota Kata integration with built-in PDCA cycles
- Realistic constraint handling with single plan prioritization

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

