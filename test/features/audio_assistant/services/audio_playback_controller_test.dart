import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/models/playback_state.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback_controller.dart';

// Mock for AudioPlayer
class MockAudioPlayer extends Mock implements AudioPlayer {
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<void> _completionController =
      StreamController<void>.broadcast();

  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 5);
  Timer? _positionUpdateTimer;

  @override
  Stream<PlayerState> get onPlayerStateChanged => _playerStateController.stream;

  @override
  Stream<Duration> get onPositionChanged => _positionController.stream;

  @override
  Stream<void> get onPlayerComplete => _completionController.stream;

  @override
  Future<void> setSourceDeviceFile(String path) async {
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 50));
    return;
  }

  @override
  Future<void> resume() async {
    _state = PlayerState.playing;
    if (!_playerStateController.isClosed) {
      _playerStateController.add(_state);
    }
    _startPositionUpdates();
    return;
  }

  @override
  Future<void> pause() async {
    _state = PlayerState.paused;
    if (!_playerStateController.isClosed) {
      _playerStateController.add(_state);
    }
    _stopPositionUpdates();
    return;
  }

  @override
  Future<void> stop() async {
    _state = PlayerState.stopped;
    _position = Duration.zero;
    if (!_playerStateController.isClosed) {
      _playerStateController.add(_state);
    }
    if (!_positionController.isClosed) {
      _positionController.add(_position);
    }
    _stopPositionUpdates();
    return;
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    if (!_positionController.isClosed) {
      _positionController.add(_position);
    }
    return;
  }

  @override
  Future<Duration?> getCurrentPosition() async {
    return _position;
  }

  @override
  Future<Duration?> getDuration() async {
    return _duration;
  }

  @override
  Future<void> dispose() async {
    _stopPositionUpdates();

    if (!_playerStateController.isClosed) {
      await _playerStateController.close();
    }

    if (!_positionController.isClosed) {
      await _positionController.close();
    }

    if (!_completionController.isClosed) {
      await _completionController.close();
    }

    return;
  }

  // Helper method to simulate playback completion
  void simulateCompletion() {
    _state = PlayerState.completed;
    _position = _duration;
    _stopPositionUpdates();

    if (!_playerStateController.isClosed) {
      _playerStateController.add(_state);
    }

    if (!_positionController.isClosed) {
      _positionController.add(_position);
    }

    if (!_completionController.isClosed) {
      _completionController.add(null);
    }
  }

  // Helper method to simulate position updates during playback
  void _startPositionUpdates() {
    _stopPositionUpdates();

    _positionUpdateTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_state != PlayerState.playing ||
          _playerStateController.isClosed ||
          _positionController.isClosed) {
        timer.cancel();
        return;
      }

      _position += const Duration(milliseconds: 100);
      if (_position >= _duration) {
        simulateCompletion();
        timer.cancel();
        return;
      }

      if (!_positionController.isClosed) {
        _positionController.add(_position);
      }
    });
  }

  void _stopPositionUpdates() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = null;
  }

  // Set a custom duration for testing
  void setDuration(Duration duration) {
    _duration = duration;
  }
}

void main() {
  late AudioPlaybackController controller;
  late MockAudioPlayer mockPlayer;
  late AudioFile testFile;

  setUp(() {
    mockPlayer = MockAudioPlayer();
    controller = AudioPlaybackController(mockPlayer);
    testFile = const AudioFile(
      path: '/test/audio.mp3',
      duration: Duration(seconds: 5),
    );
  });

  tearDown(() async {
    // Make sure to stop any ongoing playback
    if (controller.state == PlaybackState.playing) {
      await controller.stop();
    }
    await controller.dispose();
  });

  group('AudioPlaybackController', () {
    test('should initialize successfully', () async {
      final result = await controller.initialize();

      expect(result, true);
    });

    test('should load audio file', () async {
      await controller.initialize();

      final result = await controller.load(testFile);

      expect(result, true);
      expect(controller.state, PlaybackState.stopped);
    });

    test('should not load file if not initialized', () async {
      final result = await controller.load(testFile);

      expect(result, false);
    });

    test('should play loaded audio file', () async {
      await controller.initialize();
      await controller.load(testFile);

      final result = await controller.play();

      expect(result, true);
      expect(controller.state, PlaybackState.playing);

      // Stop playback to prevent timer issues
      await controller.stop();
    });

    test('should not play if no file is loaded', () async {
      await controller.initialize();

      final result = await controller.play();

      expect(result, false);
    });

    test('should pause playing audio', () async {
      await controller.initialize();
      await controller.load(testFile);
      await controller.play();

      final result = await controller.pause();

      expect(result, true);
      expect(controller.state, PlaybackState.paused);
    });

    test('should not pause if not playing', () async {
      await controller.initialize();
      await controller.load(testFile);

      final result = await controller.pause();

      expect(result, false);
    });

    test('should stop playing audio', () async {
      await controller.initialize();
      await controller.load(testFile);
      await controller.play();

      final result = await controller.stop();

      expect(result, true);
      expect(controller.state, PlaybackState.stopped);
    });

    test('should seek to position', () async {
      await controller.initialize();
      await controller.load(testFile);

      final result = await controller.seekTo(2000);

      expect(result, true);
      expect(await controller.position, 2000);
    });

    test('should emit state changes', () async {
      await controller.initialize();

      final states = <PlaybackState>[];
      final subscription = controller.onStateChanged.listen(states.add);

      await controller.load(testFile);
      await controller.play();
      await controller.pause();
      await controller.stop();

      // Wait for all events to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, contains(PlaybackState.loading));
      expect(states, contains(PlaybackState.stopped));
      expect(states, contains(PlaybackState.playing));
      expect(states, contains(PlaybackState.paused));

      await subscription.cancel();
    });

    test('should emit position changes during playback', () async {
      await controller.initialize();
      await controller.load(testFile);

      final positions = <int>[];
      final subscription = controller.onPositionChanged.listen(positions.add);

      await controller.play();

      // Wait for some position updates
      await Future.delayed(const Duration(milliseconds: 250));

      // Stop playback before checking results
      await controller.stop();

      expect(positions.length, greaterThan(0));
      expect(positions.last, greaterThan(0));

      await subscription.cancel();
    });

    test('should handle playback completion', () async {
      await controller.initialize();
      await controller.load(testFile);
      await controller.play();

      // Simulate playback completion
      mockPlayer.simulateCompletion();

      // Wait for state to update
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state, PlaybackState.stopped);
    });
  });
}
