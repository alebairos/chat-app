# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Start

```bash
# Setup
flutter pub get
cp .env.example .env  # Add your API keys

# Development
flutter run

# Testing
./test_scripts/run_all_tests.sh

# Build & Lint
flutter analyze
flutter build apk
```

## Required API Keys

Configure these in `.env`:
- `ANTHROPIC_API_KEY`: Required for AI chat functionality
- `OPENAI_API_KEY`: Required for voice transcription (Whisper)
- `ELEVEN_LABS_API_KEY`: Optional for high-quality TTS

## Architecture Overview

This is a Flutter AI chat app with sophisticated persona-based conversations and activity tracking.

### Core Technologies
- **Flutter**: Mobile app framework
- **Isar Database**: Local storage for messages and activities
- **Claude API**: AI conversation backend
- **MCP (Model Context Protocol)**: Privacy-preserving data integration

### Key Components

**Chat System** (`lib/services/claude_service.dart`):
- Manages AI conversations with rate limiting via `SharedClaudeRateLimiter`
- Integrates with MCP for context-aware responses
- Supports multiple personas with different behavioral patterns

**Persona System** (`assets/config/`):
- **Ari**: Life coach with TARS-inspired brevity (`ari_life_coach_config.json`)
- **Sergeant Oracle**: Roman gym coach with multiple versions (1.0-4.2) (`oracle/oracle_prompt_*.json`)
- **I-There**: AI clone with dimensional knowledge (`i_there_config.json`)
- Each persona has versioned configurations and MCP extensions

**Audio System** (`lib/features/audio_assistant/`):
- TTS with emotional tone mapping and character-specific voice configs
- Voice recording and transcription
- Audio playback management with cleanup

**Activity Tracking** (`lib/services/`):
- Semantic activity detection via `semantic_activity_detector.dart`
- Memory service for proactive context (`activity_memory_service.dart`)
- Queue system for processing activities (`activity_queue.dart`)

**MCP Integration** (`lib/services/system_mcp_service.dart`):
- Local data processing for privacy
- Time context service for temporal queries
- Integrated MCP processor for enhanced responses

### Database Models
- `ChatMessageModel`: Messages with persona and audio metadata
- `ActivityModel`: Tracked activities with semantic metadata
- Both use Isar with generated code (`.g.dart` files)

## Development Commands

**Testing**:
```bash
# Run all test groups (500+ tests)
./test_scripts/run_all_tests.sh

# Run specific test group
./test_scripts/run_test_group1.sh  # Audio tests
./test_scripts/run_test_group2.sh  # Message/system tests
./test_scripts/run_test_group3.sh  # Claude service tests
./test_scripts/run_test_group4.sh  # Life plan tests
./test_scripts/run_test_group5.sh  # Chat UI tests
./test_scripts/run_test_group6.sh  # Utils tests

# Run single test
flutter test test/path/to/test_file.dart
```

**Code Generation**:
```bash
# Generate Isar database code
flutter packages pub run build_runner build
```

**Analysis**:
```bash
# Lint and static analysis
flutter analyze
```

## Important Patterns

**Persona Configuration**: Each persona has JSON configs with system prompts, behavioral rules, and MCP extensions. Oracle personas are versioned (1.0-4.2) with optimization variants.

**Rate Limiting**: All Claude API calls go through `SharedClaudeRateLimiter` to prevent quota exhaustion. Activities have intelligent throttling via `llm_activity_pre_selector.dart`.

**Audio Processing**: TTS responses are cleaned via `tts_preprocessing_service.dart` to remove JSON artifacts. Character-specific voice configs in `character_voice_config.dart`.

**Activity Detection**: Semantic detection determines when activities need processing. Uses LLM qualification to prevent unnecessary API calls.

**MCP Context**: Time queries, activity stats, and memory retrieval use MCP for consistent data access while maintaining privacy.

## File Structure Notes

- `assets/config/`: Persona configurations and MCP extensions
- `lib/services/`: Core business logic and API integrations
- `lib/features/audio_assistant/`: Audio/TTS functionality
- `lib/models/`: Isar database models
- `lib/screens/`: UI screens (chat, stats, profile, onboarding)
- `lib/widgets/`: Reusable UI components
- `test/`: Comprehensive test suite organized in groups