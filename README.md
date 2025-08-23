# AI Chat App

A Flutter chat app with AI personas, voice features, and activity tracking.

## Features

- **AI Chat**: Claude-powered conversations with configurable personas
- **Voice**: Text-to-speech, audio recording, transcription
- **Personas**: Ari (Life Coach), Sergeant Oracle, I-There
- **Stats**: Activity tracking and insights
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

### FT-078: Persona-Aware MCP Data Integration ✅
- **Natural Intelligence**: Removed hardcoded rules for authentic persona responses
- **Zero Contradictions**: AI now sees full context (persona + Oracle + time + MCP data)
- **Language Agnostic**: Works seamlessly in any language
- **Foundation Ready**: Enables future proactive AI features (FT-073, FT-074, FT-075, FT-076)

## Development

- **Tests**: 500+ tests with 95%+ pass rate
- **Architecture**: Clean Flutter with Isar database
- **Audio**: Provider-based TTS with emotional preprocessing
- **MCP**: Local Model Context Protocol for privacy-preserving data integration

## Version

Current: v1.0.37

For detailed changelog and technical docs, see `docs/` directory.
