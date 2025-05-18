# Task 2: Extend ClaudeService to Support TTS

## Overview

This document outlines the steps to modify the `ClaudeService` to support Text-to-Speech (TTS) functionality. This implementation will allow the AI assistant to generate audio responses alongside text responses.

## Prerequisites

- Completed Task 1: Setup
- Existing `ClaudeService` with text response functionality
- Existing `AudioAssistantTTSService` with audio generation functionality
- Test infrastructure set up

## Implementation Steps

### Step 1: Create ClaudeAudioResponse Model

First, create a new model class to encapsulate both text and audio responses:

```dart
// lib/models/claude_audio_response.dart
class ClaudeAudioResponse {
  final String text;
  final String? audioPath;
  final Duration? audioDuration;

  ClaudeAudioResponse({
    required this.text,
    this.audioPath,
    this.audioDuration,
  });

  @override
  String toString() {
    return 'ClaudeAudioResponse(text: ${text.length > 20 ? '${text.substring(0, 20)}...' : text}, '
        'audioPath: $audioPath, audioDuration: $audioDuration)';
  }
}
```

### Step 2: Modify ClaudeService

Update `ClaudeService` to support TTS functionality:

```dart
// lib/services/claude_service.dart

// Add these imports
import '../features/audio_assistant/tts_service.dart';
import '../models/claude_audio_response.dart';

class ClaudeService {
  // Add these fields
  final AudioAssistantTTSService? _ttsService;
  bool _audioEnabled = true;

  // Update constructor
  ClaudeService({
    http.Client? client,
    LifePlanMCPService? lifePlanMCP,
    ConfigLoader? configLoader,
    AudioAssistantTTSService? ttsService,
    bool audioEnabled = true,
  })  : _client = client ?? http.Client(),
        _lifePlanMCP = lifePlanMCP,
        _configLoader = configLoader ?? ConfigLoader(),
        _ttsService = ttsService,
        _audioEnabled = audioEnabled {
    _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  }

  // Add getter and setter for audioEnabled
  bool get audioEnabled => _audioEnabled;
  set audioEnabled(bool value) => _audioEnabled = value;

  // Add method to send message with audio
  Future<ClaudeAudioResponse> sendMessageWithAudio(String message) async {
    try {
      // First get the text response
      final textResponse = await sendMessage(message);
      
      // Return text-only response if TTS is disabled or unavailable
      if (!_audioEnabled || _ttsService == null) {
        _logger.debug('Audio is disabled or TTS service is unavailable');
        return ClaudeAudioResponse(text: textResponse);
      }
      
      try {
        // Initialize TTS service if needed
        final ttsInitialized = await _ttsService!.initialize();
        if (!ttsInitialized) {
          _logger.error('Failed to initialize TTS service');
          return ClaudeAudioResponse(text: textResponse);
        }
        
        // Generate audio from the text response
        final audioPath = await _ttsService!.generateAudio(textResponse);
        
        // If audio generation failed, return text only
        if (audioPath == null) {
          _logger.error('Failed to generate audio for response');
          return ClaudeAudioResponse(text: textResponse);
        }
        
        _logger.debug('Generated audio at path: $audioPath');
        
        // Return both text and audio path
        return ClaudeAudioResponse(
          text: textResponse,
          audioPath: audioPath,
          // Duration is not available here, will be set later
        );
      } catch (e) {
        _logger.error('Error generating audio for response: $e');
        return ClaudeAudioResponse(text: textResponse);
      }
    } catch (e) {
      final errorMessage = _getUserFriendlyErrorMessage(e.toString());
      _logger.error('Error in sendMessageWithAudio: $e');
      return ClaudeAudioResponse(text: errorMessage);
    }
  }
  
  // Add helper method for TTS-specific error handling
  String _handleTTSError(dynamic error) {
    if (error.toString().contains('TTS service not initialized')) {
      return 'Audio generation is temporarily unavailable. Please try again later.';
    }
    if (error.toString().contains('audio file generation failed')) {
      return 'Failed to generate audio. Text response is still available.';
    }
    return 'An error occurred during audio generation.';
  }
}
```

### Step 3: Update Tests

Implement the unit tests for the new functionality:

```dart
// test/services/claude_service_tts_test.dart

// Add test for initialization with TTS service
test('ClaudeService initializes with TTS service', () {
  expect(claudeService.audioEnabled, isTrue);
});

// Add test for sendMessageWithAudio with TTS failure
test('sendMessageWithAudio returns text only when TTS fails', () async {
  when(mockTTSService.initialize()).thenAnswer((_) async => true);
  when(mockTTSService.generateAudio(any)).thenAnswer((_) async => null);
  
  when(mockClient.post(any, headers: any, body: any, encoding: any))
      .thenAnswer((_) async => http.Response(
            '{"content":[{"text":"Test response"}]}',
            200,
          ));
  
  final response = await claudeService.sendMessageWithAudio('Test message');
  
  expect(response.text, equals('Test response'));
  expect(response.audioPath, isNull);
});

// Add test for successful audio generation
test('sendMessageWithAudio returns both text and audio when successful', () async {
  when(mockTTSService.initialize()).thenAnswer((_) async => true);
  when(mockTTSService.generateAudio(any))
      .thenAnswer((_) async => 'audio_path/test_audio.mp3');
  
  when(mockClient.post(any, headers: any, body: any, encoding: any))
      .thenAnswer((_) async => http.Response(
            '{"content":[{"text":"Test response"}]}',
            200,
          ));
  
  final response = await claudeService.sendMessageWithAudio('Test message');
  
  expect(response.text, equals('Test response'));
  expect(response.audioPath, equals('audio_path/test_audio.mp3'));
});

// Add test for audioEnabled flag
test('audioEnabled flag controls audio generation', () async {
  when(mockTTSService.initialize()).thenAnswer((_) async => true);
  when(mockTTSService.generateAudio(any))
      .thenAnswer((_) async => 'audio_path/test_audio.mp3');
  
  when(mockClient.post(any, headers: any, body: any, encoding: any))
      .thenAnswer((_) async => http.Response(
            '{"content":[{"text":"Test response"}]}',
            200,
          ));
  
  // Disable audio
  claudeService.audioEnabled = false;
  
  final response1 = await claudeService.sendMessageWithAudio('Test message');
  expect(response1.text, equals('Test response'));
  expect(response1.audioPath, isNull);
  
  // Enable audio
  claudeService.audioEnabled = true;
  
  final response2 = await claudeService.sendMessageWithAudio('Test message');
  expect(response2.text, equals('Test response'));
  expect(response2.audioPath, equals('audio_path/test_audio.mp3'));
});
```

Also update the integration test:

```dart
// test/features/audio_assistant/integration/claude_tts_integration_test.dart

test('End-to-end integration with real TTS service', () async {
  when(mockClient.post(any, headers: any, body: any, encoding: any))
      .thenAnswer((_) async => http.Response(
            '{"content":[{"text":"This is a test response for TTS integration."}]}',
            200,
          ));
  
  // Send a message and get audio response
  final response = await claudeService.sendMessageWithAudio('Test message');
  
  // Verify text response
  expect(response.text, equals('This is a test response for TTS integration.'));
  
  // Verify audio path
  expect(response.audioPath, isNotNull);
  expect(response.audioPath, contains('test_audio_assistant_'));
  expect(response.audioPath, endsWith('.mp3'));
});
```

## Testing Steps

1. Run unit tests:
```bash
flutter test test/services/claude_service_tts_test.dart
```

2. Run integration tests:
```bash
flutter test test/features/audio_assistant/integration/claude_tts_integration_test.dart
```

3. Run all tests to ensure no regressions:
```bash
flutter test
```

## Completion Checklist

- [ ] Created ClaudeAudioResponse model
- [ ] Modified ClaudeService to support TTS
- [ ] Implemented sendMessageWithAudio method
- [ ] Added error handling for TTS-related errors
- [ ] Implemented comprehensive unit tests
- [ ] Implemented integration tests
- [ ] Verified all tests pass
- [ ] Verified no regressions in existing functionality

## Next Steps

After completing this task, proceed to Task 3: ChatMessageModel Updates to ensure the chat message model properly supports audio messages. 