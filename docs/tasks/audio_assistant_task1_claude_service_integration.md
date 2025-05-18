# Task: Integrate ClaudeService with TTS

## Overview

This task involves modifying the `ClaudeService` to use the `AudioAssistantTTSService` to generate audio versions of assistant responses. This is a critical first step in implementing the audio assistant feature.

## Prerequisites

- Existing `ClaudeService` with text response functionality
- Existing `AudioAssistantTTSService` with basic audio generation functionality
- Test infrastructure for running unit and integration tests

## Implementation Steps

### Step 1: Add TTS Service Dependency to ClaudeService

1. Modify `lib/services/claude_service.dart` to:
   - Add `AudioAssistantTTSService` as a constructor parameter
   - Initialize TTS service during ClaudeService initialization
   - Add an `audioEnabled` flag to control audio generation

```dart
class ClaudeService {
  // Existing fields
  final AudioAssistantTTSService? _ttsService;
  bool _audioEnabled = true;

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

  // New getter and setter for audioEnabled
  bool get audioEnabled => _audioEnabled;
  set audioEnabled(bool value) => _audioEnabled = value;
}
```

### Step 2: Create Response Class for Audio Responses

Create a model class to hold both text and audio path:

```dart
class ClaudeAudioResponse {
  final String text;
  final String? audioPath;
  final Duration? audioDuration;

  ClaudeAudioResponse({
    required this.text,
    this.audioPath,
    this.audioDuration,
  });
}
```

### Step 3: Add sendMessageWithAudio Method

Add a new method that generates audio for the response:

```dart
Future<ClaudeAudioResponse> sendMessageWithAudio(String message) async {
  // First get the text response
  final textResponse = await sendMessage(message);
  
  // If audio is not enabled or TTS service is not available, return text only
  if (!_audioEnabled || _ttsService == null) {
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
}
```

### Step 4: Add Error Handling

Add specific error handling for TTS-related errors:

```dart
// Helper method for TTS-specific error handling
String _handleTTSError(dynamic error) {
  if (error.toString().contains('TTS service not initialized')) {
    return 'Audio generation is temporarily unavailable. Please try again later.';
  }
  if (error.toString().contains('audio file generation failed')) {
    return 'Failed to generate audio. Text response is still available.';
  }
  return 'An error occurred during audio generation.';
}
```

## Test Plan

### Unit Tests (`test/services/claude_service_tts_test.dart`)

#### Test 1: ClaudeService Initializes with TTS Service

```dart
test('ClaudeService initializes with TTS service', () {
  final mockTTSService = MockAudioAssistantTTSService();
  final claudeService = ClaudeService(ttsService: mockTTSService);
  
  expect(claudeService.audioEnabled, isTrue);
});
```

#### Test 2: sendMessageWithAudio Returns Text Response When TTS Fails

```dart
test('sendMessageWithAudio returns text only when TTS fails', () async {
  final mockTTSService = MockAudioAssistantTTSService();
  when(mockTTSService.initialize()).thenAnswer((_) async => true);
  when(mockTTSService.generateAudio(any)).thenAnswer((_) async => null);
  
  final mockClient = MockHttpClient();
  when(mockClient.post(any, headers: any, body: any, encoding: any))
      .thenAnswer((_) async => http.Response(
            '{"content":[{"text":"Test response"}]}',
            200,
          ));
  
  final claudeService = ClaudeService(
    client: mockClient,
    ttsService: mockTTSService,
  );
  
  final response = await claudeService.sendMessageWithAudio('Test message');
  
  expect(response.text, equals('Test response'));
  expect(response.audioPath, isNull);
});
```

#### Test 3: sendMessageWithAudio Returns Both Text and Audio Path When Successful

```dart
test('sendMessageWithAudio returns both text and audio when successful', () async {
  final mockTTSService = MockAudioAssistantTTSService();
  when(mockTTSService.initialize()).thenAnswer((_) async => true);
  when(mockTTSService.generateAudio(any))
      .thenAnswer((_) async => 'audio_path/test_audio.mp3');
  
  final mockClient = MockHttpClient();
  when(mockClient.post(any, headers: any, body: any, encoding: any))
      .thenAnswer((_) async => http.Response(
            '{"content":[{"text":"Test response"}]}',
            200,
          ));
  
  final claudeService = ClaudeService(
    client: mockClient,
    ttsService: mockTTSService,
  );
  
  final response = await claudeService.sendMessageWithAudio('Test message');
  
  expect(response.text, equals('Test response'));
  expect(response.audioPath, equals('audio_path/test_audio.mp3'));
});
```

#### Test 4: audioEnabled Flag Controls Audio Generation

```dart
test('audioEnabled flag controls audio generation', () async {
  final mockTTSService = MockAudioAssistantTTSService();
  when(mockTTSService.initialize()).thenAnswer((_) async => true);
  when(mockTTSService.generateAudio(any))
      .thenAnswer((_) async => 'audio_path/test_audio.mp3');
  
  final mockClient = MockHttpClient();
  when(mockClient.post(any, headers: any, body: any, encoding: any))
      .thenAnswer((_) async => http.Response(
            '{"content":[{"text":"Test response"}]}',
            200,
          ));
  
  final claudeService = ClaudeService(
    client: mockClient,
    ttsService: mockTTSService,
    audioEnabled: false,
  );
  
  final response = await claudeService.sendMessageWithAudio('Test message');
  
  expect(response.text, equals('Test response'));
  expect(response.audioPath, isNull);
  
  // Enable audio
  claudeService.audioEnabled = true;
  final response2 = await claudeService.sendMessageWithAudio('Test message');
  
  expect(response2.text, equals('Test response'));
  expect(response2.audioPath, equals('audio_path/test_audio.mp3'));
});
```

### Integration Tests (`test/features/audio_assistant/integration/claude_tts_integration_test.dart`)

#### Test 1: End-to-End TTS Integration

```dart
test('End-to-end integration with real TTS service', () async {
  // Use a real TTS service but with test mode enabled
  final ttsService = AudioAssistantTTSService();
  ttsService.enableTestMode();
  
  // Use a mock Claude service with the real TTS service
  final mockClient = MockHttpClient();
  when(mockClient.post(any, headers: any, body: any, encoding: any))
      .thenAnswer((_) async => http.Response(
            '{"content":[{"text":"This is a test response for TTS integration."}]}',
            200,
          ));
  
  final claudeService = ClaudeService(
    client: mockClient,
    ttsService: ttsService,
  );
  
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

## Success Criteria

1. All tests pass successfully
2. ClaudeService correctly integrates with AudioAssistantTTSService
3. Audio generation is controlled by the audioEnabled flag
4. Error handling is robust and user-friendly
5. Performance impact is minimal

## Next Steps After Completion

1. Implement ChatScreen integration to use the new sendMessageWithAudio method
2. Update ChatMessage widget to display AssistantAudioMessage for responses with audio
3. Implement additional error handling and recovery mechanisms 