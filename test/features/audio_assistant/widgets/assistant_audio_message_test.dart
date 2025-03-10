import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/models/playback_state.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/assistant_audio_message.dart';

class MockAudioPlayback extends Mock implements AudioPlayback {
  final _stateController = StreamController<PlaybackState>.broadcast();
  final _positionController = StreamController<int>.broadcast();
  PlaybackState _state = PlaybackState.stopped;
  int _position = 0;
  bool _initialized = false;
  AudioFile? _loadedFile;

  @override
  Future<bool> initialize() async {
    _initialized = true;
    return true;
  }

  @override
  Future<bool> load(AudioFile file) async {
    _loadedFile = file;
    _state = PlaybackState.paused;
    _stateController.add(_state);
    return true;
  }

  @override
  Future<bool> play() async {
    _state = PlaybackState.playing;
    _stateController.add(_state);
    // Simulate position updates
    _startPositionUpdates();
    return true;
  }

  @override
  Future<bool> pause() async {
    _state = PlaybackState.paused;
    _stateController.add(_state);
    return true;
  }

  @override
  Future<bool> stop() async {
    _state = PlaybackState.stopped;
    _position = 0;
    _stateController.add(_state);
    _positionController.add(_position);
    return true;
  }

  @override
  Future<bool> seekTo(int position) async {
    _position = position;
    _positionController.add(_position);
    return true;
  }

  @override
  Future<int> get position async => _position;

  @override
  Future<int> get duration async => _loadedFile?.duration.inMilliseconds ?? 0;

  @override
  PlaybackState get state => _state;

  @override
  Stream<PlaybackState> get onStateChanged => _stateController.stream;

  @override
  Stream<int> get onPositionChanged => _positionController.stream;

  void _startPositionUpdates() {
    // Simulate position updates every 100ms
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_state == PlaybackState.playing && !_positionController.isClosed) {
        _position += 100;
        _positionController.add(_position);

        // Stop at the end of the file
        if (_loadedFile != null &&
            _position >= _loadedFile!.duration.inMilliseconds) {
          _state = PlaybackState.stopped;
          _stateController.add(_state);
          return false;
        }
      }
      return _state == PlaybackState.playing;
    });
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _positionController.close();
  }
}

void main() {
  group('AssistantAudioMessage', () {
    late MockAudioPlayback mockAudioPlayback;
    late AudioFile testAudioFile;

    setUp(() {
      mockAudioPlayback = MockAudioPlayback();
      testAudioFile = const AudioFile(
        path: 'test_path.mp3',
        duration: Duration(seconds: 30),
      );
    });

    tearDown(() {
      mockAudioPlayback.dispose();
    });

    testWidgets('renders correctly with initial state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioFile: testAudioFile,
              transcription: 'Test transcription',
              audioPlayback: mockAudioPlayback,
            ),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.text('Test transcription'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget); // Current position
      expect(find.text('00:30'), findsOneWidget); // Duration
    });

    testWidgets('toggles play/pause when button is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioFile: testAudioFile,
              transcription: 'Test transcription',
              audioPlayback: mockAudioPlayback,
            ),
          ),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Tap the play button
      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.pump();

      // Verify play was called
      expect(mockAudioPlayback.state, equals(PlaybackState.playing));

      // Wait for UI to update
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the pause button
      await tester.tap(find.byIcon(Icons.pause_circle_filled));
      await tester.pump();

      // Verify pause was called
      expect(mockAudioPlayback.state, equals(PlaybackState.paused));
    });

    testWidgets('updates position during playback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantAudioMessage(
              audioFile: testAudioFile,
              transcription: 'Test transcription',
              audioPlayback: mockAudioPlayback,
            ),
          ),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Tap the play button
      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.pump();

      // Wait for position to update
      await tester.pump(const Duration(milliseconds: 200));

      // Verify position text has changed from 00:00
      expect(find.text('00:00'), findsNothing);
    });
  });
}
