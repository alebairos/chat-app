# AI Chat App

A Flutter chat app with AI personas, voice features, and activity tracking.

## Features

- **AI Chat**: Claude-powered conversations with configurable personas
- **Voice**: Text-to-speech, audio recording, transcription
- **Personas**: Ari (Life Coach), Sergeant Oracle, I-There
- **Plan Tab**: Proactive planning system with calendar navigation and template replication
- **Stats**: Activity tracking analytics and insights
- **Storage**: Local message and audio storage
- **MCP Integration**: Local data processing with intelligent persona responses

## Quick Start

1. Clone and run `flutter pub get`
2. Create `.env` with your API keys:
   ```
   ANTHROPIC_API_KEY=your_claude_key
   OPENAI_API_KEY=your_whisper_key
   ELEVEN_LABS_API_KEY=your_tts_key
   ```
3. Run `flutter run`

## API Keys

- **Claude**: Required for AI chat
- **Whisper**: Required for voice transcription  
- **ElevenLabs**: Optional for high-quality TTS

## Personas

- **Ari**: Concise life coaching with TARS-inspired brevity
- **Sergeant Oracle**: Energetic Roman gym coach
- **I-There**: AI clone with dimensional knowledge

## Recent Updates

### FT-105: Plan Tab - Comprehensive Planning System 📝
- **Proactive Planning**: Transform from reactive stats to intentional daily planning
- **Calendar Navigation**: Swipeable days with today-focused interface
- **Template Intelligence**: Smart replication (weekdays from weekdays, weekends from weekends)
- **Personal Organization**: Custom labels, user notes, and drag-drop activity management
- **Seamless Integration**: Zero impact on detection system, auto-complete planned activities

### FT-104: JSON Command TTS Leak Fix ✅
- **TTS Contamination**: Prevent JSON commands from bleeding into spoken responses
- **Surgical Fix**: Enhanced response cleaning for both regular and two-pass conversations
- **User Experience**: Clean audio without technical artifacts

### FT-103: Intelligent Activity Detection Throttling ✅
- **Model-Driven Qualification**: AI determines when activity detection is needed
- **Rate Limit Protection**: Adaptive delays (5-15s) based on API usage patterns
- **Smart Processing**: Internal assessment tags prevent TTS contamination

### FT-102: Minimal Time Cache Fix ✅
- **Caching Strategy**: 30-second cache for `get_current_time` MCP calls
- **Rate Limit Prevention**: Reduces redundant API calls across services
- **System Efficiency**: Maintains accuracy while optimizing performance

### FT-100: Basic Temporal Query MCP Fix ✅
- **Enhanced Guidance**: Comprehensive prompt table for temporal query handling
- **Consistent Responses**: Always use MCP for "what time?", "what date?", "what day?"
- **Reliable Data**: Fix date inconsistencies in AI responses

## Development

- **Tests**: 500+ tests with 95%+ pass rate
- **Architecture**: Clean Flutter with Isar database
- **Audio**: Provider-based TTS with emotional preprocessing
- **MCP**: Local Model Context Protocol for privacy-preserving data integration

## Version

Current: v1.0.37

For detailed changelog and technical docs, see `docs/` directory.
