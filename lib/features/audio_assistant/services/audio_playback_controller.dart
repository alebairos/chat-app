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
  File? _currentFile;

  /// The duration of the currently loaded audio file.
  Duration _currentDuration = Duration.zero;

  /// The current playback state.
  PlaybackState _state = PlaybackState.stopped;

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
        _currentDuration = Duration(milliseconds: duration.inMilliseconds);
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
  Future<bool> load(AudioFile audioFile) async {
    debugPrint('Loading audio file: ${audioFile.path}');
    debugPrint('Audio file duration: ${audioFile.duration}');

    // Generate a unique ID for this load operation for tracking
    final loadId = DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('LOAD_ID: $loadId - Starting load operation');

    try {
      // Stop any currently playing audio and release resources
      if (_currentFile != null) {
        debugPrint(
            'LOAD_ID: $loadId - Stopping and releasing previous audio file: ${_currentFile?.path}');
        await _audioPlayer.stop();
        await _audioPlayer.release();
      }

      // Store the duration from the AudioFile
      _currentDuration = audioFile.duration;
      debugPrint(
          'LOAD_ID: $loadId - Set current duration to: $_currentDuration');

      // Check if the file exists and is not empty
      final path = audioFile.path;

      // Add a unique cache-busting parameter to prevent caching issues
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint(
          'LOAD_ID: $loadId - Using unique ID for audio load: $uniqueId');

      // Check if this is an asset path
      if (path.startsWith('assets/')) {
        debugPrint('LOAD_ID: $loadId - Loading from asset: $path');
        try {
          // For asset files, use setSourceAsset
          await _audioPlayer.setSourceAsset(path);
          debugPrint('LOAD_ID: $loadId - Asset audio source set successfully');

          _currentFile = File(path); // Create a placeholder File object
          _stateController.add(PlaybackState.paused);
          debugPrint('LOAD_ID: $loadId - Asset audio file loaded successfully');
          return true;
        } catch (e) {
          debugPrint('LOAD_ID: $loadId - Error setting asset audio source: $e');
          throw Exception('Error setting asset audio source: $e');
        }
      }

      // For device files, continue with the existing logic
      final file = File(path);
      final exists = await file.exists();

      if (!exists) {
        debugPrint('LOAD_ID: $loadId - Audio file does not exist: $path');

        // Check if this might be an asset path without the 'assets/' prefix
        if (path.contains('.aiff') || path.contains('.mp3')) {
          final assetPath = path.split('/').last;
          final fullAssetPath = 'assets/audio/$assetPath';
          debugPrint(
              'LOAD_ID: $loadId - Attempting to load as asset: $fullAssetPath');

          try {
            await _audioPlayer.setSourceAsset(fullAssetPath);
            debugPrint(
                'LOAD_ID: $loadId - Fallback asset audio source set successfully');

            _currentFile = File(path); // Create a placeholder File object
            _stateController.add(PlaybackState.paused);
            debugPrint(
                'LOAD_ID: $loadId - Fallback asset audio file loaded successfully');
            return true;
          } catch (e) {
            debugPrint(
                'LOAD_ID: $loadId - Error setting fallback asset audio source: $e');
            throw Exception('Audio file not found: $path');
          }
        } else {
          throw Exception('Audio file not found: $path');
        }
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('LOAD_ID: $loadId - Audio file is empty: ${file.path}');
        throw Exception('Audio file is empty: ${file.path}');
      }

      // Determine the file extension to use the correct source method
      final fileExtension = file.path.split('.').last.toLowerCase();
      debugPrint('LOAD_ID: $loadId - Audio file extension: $fileExtension');

      // Set the source based on file type
      try {
        if (fileExtension == 'aiff') {
          // For AIFF files, we need to use a different source method
          debugPrint(
              'LOAD_ID: $loadId - Using device file source for AIFF file');
          await _audioPlayer.setSourceDeviceFile(file.path);
        } else {
          // For other file types, use the standard method
          debugPrint(
              'LOAD_ID: $loadId - Using device file source for ${fileExtension.toUpperCase()} file');
          await _audioPlayer.setSourceDeviceFile(file.path);
        }
        debugPrint('LOAD_ID: $loadId - Audio source set successfully');
      } catch (e) {
        debugPrint('LOAD_ID: $loadId - Error setting audio source: $e');
        throw Exception('Error setting audio source: $e');
      }

      _currentFile = file;
      _stateController.add(PlaybackState.paused);
      debugPrint(
          'LOAD_ID: $loadId - Audio file loaded successfully: ${file.path}');
      return true;
    } catch (e) {
      debugPrint('LOAD_ID: $loadId - Failed to load audio file: $e');
      // Rethrow to allow proper error handling upstream
      rethrow;
    }
  }

  @override
  Future<bool> play() async {
    final playId = DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('PLAY_ID: $playId - Starting play operation');

    if (!_initialized || _currentFile == null) {
      debugPrint(
          'PLAY_ID: $playId - Cannot play: not initialized or no file loaded');
      return false;
    }

    try {
      debugPrint(
          'PLAY_ID: $playId - Playing audio file: ${_currentFile?.path}');
      debugPrint('PLAY_ID: $playId - Audio duration: $_currentDuration');
      await _audioPlayer.resume();
      _updateState(PlaybackState.playing);
      debugPrint('PLAY_ID: $playId - Audio playback started successfully');
      return true;
    } catch (e) {
      debugPrint('PLAY_ID: $playId - Failed to play audio: $e');
      return false;
    }
  }

  @override
  Future<bool> pause() async {
    final pauseId = DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('PAUSE_ID: $pauseId - Starting pause operation');

    if (!_initialized || _currentFile == null) {
      debugPrint(
          'PAUSE_ID: $pauseId - Cannot pause: not initialized or no file loaded');
      return false;
    }

    try {
      debugPrint(
          'PAUSE_ID: $pauseId - Pausing audio playback for file: ${_currentFile?.path}');
      await _audioPlayer.pause();
      _updateState(PlaybackState.paused);
      debugPrint('PAUSE_ID: $pauseId - Audio playback paused successfully');
      return true;
    } catch (e) {
      debugPrint('PAUSE_ID: $pauseId - Failed to pause audio: $e');
      return false;
    }
  }

  @override
  Future<bool> stop() async {
    if (!_initialized) return false;

    try {
      debugPrint('Stopping audio playback');
      await _audioPlayer.stop();

      // Reset position to beginning
      await _audioPlayer.seek(Duration.zero);

      _updateState(PlaybackState.stopped);
      return true;
    } catch (e) {
      debugPrint('Error stopping audio playback: $e');
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
    if (!_initialized) {
      throw Exception('AudioPlaybackController not initialized');
    }

    if (_currentFile == null) {
      return 0;
    }

    try {
      final duration = await _audioPlayer.getDuration();
      return duration?.inMilliseconds ?? _currentDuration.inMilliseconds;
    } catch (e) {
      print('Failed to get duration: $e');
      return _currentDuration.inMilliseconds;
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
    debugPrint('Disposing AudioPlaybackController');

    // Stop any ongoing playback
    try {
      await stop();
    } catch (e) {
      debugPrint('Error stopping playback during dispose: $e');
    }

    // Cancel the position timer
    _stopPositionTimer();

    // Release the audio player resources
    try {
      await _audioPlayer.release();
      await _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }

    // Close stream controllers
    try {
      if (!_stateController.isClosed) await _stateController.close();
      if (!_positionController.isClosed) await _positionController.close();
    } catch (e) {
      debugPrint('Error closing stream controllers: $e');
    }

    // Clear references
    _currentFile = null;
    _initialized = false;
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
