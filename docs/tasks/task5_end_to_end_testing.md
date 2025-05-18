# Task 5: End-to-End Testing

## Overview

This task involves creating comprehensive end-to-end tests for the audio assistant feature. These tests will verify that the entire flow works correctly, from sending a message to receiving and playing an audio response.

## Prerequisites

- Completed Task 4: ChatScreen Integration
- Working audio assistant feature

## Implementation Steps

### Step 1: Create E2E Test File

Create a comprehensive end-to-end test file:

```dart
// test/features/audio_assistant/integration/audio_assistant_e2e_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:character_ai_clone/main.dart';
import 'package:character_ai_clone/screens/chat_screen.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/chat_storage_service.dart';
import 'package:character_ai_clone/features/audio_assistant/tts_service.dart';
import 'package:character_ai_clone/models/claude_audio_response.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/assistant_audio_message.dart';

// Mock service classes
class MockClaudeService extends Mock implements ClaudeService {}
class MockChatStorageService extends Mock implements ChatStorageService {}
class MockAudioAssistantTTSService extends Mock implements AudioAssistantTTSService {}

void main() {
  late MockClaudeService mockClaudeService;
  late MockChatStorageService mockStorageService;
  late MockAudioAssistantTTSService mockTTSService;

  setUp(() {
    mockClaudeService = MockClaudeService();
    mockStorageService = MockChatStorageService();
    mockTTSService = MockAudioAssistantTTSService();
    
    // Setup default behaviors
    when(() => mockClaudeService.initialize()).thenAnswer((_) async => true);
    when(() => mockStorageService.initialize()).thenAnswer((_) async => true);
    when(() => mockTTSService.initialize()).thenAnswer((_) async => true);
    when(() => mockStorageService.getMessages(
      limit: any(named: 'limit'),
      before: any(named: 'before'),
    )).thenAnswer((_) async => []);
    
    // Register fallback values for any named parameters
    registerFallbackValue(DateTime.now());
    registerFallbackValue(Duration(seconds: 10));
    registerFallbackValue(MessageType.audio);
  });

  group('Audio Assistant End-to-End Tests', () {
    testWidgets('Complete flow: send message, receive audio, play audio', 
      (WidgetTester tester) async {
      // Setup Claude service to return audio response
      when(() => mockClaudeService.audioEnabled).thenReturn(true);
      when(() => mockClaudeService.sendMessageWithAudio(any())).thenAnswer((_) async =>
        ClaudeAudioResponse(
          text: 'This is an audio response from the assistant.',
          audioPath: 'test_audio.mp3',
          audioDuration: Duration(seconds: 10),
        )
      );
      
      // Setup storage service mock for saving and retrieval
      when(() => mockStorageService.saveMessage(
        text: any(named: 'text'),
        isUser: any(named: 'isUser'), 
        type: any(named: 'type'),
        mediaPath: any(named: 'mediaPath'),
        duration: any(named: 'duration'),
      )).thenAnswer((_) async => 1);
      
      when(() => mockStorageService.getMessages(limit: any(named: 'limit')))
        .thenAnswer((_) async => [
          ChatMessageModel(
            id: 1,
            text: 'This is an audio response from the assistant.',
            isUser: false,
            type: MessageType.audio,
            timestamp: DateTime.now(),
            mediaPath: 'test_audio.mp3',
            duration: Duration(seconds: 10),
          ),
        ]);
      
      // Build the app with mock services
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            claudeService: mockClaudeService,
            storageService: mockStorageService,
            testMode: true,
          ),
        ),
      );
      
      // Enter a user message
      await tester.enterText(find.byType(TextField), 'Tell me about audio features');
      
      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      
      // Wait for UI update
      await tester.pumpAndSettle();
      
      // Verify that the ClaudeService was called with audio
      verify(() => mockClaudeService.sendMessageWithAudio('Tell me about audio features')).called(1);
      
      // Verify the audio message is displayed
      expect(find.text('This is an audio response from the assistant.'), findsOneWidget);
      expect(find.byType(AssistantAudioMessage), findsOneWidget);
      
      // Tap the play button in the AssistantAudioMessage
      await tester.tap(find.descendant(
        of: find.byType(AssistantAudioMessage),
        matching: find.byIcon(Icons.play_circle_filled),
      ));
      
      // Wait for UI update after playback starts
      await tester.pumpAndSettle();
      
      // Verify the pause button is now displayed (indicating playback)
      expect(find.descendant(
        of: find.byType(AssistantAudioMessage),
        matching: find.byIcon(Icons.pause_circle_filled),
      ), findsOneWidget);
      
      // Tap the pause button
      await tester.tap(find.descendant(
        of: find.byType(AssistantAudioMessage),
        matching: find.byIcon(Icons.pause_circle_filled),
      ));
      
      // Wait for UI update after playback pauses
      await tester.pumpAndSettle();
      
      // Verify the play button is displayed again
      expect(find.descendant(
        of: find.byType(AssistantAudioMessage),
        matching: find.byIcon(Icons.play_circle_filled),
      ), findsOneWidget);
    });
    
    testWidgets('Multiple audio messages - only one plays at a time', 
      (WidgetTester tester) async {
      // Setup initial state with multiple audio messages
      when(() => mockStorageService.getMessages(limit: any(named: 'limit')))
        .thenAnswer((_) async => [
          ChatMessageModel(
            id: 1,
            text: 'First audio response',
            isUser: false,
            type: MessageType.audio,
            timestamp: DateTime.now(),
            mediaPath: 'audio1.mp3',
            duration: Duration(seconds: 5),
          ),
          ChatMessageModel(
            id: 2,
            text: 'Second audio response',
            isUser: false,
            type: MessageType.audio,
            timestamp: DateTime.now().subtract(Duration(minutes: 1)),
            mediaPath: 'audio2.mp3',
            duration: Duration(seconds: 8),
          ),
        ]);
      
      // Build the app with mock services
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            claudeService: mockClaudeService,
            storageService: mockStorageService,
            testMode: true,
          ),
        ),
      );
      
      // Wait for UI to load
      await tester.pumpAndSettle();
      
      // Verify both audio messages are displayed
      expect(find.text('First audio response'), findsOneWidget);
      expect(find.text('Second audio response'), findsOneWidget);
      expect(find.byType(AssistantAudioMessage), findsNWidgets(2));
      
      // Find the first and second audio messages
      final firstAudioMessage = find.text('First audio response');
      final secondAudioMessage = find.text('Second audio response');
      
      // Tap play on first audio message
      await tester.tap(find.descendant(
        of: find.ancestor(
          of: firstAudioMessage,
          matching: find.byType(AssistantAudioMessage),
        ),
        matching: find.byIcon(Icons.play_circle_filled),
      ));
      
      // Wait for UI update
      await tester.pumpAndSettle();
      
      // Verify first message is playing (shows pause button)
      expect(find.descendant(
        of: find.ancestor(
          of: firstAudioMessage,
          matching: find.byType(AssistantAudioMessage),
        ),
        matching: find.byIcon(Icons.pause_circle_filled),
      ), findsOneWidget);
      
      // Tap play on second audio message
      await tester.tap(find.descendant(
        of: find.ancestor(
          of: secondAudioMessage,
          matching: find.byType(AssistantAudioMessage),
        ),
        matching: find.byIcon(Icons.play_circle_filled),
      ));
      
      // Wait for UI update
      await tester.pumpAndSettle();
      
      // Verify first message stopped playing (shows play button)
      expect(find.descendant(
        of: find.ancestor(
          of: firstAudioMessage,
          matching: find.byType(AssistantAudioMessage),
        ),
        matching: find.byIcon(Icons.play_circle_filled),
      ), findsOneWidget);
      
      // Verify second message is playing (shows pause button)
      expect(find.descendant(
        of: find.ancestor(
          of: secondAudioMessage,
          matching: find.byType(AssistantAudioMessage),
        ),
        matching: find.byIcon(Icons.pause_circle_filled),
      ), findsOneWidget);
    });
    
    testWidgets('Audio toggle disables audio generation', 
      (WidgetTester tester) async {
      // Setup Claude service
      when(() => mockClaudeService.audioEnabled).thenReturn(true);
      when(() => mockClaudeService.sendMessage(any())).thenAnswer((_) async =>
        'Text-only response'
      );
      when(() => mockClaudeService.sendMessageWithAudio(any())).thenAnswer((_) async =>
        ClaudeAudioResponse(
          text: 'Audio response',
          audioPath: 'test_audio.mp3',
          audioDuration: Duration(seconds: 5),
        )
      );
      
      // Allow setting audioEnabled
      when(() => mockClaudeService.audioEnabled = any(named: 'value'))
        .thenAnswer((invocation) {
          final bool value = invocation.namedArguments[#value] as bool;
          when(() => mockClaudeService.audioEnabled).thenReturn(value);
        });
      
      // Setup storage mock
      when(() => mockStorageService.saveMessage(
        text: any(named: 'text'),
        isUser: any(named: 'isUser'), 
        type: any(named: 'type'),
        mediaPath: any(named: 'mediaPath'),
        duration: any(named: 'duration'),
      )).thenAnswer((_) async => 1);
      
      when(() => mockStorageService.getMessages(limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
      
      // Build the app with mock services
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            claudeService: mockClaudeService,
            storageService: mockStorageService,
            testMode: true,
          ),
        ),
      );
      
      // Find the audio toggle in the app bar (may need to adjust based on actual UI)
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pumpAndSettle();
      
      // Enter and send a message
      await tester.enterText(find.byType(TextField), 'Test message with audio disabled');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      
      // Verify that the regular sendMessage was called instead of sendMessageWithAudio
      verify(() => mockClaudeService.sendMessage('Test message with audio disabled')).called(1);
      verifyNever(() => mockClaudeService.sendMessageWithAudio(any()));
    });
  });
}
```

### Step 2: Create Manual Testing Script

Create a manual testing script for real device testing:

```markdown
# Audio Assistant Manual Testing Script

## Setup
1. Install the app on both iOS and Android test devices
2. Ensure internet connectivity is available
3. Ensure device sound is turned on

## Basic Functionality Tests

### Test 1: Basic Audio Response
1. Open the app
2. Enter a simple message: "Hello, tell me about yourself"
3. Tap send button
4. Verify:
   - Assistant responds with a text message
   - Message includes an audio player UI
   - Audio content matches text content

### Test 2: Audio Playback
1. From Test 1, tap the play button on the audio message
2. Verify:
   - Audio begins playing
   - Play button changes to pause button
   - Progress indicator moves
3. Tap pause button
4. Verify:
   - Audio stops playing
   - Pause button changes back to play button
5. Tap play again to resume from paused position
6. Let audio play to completion
7. Verify play button reappears and progress resets

### Test 3: Multiple Audio Messages
1. Send a second message: "Tell me a short joke"
2. Wait for audio response
3. Play the first audio message
4. While first audio is playing, play the second audio
5. Verify:
   - First audio stops when second audio starts
   - Only one audio message plays at a time

### Test 4: Audio Toggle
1. Tap the audio toggle button to disable audio
2. Send message: "How does text-only response look?"
3. Verify response comes without audio player
4. Tap audio toggle to re-enable audio
5. Send message: "Audio should be back now"
6. Verify audio response returns

## Edge Case Tests

### Test 5: Network Interruption
1. Enable airplane mode while sending a message
2. Verify app shows appropriate error
3. Disable airplane mode
4. Try sending message again
5. Verify message sends successfully with audio

### Test 6: Background and Foreground
1. Play an audio message
2. Send app to background (press home button)
3. Return to app after 5 seconds
4. Verify:
   - Audio has continued playing in background (if permitted by platform)
   - UI state correctly reflects playback state

### Test 7: Long Messages
1. Send a long message asking for a detailed explanation of something
2. Verify:
   - Long text response is properly formatted
   - Audio plays the entire long response

## Performance Tests

### Test 8: Response Time
1. Time how long it takes from sending message to receiving audio response
2. Verify response time is within acceptable range (< 10 seconds)

### Test 9: Memory Usage
1. Send and play 10 audio messages in succession
2. Check device memory usage
3. Verify app doesn't consume excessive memory

### Test 10: Battery Impact
1. Note battery percentage
2. Send and play audio messages for 10 minutes
3. Check battery usage stats
4. Verify audio playback doesn't cause excessive battery drain
```

### Step 3: Create Performance Testing Script

Create a simple test script for measuring audio generation performance:

```dart
// test/features/audio_assistant/performance/tts_performance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/features/audio_assistant/tts_service.dart';

void main() {
  group('TTS Performance Tests', () {
    late AudioAssistantTTSService ttsService;
    
    setUp(() {
      ttsService = AudioAssistantTTSService();
    });
    
    test('Measure audio generation time for short text', () async {
      await ttsService.initialize();
      
      final stopwatch = Stopwatch()..start();
      
      await ttsService.generateAudio('This is a short test message for performance testing.');
      
      stopwatch.stop();
      final elapsedMilliseconds = stopwatch.elapsedMilliseconds;
      
      print('Short text audio generation took: $elapsedMilliseconds ms');
      
      // Set a reasonable threshold based on your requirements
      expect(elapsedMilliseconds, lessThan(5000)); // Less than 5 seconds
    });
    
    test('Measure audio generation time for medium text', () async {
      await ttsService.initialize();
      
      final mediumText = 'This is a medium length text for performance testing. '
          'It contains multiple sentences and should be long enough to represent '
          'a typical assistant response. The performance of text-to-speech generation '
          'should be measured to ensure it meets the requirements for a good user experience.';
      
      final stopwatch = Stopwatch()..start();
      
      await ttsService.generateAudio(mediumText);
      
      stopwatch.stop();
      final elapsedMilliseconds = stopwatch.elapsedMilliseconds;
      
      print('Medium text audio generation took: $elapsedMilliseconds ms');
      
      // Set a reasonable threshold based on your requirements
      expect(elapsedMilliseconds, lessThan(10000)); // Less than 10 seconds
    });
    
    test('Memory usage during audio generation', () async {
      await ttsService.initialize();
      
      // Generate multiple audio files and check memory usage
      for (int i = 0; i < 5; i++) {
        await ttsService.generateAudio(
          'Test message number $i for memory usage testing. '
          'This should generate a reasonable sized audio file.'
        );
      }
      
      // The actual memory measurement would require platform-specific code
      // In a real test, you might use a memory profiler or platform channels
      // For this example, we're just ensuring the function completes without errors
      expect(true, isTrue); 
    });
  });
}
```

## Testing Steps

1. Run end-to-end tests:
```bash
flutter test test/features/audio_assistant/integration/audio_assistant_e2e_test.dart
```

2. Run performance tests (these will likely need to be run on a real device):
```bash
flutter test test/features/audio_assistant/performance/tts_performance_test.dart
```

3. Execute the manual testing script on both iOS and Android devices.

## Completion Checklist

- [ ] Created comprehensive end-to-end tests
- [ ] Created manual testing script
- [ ] Created performance testing script
- [ ] Verified all automated tests pass
- [ ] Completed manual testing on iOS device
- [ ] Completed manual testing on Android device
- [ ] Documented any issues or performance concerns
- [ ] Verified all features work as expected

## Next Steps

After completing the end-to-end testing, proceed to Task 6: Error Handling and Recovery to implement robust error handling for the audio assistant feature. 