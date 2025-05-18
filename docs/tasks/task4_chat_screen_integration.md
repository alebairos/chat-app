# Task 4: ChatScreen Integration

## Overview

This task involves updating the `ChatScreen` to use the enhanced ClaudeService with audio capabilities and properly display audio messages from the assistant. This is a key step in bringing the audio assistant feature to users.

## Prerequisites

- Completed Task 3: ChatMessageModel Updates
- Working ClaudeService with audio support
- Working AssistantAudioMessage widget

## Implementation Steps

### Step 1: Create Integration Test

First, create an integration test for the ChatScreen audio integration:

```dart
// test/features/audio_assistant/integration/chat_screen_audio_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:character_ai_clone/screens/chat_screen.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/chat_storage_service.dart';
import 'package:character_ai_clone/models/claude_audio_response.dart';
import 'package:character_ai_clone/models/chat_message_model.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/assistant_audio_message.dart';

class MockClaudeService extends Mock implements ClaudeService {}
class MockChatStorageService extends Mock implements ChatStorageService {}

void main() {
  late MockClaudeService mockClaudeService;
  late MockChatStorageService mockStorageService;

  setUp(() {
    mockClaudeService = MockClaudeService();
    mockStorageService = MockChatStorageService();
    
    // Setup default behaviors
    when(() => mockClaudeService.initialize()).thenAnswer((_) async => true);
    when(() => mockStorageService.initialize()).thenAnswer((_) async => true);
    when(() => mockStorageService.getMessages(
      limit: any(named: 'limit'),
      before: any(named: 'before'),
    )).thenAnswer((_) async => []);
  });

  testWidgets('ChatScreen sends message and displays audio response', (WidgetTester tester) async {
    // Setup Claude service to return audio response
    when(() => mockClaudeService.sendMessageWithAudio(any())).thenAnswer((_) async => 
      ClaudeAudioResponse(
        text: 'Test assistant response',
        audioPath: 'test_audio.mp3',
        audioDuration: Duration(seconds: 10),
      )
    );
    
    // Setup storage service mock
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
          text: 'Test assistant response',
          isUser: false,
          type: MessageType.audio,
          timestamp: DateTime.now(),
          mediaPath: 'test_audio.mp3',
          duration: Duration(seconds: 10),
        ),
      ]);
    
    // Build the ChatScreen with mocked services
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          claudeService: mockClaudeService,
          storageService: mockStorageService,
          testMode: true,
        ),
      ),
    );
    
    // Enter a message
    await tester.enterText(find.byType(TextField), 'Test user message');
    
    // Tap send button
    await tester.tap(find.byIcon(Icons.send));
    
    // Rebuild widget
    await tester.pumpAndSettle();
    
    // Verify that the ClaudeService was called with audio
    verify(() => mockClaudeService.sendMessageWithAudio('Test user message')).called(1);
    
    // Verify the audio message is displayed
    expect(find.text('Test assistant response'), findsOneWidget);
    expect(find.byType(AssistantAudioMessage), findsOneWidget);
  });
}
```

### Step 2: Update ChatScreen to Use ClaudeService with Audio

Modify the ChatScreen to use the enhanced ClaudeService:

```dart
// lib/screens/chat_screen.dart

// Add imports
import '../features/audio_assistant/tts_service.dart';
import '../models/claude_audio_response.dart';
import '../features/audio_assistant/widgets/assistant_audio_message.dart';

class _ChatScreenState extends State<ChatScreen> {
  // Add audio-related fields if needed
  late final AudioAssistantTTSService _ttsService;
  bool _audioEnabled = true;

  @override
  void initState() {
    super.initState();
    _claudeService = widget.claudeService ?? ClaudeService();
    _storageService = widget.storageService ?? ChatStorageService();
    _ttsService = AudioAssistantTTSService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _claudeService.initialize();
      await _storageService.initialize();
      await _ttsService.initialize();
      
      // If ClaudeService doesn't already have a TTS service, provide one
      if (_claudeService is ClaudeService && 
          !(_claudeService as ClaudeService).hasOwnTTSService) {
        (_claudeService as ClaudeService).setTTSService(_ttsService);
      }
      
      // Migrate any existing absolute paths to relative paths
      await _storageService.migratePathsToRelative();

      // Then load messages
      await _loadMessages();
    } catch (e) {
      setState(() {
        _error = 'Error initializing services: $e';
        _isInitialLoading = false;
      });
      _logger.error('Error initializing services: $e');
    }
  }

  // Update the send message method to use audio
  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    final userMessageModel = ChatMessageModel(
      text: userMessage,
      isUser: true,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    try {
      // Save user message and get ID
      final isar = await _storageService.db;
      late final int messageId;
      await isar.writeTxn(() async {
        messageId = await isar.chatMessageModels.put(userMessageModel);
      });
      userMessageModel.id = messageId;

      setState(() {
        _messages.insert(0, _createChatMessage(userMessageModel));
        _isTyping = true;
      });
      _messageController.clear();
      _scrollToBottom();

      // Get AI response with audio
      final response = await _claudeService.sendMessageWithAudio(userMessage);

      // Check if the response contains an error message
      final bool isErrorResponse = response.text.startsWith('Error:') ||
          response.text.contains('Unable to connect') ||
          response.text.contains('experiencing high demand') ||
          response.text.contains('temporarily unavailable') ||
          response.text.contains('rate limit') ||
          response.text.contains('Authentication failed');

      if (isErrorResponse) {
        // Create a model for the error message
        final errorMessageModel = ChatMessageModel(
          text: response.text,
          isUser: false,
          type: MessageType.text,
          timestamp: DateTime.now(),
        );

        // Save to storage and get ID
        await isar.writeTxn(() async {
          final errorMessageId = await isar.chatMessageModels.put(errorMessageModel);
          errorMessageModel.id = errorMessageId;
        });

        // Display error message in UI
        setState(() {
          _messages.insert(0, _createChatMessage(errorMessageModel));
          _isTyping = false;
        });

        // Show error in snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.text),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Create AI message model with audio if available
      final aiMessageModel = ChatMessageModel(
        text: response.text,
        isUser: false,
        type: response.audioPath != null ? MessageType.audio : MessageType.text,
        timestamp: DateTime.now(),
        mediaPath: response.audioPath,
        duration: response.audioDuration,
      );

      // Save to storage
      await isar.writeTxn(() async {
        final aiMessageId = await isar.chatMessageModels.put(aiMessageModel);
        aiMessageModel.id = aiMessageId;
      });

      // Add to UI
      setState(() {
        _messages.insert(0, _createChatMessage(aiMessageModel));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.insert(
          0,
          const ChatMessage(
            text: 'Error: Unable to send message. Please try again later.',
            isUser: false,
          ),
        );
        _isTyping = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Make sure ChatMessage creation properly handles audio messages
  ChatMessage _createChatMessage(ChatMessageModel model) {
    return ChatMessage(
      key: ValueKey(model.id),
      text: model.text,
      isUser: model.isUser,
      audioPath: model.mediaPath,
      duration: model.duration,
      onDelete: () => _deleteMessage(model.id),
      onEdit: model.isUser ? (text) => _showEditDialog(model.id.toString(), text) : null,
    );
  }
}
```

### Step 3: Add Audio Toggle Setting (Optional)

Add a UI element to toggle audio responses on/off:

```dart
// Add to app bar or settings menu
IconButton(
  icon: Icon(_audioEnabled ? Icons.volume_up : Icons.volume_off),
  onPressed: () {
    setState(() {
      _audioEnabled = !_audioEnabled;
      // Update ClaudeService audio setting
      (_claudeService as ClaudeService).audioEnabled = _audioEnabled;
    });
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_audioEnabled 
          ? 'Assistant audio responses enabled' 
          : 'Assistant audio responses disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  },
),
```

### Step 4: Add Error Handling for Audio Playback

Ensure that the ChatScreen handles audio playback errors gracefully:

```dart
// Add method to handle audio errors
void _handleAudioError(String errorMessage) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Audio Error: $errorMessage'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Pass the error handler to ChatMessage
ChatMessage _createChatMessage(ChatMessageModel model) {
  return ChatMessage(
    key: ValueKey(model.id),
    text: model.text,
    isUser: model.isUser,
    audioPath: model.mediaPath,
    duration: model.duration,
    onDelete: () => _deleteMessage(model.id),
    onEdit: model.isUser ? (text) => _showEditDialog(model.id.toString(), text) : null,
    onAudioError: _handleAudioError,
  );
}
```

## Testing Steps

1. Run the ChatScreen integration tests:
```bash
flutter test test/features/audio_assistant/integration/chat_screen_audio_test.dart
```

2. Run all ChatScreen tests to ensure no regressions:
```bash
flutter test test/screens/chat_screen_test.dart
```

3. Run the app to manually test audio integration:
```bash
flutter run
```

- Send a message and verify an audio response is received
- Verify the audio plays correctly when tapped
- Verify the audio can be paused
- Verify the audio transcript is displayed correctly

## Completion Checklist

- [ ] Created integration tests for ChatScreen audio functionality
- [ ] Updated ChatScreen to use ClaudeService with audio capability
- [ ] Handled audio responses in message display
- [ ] Added audio toggle setting (optional)
- [ ] Added error handling for audio playback
- [ ] Verified tests pass for both unit and integration tests
- [ ] Manually tested the audio message functionality

## Next Steps

After completing the ChatScreen integration, proceed to Task 5: End-to-End Testing to create comprehensive tests for the entire audio assistant feature flow. 