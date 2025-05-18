# Task 3: ChatMessageModel Updates

## Overview

This task involves reviewing and potentially updating the `ChatMessageModel` to ensure it fully supports audio messages. The model already has basic audio support, but we need to ensure it's properly configured for integration with the audio assistant feature.

## Prerequisites

- Completed Task 2: ClaudeService TTS Integration
- Existing `ChatMessageModel` with basic fields for media path and duration

## Implementation Steps

### Step 1: Review Current ChatMessageModel

First, review the existing `ChatMessageModel` to confirm it has the necessary fields to support audio:

Required fields:
- text: The text content of the message (or transcription for audio)
- type: A MessageType enum value that includes audio
- mediaPath: Path to the audio file
- duration: Duration of the audio file

### Step 2: Create Test File for ChatMessageModel Audio Support

Create a test file to verify audio-specific functionality:

```dart
// test/models/chat_message_audio_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/models/chat_message_model.dart';
import 'package:character_ai_clone/models/message_type.dart';

void main() {
  group('ChatMessageModel Audio Support', () {
    test('ChatMessageModel stores audio path correctly', () {
      final model = ChatMessageModel(
        text: 'Test transcription',
        isUser: false,
        type: MessageType.audio,
        timestamp: DateTime.now(),
        mediaPath: 'audio_path/test.mp3',
      );
      
      expect(model.mediaPath, equals('audio_path/test.mp3'));
      expect(model.type, equals(MessageType.audio));
    });
    
    test('ChatMessageModel stores duration correctly', () {
      final duration = Duration(seconds: 30);
      final model = ChatMessageModel(
        text: 'Test transcription',
        isUser: false,
        type: MessageType.audio,
        timestamp: DateTime.now(),
        duration: duration,
      );
      
      expect(model.duration, equals(duration));
      expect(model.durationInMillis, equals(30000));
    });
    
    test('ChatMessageModel copyWith preserves audio properties', () {
      final original = ChatMessageModel(
        text: 'Original text',
        isUser: false,
        type: MessageType.audio,
        timestamp: DateTime.now(),
        mediaPath: 'original_path.mp3',
        duration: Duration(seconds: 20),
      );
      
      final copied = original.copyWith(
        text: 'Updated text',
      );
      
      expect(copied.text, equals('Updated text'));
      expect(copied.mediaPath, equals('original_path.mp3'));
      expect(copied.duration?.inSeconds, equals(20));
      expect(copied.type, equals(MessageType.audio));
    });
  });
}
```

### Step 3: Update MessageType Enum if Needed

If the `MessageType` enum doesn't have an audio type, update it:

```dart
// lib/models/message_type.dart
enum MessageType {
  text,
  audio,
  image,
}
```

### Step 4: Update ChatMessageModel if Needed

If the review indicates any missing functionality, update the `ChatMessageModel` class:

```dart
// lib/models/chat_message_model.dart

// If any fields are missing, add them:
@collection
class ChatMessageModel {
  Id id = Isar.autoIncrement;

  @Index()
  DateTime timestamp;

  @Index()
  String text;

  bool isUser;

  @enumerated
  MessageType type;

  List<byte>? mediaData;

  String? mediaPath;

  @Index()
  int? durationInMillis;

  // Make sure the constructor includes all fields
  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.type,
    required this.timestamp,
    this.mediaData,
    this.mediaPath,
    Duration? duration,
  }) : durationInMillis = duration?.inMilliseconds;

  // Make sure the duration getter and setter are implemented
  @ignore
  Duration? get duration => durationInMillis != null
      ? Duration(milliseconds: durationInMillis!)
      : null;

  @ignore
  set duration(Duration? value) {
    durationInMillis = value?.inMilliseconds;
  }

  // Make sure copyWith includes all fields
  ChatMessageModel copyWith({
    Id? id,
    DateTime? timestamp,
    String? text,
    bool? isUser,
    MessageType? type,
    List<byte>? mediaData,
    String? mediaPath,
    Duration? duration,
  }) {
    final model = ChatMessageModel(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      mediaData: mediaData ?? this.mediaData,
      mediaPath: mediaPath ?? this.mediaPath,
      duration: duration ?? this.duration,
    );
    model.id = id ?? this.id;
    return model;
  }
}
```

## Testing Steps

1. Run the ChatMessageModel audio tests:
```bash
flutter test test/models/chat_message_audio_test.dart
```

2. Run all model tests to ensure no regressions:
```bash
flutter test test/models
```

3. Run all tests to verify overall integrity:
```bash
flutter test
```

## Completion Checklist

- [ ] Reviewed current ChatMessageModel for audio support
- [ ] Created tests for audio-specific functionality
- [ ] Verified or updated MessageType enum
- [ ] Made necessary updates to ChatMessageModel (if any)
- [ ] Verified all tests pass
- [ ] Verified no regressions in existing functionality

## Next Steps

After ensuring the ChatMessageModel properly supports audio messages, proceed to Task 4: ChatScreen Integration to update the ChatScreen to handle assistant audio messages. 