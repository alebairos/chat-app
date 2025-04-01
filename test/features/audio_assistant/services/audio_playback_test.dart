import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/models/playback_state.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback.dart';

// Mock implementation of AudioPlayback for testing
class MockAudioPlayback implements AudioPlayback {
  bool _initialized = false;
  AudioFile? _loadedFile;
  PlaybackState _state = PlaybackState.initial;
  int _position = 0;
  int _duration = 0;
  Timer? _positionTimer;

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  final StreamController<int> _positionController =
      StreamController<int>.broadcast();

  @override
  Future<bool> initialize() async {
    _initialized = true;
    return true;
  }

  @override
  Future<bool> load(AudioFile file) async {
    if (!_initialized) {
      return false;
    }

    _loadedFile = file;
    _duration = file.duration.inMilliseconds;
    _position = 0;
    _updateState(PlaybackState.loading);

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 100));

    _updateState(PlaybackState.stopped);
    return true;
  }

  @override
  Future<bool> play() async {
    if (!_initialized || _loadedFile == null) {
      return false;
    }

    if (_state == PlaybackState.playing) {
      return true; // Already playing
    }

    _updateState(PlaybackState.playing);

    // Simulate position updates during playback
    _startPositionUpdates();

    return true;
  }

  @override
  Future<bool> pause() async {
    if (!_initialized || _loadedFile == null) {
      return false;
    }

    if (_state != PlaybackState.playing) {
      return false; // Not playing
    }

    _updateState(PlaybackState.paused);
    _stopPositionUpdates();
    return true;
  }

  @override
  Future<bool> stop() async {
    if (!_initialized || _loadedFile == null) {
      return false;
    }

    if (_state == PlaybackState.stopped) {
      return true; // Already stopped
    }

    _position = 0;
    _updateState(PlaybackState.stopped);
    _stopPositionUpdates();
    return true;
  }

  @override
  Future<bool> seekTo(int position) async {
    if (!_initialized || _loadedFile == null) {
      return false;
    }

    if (position < 0 || position > _duration) {
      return false; // Invalid position
    }

    _position = position;
    _positionController.add(_position);
    return true;
  }

  @override
  Future<int> get position async => _position;

  @override
  Future<int> get duration async => _duration;

  @override
  PlaybackState get state => _state;

  @override
  Stream<PlaybackState> get onStateChanged => _stateController.stream;

  @override
  Stream<int> get onPositionChanged => _positionController.stream;

  @override
  Future<void> dispose() async {
    _stopPositionUpdates();
    await _stateController.close();
    await _positionController.close();
  }

  void _updateState(PlaybackState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void _startPositionUpdates() {
    _stopPositionUpdates(); // Cancel any existing timer

    // Simulate position updates during playback
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_state != PlaybackState.playing ||
          _stateController.isClosed ||
          _positionController.isClosed) {
        timer.cancel();
        return;
      }

      _position += 100;
      if (_position >= _duration) {
        _position = _duration;
        _updateState(PlaybackState.stopped);
        timer.cancel();
      }

      if (!_positionController.isClosed) {
        _positionController.add(_position);
      }
    });
  }

  void _stopPositionUpdates() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }
}

void main() {
  group('AudioPlayback', () {
    late MockAudioPlayback audioPlayback;
    late AudioFile testFile;

    setUp(() {
      audioPlayback = MockAudioPlayback();
      testFile = const AudioFile(
        path: '/test/audio.mp3',
        duration: Duration(seconds: 5),
      );
    });

    tearDown(() async {
      await audioPlayback.dispose();
    });

    test('should initialize successfully', () async {
      final result = await audioPlayback.initialize();

      expect(result, true);
    });

    test('should load audio file', () async {
      await audioPlayback.initialize();

      final result = await audioPlayback.load(testFile);

      expect(result, true);
      expect(audioPlayback.state, PlaybackState.stopped);
      expect(await audioPlayback.duration, testFile.duration.inMilliseconds);
      expect(await audioPlayback.position, 0);
    });

    test('should not load file if not initialized', () async {
      final result = await audioPlayback.load(testFile);

      expect(result, false);
    });

    test('should play loaded audio file', () async {
      await audioPlayback.initialize();
      await audioPlayback.load(testFile);

      final result = await audioPlayback.play();

      expect(result, true);
      expect(audioPlayback.state, PlaybackState.playing);

      // Make sure to stop playback before the test ends
      await audioPlayback.stop();
    });

    test('should not play if no file is loaded', () async {
      await audioPlayback.initialize();

      final result = await audioPlayback.play();

      expect(result, false);
      expect(audioPlayback.state, PlaybackState.initial);
    });

    test('should pause playing audio', () async {
      await audioPlayback.initialize();
      await audioPlayback.load(testFile);
      await audioPlayback.play();

      final result = await audioPlayback.pause();

      expect(result, true);
      expect(audioPlayback.state, PlaybackState.paused);
    });

    test('should not pause if not playing', () async {
      await audioPlayback.initialize();
      await audioPlayback.load(testFile);

      final result = await audioPlayback.pause();

      expect(result, false);
      expect(audioPlayback.state, PlaybackState.stopped);
    });

    test('should stop playing audio', () async {
      await audioPlayback.initialize();
      await audioPlayback.load(testFile);
      await audioPlayback.play();

      final result = await audioPlayback.stop();

      expect(result, true);
      expect(audioPlayback.state, PlaybackState.stopped);
      expect(await audioPlayback.position, 0);
    });

    test('should seek to position', () async {
      await audioPlayback.initialize();
      await audioPlayback.load(testFile);

      final result = await audioPlayback.seekTo(2000);

      expect(result, true);
      expect(await audioPlayback.position, 2000);
    });

    test('should not seek to invalid position', () async {
      await audioPlayback.initialize();
      await audioPlayback.load(testFile);

      final result = await audioPlayback.seekTo(-1000);

      expect(result, false);
      expect(await audioPlayback.position, 0);
    });

    test('should emit state changes', () async {
      await audioPlayback.initialize();

      final states = <PlaybackState>[];
      final subscription = audioPlayback.onStateChanged.listen(states.add);

      await audioPlayback.load(testFile);
      await audioPlayback.play();
      await audioPlayback.pause();
      await audioPlayback.stop();

      // Wait for all events to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      expect(states, contains(PlaybackState.loading));
      expect(states, contains(PlaybackState.stopped));
      expect(states, contains(PlaybackState.playing));
      expect(states, contains(PlaybackState.paused));

      await subscription.cancel();
    });

    test('should emit position changes during playback', () async {
      await audioPlayback.initialize();
      await audioPlayback.load(testFile);

      final positions = <int>[];
      final subscription =
          audioPlayback.onPositionChanged.listen(positions.add);

      await audioPlayback.play();

      // Wait for some position updates
      await Future.delayed(const Duration(milliseconds: 250));

      // Stop playback before checking results
      await audioPlayback.stop();

      expect(positions.length, greaterThan(0));
      expect(positions.last, greaterThan(0));

      await subscription.cancel();
    });
  });
}
