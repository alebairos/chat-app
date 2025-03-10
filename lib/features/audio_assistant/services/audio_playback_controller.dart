import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../models/audio_file.dart';
import '../models/playback_state.dart';
import 'audio_playback.dart';
import 'package:flutter/foundation.dart';

/// A controller that handles audio playback using the audioplayers package.
///
/// This class implements the [AudioPlayback] interface and provides
/// functionality for playing, pausing, and controlling audio playback.
class AudioPlaybackController implements AudioPlayback {
  /// The audio player instance used for playback.
  final AudioPlayer _audioPlayer;

  /// The currently loaded audio file.
  AudioFile? _currentFile;

  /// The current playback state.
  PlaybackState _state = PlaybackState.initial;

  /// The current duration of the loaded audio in milliseconds.
  int _duration = 0;

  /// Stream controller for playback state changes.
  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();

  /// Stream controller for playback position changes.
  final StreamController<int> _positionController =
      StreamController<int>.broadcast();

  /// Timer for position updates when not provided by the player.
  Timer? _positionTimer;

  /// Flag indicating whether the controller has been initialized.
  bool _initialized = false;

  /// Creates a new [AudioPlaybackController] instance.
  ///
  /// Optionally, a custom [AudioPlayer] instance can be provided for testing.
  AudioPlaybackController([AudioPlayer? audioPlayer])
      : _audioPlayer = audioPlayer ?? AudioPlayer();

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      debugPrint('Initializing AudioPlaybackController');
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      // Set up listeners
      _audioPlayer.onPlayerStateChanged.listen((state) {
        debugPrint('Player state changed: $state');
        switch (state) {
          case PlayerState.playing:
            _stateController.add(PlaybackState.playing);
            break;
          case PlayerState.paused:
            _stateController.add(PlaybackState.paused);
            break;
          case PlayerState.stopped:
            _stateController.add(PlaybackState.stopped);
            break;
          case PlayerState.completed:
            _stateController.add(PlaybackState.stopped);
            break;
          default:
            break;
        }
      });

      _audioPlayer.onPositionChanged.listen((position) {
        _positionController.add(position.inMilliseconds);
      });

      _audioPlayer.onDurationChanged.listen((duration) {
        _duration = duration.inMilliseconds;
      });

      _initialized = true;
      debugPrint('AudioPlaybackController initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize AudioPlaybackController: $e');
      return false;
    }
  }

  @override
  Future<bool> load(AudioFile file) async {
    if (!_initialized) {
      debugPrint('AudioPlaybackController not initialized');
      return false;
    }

    try {
      debugPrint('Loading audio file: ${file.path}');
      // Stop any current playback
      await stop();

      // Check if the file exists
      final audioFile = File(file.path);
      final exists = await audioFile.exists();
      debugPrint('File exists check: $exists for path: ${file.path}');

      if (!exists) {
        debugPrint('Audio file does not exist: ${file.path}');
        throw Exception('Audio file not found at ${file.path}');
      }

      // Get file size to verify it's a valid file
      final fileSize = await audioFile.length();
      debugPrint('Audio file size: $fileSize bytes');

      if (fileSize <= 0) {
        debugPrint('Audio file is empty: ${file.path}');
        throw Exception('Audio file is empty: ${file.path}');
      }

      // Determine the file extension to use the correct source method
      final fileExtension = file.path.split('.').last.toLowerCase();
      debugPrint('Audio file extension: $fileExtension');

      // Set the source based on file type
      try {
        if (fileExtension == 'aiff') {
          // For AIFF files, we need to use a different source method
          debugPrint('Using device file source for AIFF file');
          await _audioPlayer.setSourceDeviceFile(file.path);
        } else {
          // For other file types, use the standard method
          debugPrint(
              'Using device file source for ${fileExtension.toUpperCase()} file');
          await _audioPlayer.setSourceDeviceFile(file.path);
        }
        debugPrint('Audio source set successfully');
      } catch (e) {
        debugPrint('Error setting audio source: $e');
        throw Exception('Error setting audio source: $e');
      }

      _currentFile = file;
      _stateController.add(PlaybackState.paused);
      debugPrint('Audio file loaded successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to load audio file: $e');
      // Rethrow to allow proper error handling upstream
      rethrow;
    }
  }

  @override
  Future<bool> play() async {
    if (!_initialized || _currentFile == null) {
      debugPrint('Cannot play: not initialized or no file loaded');
      return false;
    }

    try {
      debugPrint('Playing audio');
      await _audioPlayer.resume();
      _updateState(PlaybackState.playing);
      debugPrint('Audio playback started');
      return true;
    } catch (e) {
      debugPrint('Failed to play audio: $e');
      return false;
    }
  }

  @override
  Future<bool> pause() async {
    if (!_initialized || _currentFile == null) {
      debugPrint('Cannot pause: not initialized or no file loaded');
      return false;
    }

    try {
      debugPrint('Pausing audio playback');
      await _audioPlayer.pause();
      _updateState(PlaybackState.paused);
      debugPrint('Audio playback paused');
      return true;
    } catch (e) {
      debugPrint('Failed to pause audio: $e');
      return false;
    }
  }

  @override
  Future<bool> stop() async {
    if (!_initialized || _currentFile == null) {
      return false;
    }

    try {
      await _audioPlayer.stop();
      return true;
    } catch (e) {
      print('Failed to stop audio: $e');
      return false;
    }
  }

  @override
  Future<bool> seekTo(int position) async {
    if (!_initialized || _currentFile == null) {
      return false;
    }

    try {
      await _audioPlayer.seek(Duration(milliseconds: position));
      _positionController.add(position);
      return true;
    } catch (e) {
      print('Failed to seek: $e');
      return false;
    }
  }

  @override
  Future<int> get position async {
    if (!_initialized || _currentFile == null) {
      return 0;
    }

    try {
      final position = await _audioPlayer.getCurrentPosition();
      return position?.inMilliseconds ?? 0;
    } catch (e) {
      print('Failed to get position: $e');
      return 0;
    }
  }

  @override
  Future<int> get duration async {
    if (!_initialized || _currentFile == null) {
      return 0;
    }

    try {
      final duration = await _audioPlayer.getDuration();
      return duration?.inMilliseconds ?? _currentFile!.duration.inMilliseconds;
    } catch (e) {
      print('Failed to get duration: $e');
      return _currentFile!.duration.inMilliseconds;
    }
  }

  @override
  PlaybackState get state => _state;

  @override
  Stream<PlaybackState> get onStateChanged => _stateController.stream;

  @override
  Stream<int> get onPositionChanged => _positionController.stream;

  @override
  Future<void> dispose() async {
    _stopPositionTimer();
    await _audioPlayer.dispose();
    await _stateController.close();
    await _positionController.close();
  }

  /// Updates the current playback state and notifies listeners.
  void _updateState(PlaybackState newState) {
    if (_state == newState) return;

    _state = newState;

    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }

    // Start or stop position timer based on state
    if (newState == PlaybackState.playing) {
      _startPositionTimer();
    } else {
      _stopPositionTimer();
    }
  }

  /// Handles player state changes from the audio player.
  void _handlePlayerStateChange(PlayerState playerState) {
    switch (playerState) {
      case PlayerState.playing:
        _updateState(PlaybackState.playing);
        break;
      case PlayerState.paused:
        _updateState(PlaybackState.paused);
        break;
      case PlayerState.stopped:
        _updateState(PlaybackState.stopped);
        break;
      case PlayerState.completed:
        _updateState(PlaybackState.stopped);
        break;
      case PlayerState.disposed:
        // Do nothing
        break;
    }
  }

  /// Handles position changes from the audio player.
  void _handlePositionChange(Duration position) {
    if (!_positionController.isClosed) {
      _positionController.add(position.inMilliseconds);
    }
  }

  /// Starts a timer to emit position updates if the player doesn't provide them.
  void _startPositionTimer() {
    _stopPositionTimer();

    // Update position every 200ms
    _positionTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_state != PlaybackState.playing ||
          _stateController.isClosed ||
          _positionController.isClosed) {
        timer.cancel();
        return;
      }

      final currentPosition = await position;
      if (!_positionController.isClosed) {
        _positionController.add(currentPosition);
      }
    });
  }

  /// Stops the position update timer.
  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }
}
