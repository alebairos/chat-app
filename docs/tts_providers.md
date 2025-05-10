# Text-to-Speech Provider Integration

This document outlines how Text-to-Speech (TTS) providers are integrated into the Chat App's audio assistant feature.

## Architecture Overview

The TTS integration uses a provider-based architecture that allows easy switching between different TTS services.

### Key Components

1. **TTSProvider Interface**: A common interface that all TTS providers implement
2. **ElevenLabsProvider**: Implementation using Eleven Labs API
3. **MockTTSProvider**: Mock implementation for testing purposes
4. **AudioAssistantTTSService**: Main service that coordinates TTS functionality

## Available Providers

Currently, the following TTS providers are available:

### Eleven Labs (Default)

- High-quality, natural-sounding voices
- Extensive customization options
- Requires API key (set as `ELEVENLABS_API_KEY` in .env file)
- Configuration options:
  - `voiceId`: The voice to use (default: `pNInz6obpgDQGcFmaJgB`)
  - `modelId`: The model to use (default: `eleven_monolingual_v1`)
  - `stability`: Voice stability factor (0.0-1.0)
  - `similarityBoost`: Voice similarity factor (0.0-1.0)
  - `style`: Voice style factor (0.0-1.0)
  - `speakerBoost`: Whether to boost speaker clarity

### Mock TTS Provider (Testing Only)

- Used for testing purposes
- Generates simple WAV files with sine waves
- Simulates various behaviors like delays and failures
- Configuration options:
  - `simulateDelay`: Whether to simulate processing delays
  - `delayMilliseconds`: Amount of delay to simulate
  - `simulateRandomFailures`: Whether to simulate random failures
  - `failureRate`: Probability of failure (0.0-1.0)

## How to Use

### Basic Usage

```dart
// Get the service
final ttsService = AudioAssistantTTSService();

// Initialize
await ttsService.initialize();

// Generate speech
final audioPath = await ttsService.generateAudio('Text to convert to speech');
```

### Switching Providers

```dart
// List available providers
final providers = ttsService.availableProviders;
print('Available providers: $providers');

// Switch to a different provider
await ttsService.switchProvider('ElevenLabs');
```

### Configuring Providers

```dart
// Get current configuration
final config = ttsService.providerConfig;

// Update configuration
await ttsService.updateProviderConfig({
  'voiceId': 'different_voice_id',
  'stability': 0.8,
});
```

## Adding New Providers

To add a new TTS provider:

1. Create a new class that implements the `TTSProvider` interface
2. Register the provider in the `_registerProviders` method of `AudioAssistantTTSService`
3. Implement all required methods

Example:

```dart
class GoogleTTSProvider implements TTSProvider {
  @override
  String get name => 'GoogleTTS';
  
  // Implement all other required methods
}

// In AudioAssistantTTSService._registerProviders
_availableProviders['GoogleTTS'] = GoogleTTSProvider();
```

## Environment Setup

To use the Eleven Labs provider:

1. Copy `.env.example` to `.env`
2. Add your Eleven Labs API key as `ELEVENLABS_API_KEY=your_key_here`
3. Make sure `flutter_dotenv` is properly initialized in your app

## Testing

A mock provider is available for testing purposes:

```dart
// In your test
final ttsService = AudioAssistantTTSService();
ttsService.enableTestMode(); // Use mock provider

// Test TTS functionality without external dependencies
final result = await ttsService.generateAudio('Test text');
``` 