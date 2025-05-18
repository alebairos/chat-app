# Task 6: Error Handling and Recovery

## Overview

This task involves implementing robust error handling and recovery mechanisms for the audio assistant feature. Proper error handling is critical for maintaining a good user experience, especially when dealing with network requests, audio generation, and playback.

## Prerequisites

- Completed Task 5: End-to-End Testing
- Working audio assistant feature with basic error handling

## Implementation Steps

### Step 1: Identify Error Scenarios

First, identify all potential error scenarios in the audio assistant feature:

1. **TTS Service Errors**:
   - Initialization failure
   - Audio generation failure
   - Network connectivity issues during generation
   - API rate limiting or quotas
   - Invalid API credentials

2. **Audio Playback Errors**:
   - File not found
   - Corrupted audio file
   - Playback initialization failure
   - System audio errors
   - Permission issues

3. **Network and API Errors**:
   - Connection timeout
   - Server errors
   - Authentication failures
   - Malformed responses

4. **File System Errors**:
   - Insufficient storage
   - Permission issues
   - File operation failures

### Step 2: Enhance TTS Service Error Handling

Update the AudioAssistantTTSService to handle errors more robustly:

```dart
// lib/features/audio_assistant/tts_service.dart
class TTSError extends Error {
  final String message;
  final String code;
  final dynamic originalError;

  TTSError(this.message, {this.code = 'unknown', this.originalError});

  @override
  String toString() => 'TTSError: $message (code: $code)';
}

class AudioAssistantTTSService {
  // Add retry configuration
  int _maxRetries = 3;
  Duration _retryDelay = Duration(seconds: 1);

  // Add method to customize retry policy
  void setRetryPolicy({int maxRetries = 3, Duration? retryDelay}) {
    _maxRetries = maxRetries;
    if (retryDelay != null) _retryDelay = retryDelay;
  }

  // Update generateAudio with retry logic
  Future<String?> generateAudio(String text) async {
    if (text.isEmpty) {
      _logger.warning('Attempted to generate audio for empty text');
      return null;
    }

    if (!_initialized) {
      final success = await initialize();
      if (!success) {
        throw TTSError('TTS service not initialized', code: 'initialization_failed');
      }
    }

    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        attempts++;
        
        // Original generation logic...
        final result = await _currentProvider!.generateAudio(text);
        
        if (result == null) {
          _logger.error('Audio generation failed on attempt $attempts');
          if (attempts < _maxRetries) {
            _logger.info('Retrying in ${_retryDelay.inSeconds} seconds...');
            await Future.delayed(_retryDelay);
            continue;
          }
          throw TTSError('Audio generation failed after $attempts attempts', 
            code: 'generation_failed');
        }
        
        return result;
      } catch (e) {
        _logger.error('Error generating audio on attempt $attempts: $e');
        
        // Determine if we should retry based on error type
        if (_shouldRetryError(e) && attempts < _maxRetries) {
          _logger.info('Retrying in ${_retryDelay.inSeconds} seconds...');
          await Future.delayed(_retryDelay);
          continue;
        }
        
        // Convert to structured error
        if (e is TTSError) rethrow;
        
        String errorCode = 'unknown';
        if (e.toString().contains('network')) errorCode = 'network_error';
        if (e.toString().contains('timeout')) errorCode = 'timeout';
        if (e.toString().contains('rate limit')) errorCode = 'rate_limited';
        if (e.toString().contains('quota')) errorCode = 'quota_exceeded';
        if (e.toString().contains('authorization')) errorCode = 'auth_error';
        
        throw TTSError('Failed to generate audio: ${e.toString()}', 
          code: errorCode, originalError: e);
      }
    }
    
    return null;
  }
  
  // Helper method to determine if error is retriable
  bool _shouldRetryError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('timeout') || 
           errorString.contains('connection') ||
           errorString.contains('rate limit') ||
           errorString.contains('server');
  }
}
```

### Step 3: Enhance ClaudeService Error Handling

Update the ClaudeService to handle TTS errors more gracefully:

```dart
// lib/services/claude_service.dart
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
        return ClaudeAudioResponse(
          text: textResponse,
          error: 'TTS service initialization failed',
        );
      }
      
      // Generate audio with exponential backoff
      int maxRetries = 3;
      for (int i = 0; i < maxRetries; i++) {
        try {
          final audioPath = await _ttsService!.generateAudio(textResponse);
          
          // If audio generation failed, return text only with error
          if (audioPath == null) {
            _logger.error('Failed to generate audio for response');
            return ClaudeAudioResponse(
              text: textResponse,
              error: 'Audio generation failed',
            );
          }
          
          _logger.debug('Generated audio at path: $audioPath');
          
          // Return both text and audio path
          return ClaudeAudioResponse(
            text: textResponse,
            audioPath: audioPath,
          );
        } catch (ttsError) {
          // Check if we should retry
          if (i < maxRetries - 1 && _shouldRetryTTSError(ttsError)) {
            _logger.warning('TTS error, retrying (${i+1}/$maxRetries): $ttsError');
            await Future.delayed(Duration(milliseconds: 200 * pow(2, i).toInt()));
            continue;
          }
          
          // If we've used all retries or it's not retriable, return with error
          _logger.error('TTS error after retries: $ttsError');
          return ClaudeAudioResponse(
            text: textResponse,
            error: _handleTTSError(ttsError),
          );
        }
      }
      
      // This should not be reached, but just in case
      return ClaudeAudioResponse(
        text: textResponse,
        error: 'Failed to generate audio after multiple attempts',
      );
    } catch (e) {
      _logger.error('Error generating audio for response: $e');
      return ClaudeAudioResponse(
        text: textResponse,
        error: _handleTTSError(e),
      );
    }
  } catch (e) {
    final errorMessage = _getUserFriendlyErrorMessage(e.toString());
    _logger.error('Error in sendMessageWithAudio: $e');
    return ClaudeAudioResponse(
      text: errorMessage,
      error: 'Failed to generate AI response',
    );
  }
}

// Helper to determine if a TTS error should be retried
bool _shouldRetryTTSError(dynamic error) {
  final errorString = error.toString().toLowerCase();
  return errorString.contains('network') || 
         errorString.contains('timeout') || 
         errorString.contains('connection') ||
         errorString.contains('rate limit') ||
         errorString.contains('server');
}
```

### Step 4: Update ClaudeAudioResponse Model

Update the ClaudeAudioResponse model to include error information:

```dart
// lib/models/claude_audio_response.dart
class ClaudeAudioResponse {
  final String text;
  final String? audioPath;
  final Duration? audioDuration;
  final String? error;  // Add error field

  ClaudeAudioResponse({
    required this.text,
    this.audioPath,
    this.audioDuration,
    this.error,
  });

  bool get hasAudio => audioPath != null;
  bool get hasError => error != null;

  @override
  String toString() {
    return 'ClaudeAudioResponse(text: ${text.length > 20 ? '${text.substring(0, 20)}...' : text}, '
        'audioPath: $audioPath, audioDuration: $audioDuration, error: $error)';
  }
}
```

### Step 5: Enhance ChatScreen Error Handling

Update the ChatScreen to handle audio-related errors more gracefully:

```dart
// lib/screens/chat_screen.dart
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

    // Check for audio-specific errors
    if (response.hasError && response.error!.isNotEmpty) {
      // Show audio error notification, but still proceed with text
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio Error: ${response.error}'),
            backgroundColor: Colors.orange,  // Use a different color for non-critical errors
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry Audio',
              onPressed: () => _retryAudioGeneration(response.text),
            ),
          ),
        );
      }
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

// Add method to retry audio generation
Future<void> _retryAudioGeneration(String text) async {
  if (!_audioEnabled || _ttsService == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio is disabled or TTS service is unavailable'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return;
  }
  
  setState(() {
    _isGeneratingAudio = true;
  });
  
  try {
    await _ttsService.initialize();
    final audioPath = await _ttsService.generateAudio(text);
    
    if (audioPath == null) {
      throw Exception('Failed to generate audio');
    }
    
    // Find the message in storage
    final isar = await _storageService.db;
    final messages = await isar.chatMessageModels
        .filter()
        .textEqualTo(text)
        .isUserEqualTo(false)
        .findAll();
    
    if (messages.isEmpty) {
      throw Exception('Message not found');
    }
    
    // Update the message with audio path
    final message = messages.first;
    message.type = MessageType.audio;
    message.mediaPath = audioPath;
    
    await isar.writeTxn(() async {
      await isar.chatMessageModels.put(message);
    });
    
    // Refresh UI
    await _loadMessages();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio generated successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate audio: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } finally {
    setState(() {
      _isGeneratingAudio = false;
    });
  }
}
```

### Step 6: Enhance AssistantAudioMessage Error Handling

Improve error handling in the AssistantAudioMessage widget:

```dart
// lib/features/audio_assistant/widgets/assistant_audio_message.dart
class _AssistantAudioMessageState extends State<AssistantAudioMessage> {
  // Add error tracking
  String? _errorMessage;
  bool _fileExists = false;
  bool _hasCheckedFile = false;
  
  @override
  void initState() {
    super.initState();
    _verifyFileExists();
    _subscribeToPlaybackUpdates();
  }
  
  // Add method to verify file exists
  Future<void> _verifyFileExists() async {
    if (widget.audioPath == null) {
      setState(() {
        _errorMessage = 'No audio file path provided';
        _hasCheckedFile = true;
        _fileExists = false;
      });
      return;
    }
    
    try {
      final file = File(widget.audioPath!);
      final exists = await file.exists();
      
      setState(() {
        _fileExists = exists;
        _hasCheckedFile = true;
        if (!exists) {
          _errorMessage = 'Audio file not found';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error accessing audio file: $e';
        _hasCheckedFile = true;
        _fileExists = false;
      });
    }
  }
  
  // Update play method with error handling
  Future<void> _play() async {
    if (!_fileExists) {
      setState(() {
        _errorMessage = 'Audio file not found';
      });
      widget.onError?.call('Audio file not found');
      return;
    }
    
    try {
      await widget.playbackManager.play(widget.audioPath!);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error playing audio: $e';
      });
      widget.onError?.call('Error playing audio: $e');
    }
  }
  
  // Add retry button
  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.refresh),
      label: Text('Retry'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        setState(() {
          _errorMessage = null;
          _hasCheckedFile = false;
        });
        _verifyFileExists();
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Show error message if there's an error
    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original text content
          widget.transcription != null
              ? GestureDetector(
                  onTap: _toggleTranscription,
                  child: Text(
                    _showFullTranscription
                        ? widget.transcription!
                        : _getShortTranscription(),
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                )
              : SizedBox(),
          SizedBox(height: 8),
          
          // Error message
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
                _buildRetryButton(),
              ],
            ),
          ),
        ],
      );
    }
    
    // Show loading while checking file
    if (!_hasCheckedFile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original text content
          widget.transcription != null
              ? Text(
                  _getShortTranscription(),
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                )
              : SizedBox(),
          SizedBox(height: 8),
          
          // Loading indicator
          Center(
            child: SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }
    
    // Original UI if no errors
    return Column(/* original widget implementation */);
  }
}
```

### Step 7: Update Tests for Error Handling

Update tests to verify the new error handling mechanisms:

```dart
// test/features/audio_assistant/error_handling_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:character_ai_clone/features/audio_assistant/tts_service.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/models/claude_audio_response.dart';

class MockAudioAssistantTTSService extends Mock implements AudioAssistantTTSService {}

void main() {
  group('Error Handling Tests', () {
    late MockAudioAssistantTTSService mockTTSService;
    late ClaudeService claudeService;

    setUp(() {
      mockTTSService = MockAudioAssistantTTSService();
      claudeService = ClaudeService(
        ttsService: mockTTSService,
      );
    });

    test('TTS initialization failure is handled gracefully', () async {
      // Setup mock
      when(() => mockTTSService.initialize()).thenAnswer((_) async => false);
      when(() => claudeService.sendMessage(any())).thenAnswer((_) async => 'Test response');
      
      // Act
      final response = await claudeService.sendMessageWithAudio('Test message');
      
      // Assert
      expect(response.text, equals('Test response'));
      expect(response.audioPath, isNull);
      expect(response.error, isNotNull);
      expect(response.error, contains('initialization failed'));
    });

    test('TTS generation failure is handled gracefully', () async {
      // Setup mock
      when(() => mockTTSService.initialize()).thenAnswer((_) async => true);
      when(() => mockTTSService.generateAudio(any())).thenAnswer((_) async => null);
      when(() => claudeService.sendMessage(any())).thenAnswer((_) async => 'Test response');
      
      // Act
      final response = await claudeService.sendMessageWithAudio('Test message');
      
      // Assert
      expect(response.text, equals('Test response'));
      expect(response.audioPath, isNull);
      expect(response.error, isNotNull);
      expect(response.error, contains('generation failed'));
    });

    test('TTS network error is retried', () async {
      // Setup mock
      when(() => mockTTSService.initialize()).thenAnswer((_) async => true);
      
      // First call fails with network error, second call succeeds
      var callCount = 0;
      when(() => mockTTSService.generateAudio(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('network error');
        }
        return 'audio_path.mp3';
      });
      
      when(() => claudeService.sendMessage(any())).thenAnswer((_) async => 'Test response');
      
      // Act
      final response = await claudeService.sendMessageWithAudio('Test message');
      
      // Assert
      expect(response.text, equals('Test response'));
      expect(response.audioPath, equals('audio_path.mp3'));
      expect(response.error, isNull);
      verify(() => mockTTSService.generateAudio(any())).called(2);
    });

    test('TTS gives up after max retries', () async {
      // Setup mock
      when(() => mockTTSService.initialize()).thenAnswer((_) async => true);
      
      // All calls fail with network error
      when(() => mockTTSService.generateAudio(any()))
          .thenThrow(Exception('network error'));
      
      when(() => claudeService.sendMessage(any())).thenAnswer((_) async => 'Test response');
      
      // Act
      final response = await claudeService.sendMessageWithAudio('Test message');
      
      // Assert
      expect(response.text, equals('Test response'));
      expect(response.audioPath, isNull);
      expect(response.error, isNotNull);
      verify(() => mockTTSService.generateAudio(any())).called(3); // 3 is the max retries
    });
  });
}
```

## Testing Steps

1. Run the error handling tests:
```bash
flutter test test/features/audio_assistant/error_handling_test.dart
```

2. Run all tests to verify the error handling doesn't break existing functionality:
```bash
flutter test
```

3. Manually test error scenarios:
```bash
flutter run
```

- Test with network disabled
- Test with invalid audio file paths
- Test with corrupted audio files

## Completion Checklist

- [ ] Identified all potential error scenarios
- [ ] Enhanced TTS service with retry logic and error handling
- [ ] Updated ClaudeService to handle TTS errors gracefully
- [ ] Updated ClaudeAudioResponse model to include error information
- [ ] Enhanced ChatScreen error handling for audio-related errors
- [ ] Enhanced AssistantAudioMessage error handling
- [ ] Added comprehensive error handling tests
- [ ] Manually tested error scenarios
- [ ] Verified all tests pass

## Next Steps

After completing the error handling and recovery implementation, proceed to Task 7: Performance Optimization to ensure the audio assistant feature performs optimally in all scenarios. 