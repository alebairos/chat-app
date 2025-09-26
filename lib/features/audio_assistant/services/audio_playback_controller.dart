import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../models/audio_file.dart';
import '../models/playback_state.dart';
import 'audio_playback.dart';
import '../../../utils/logger.dart';

/// Implementation of [AudioPlayback] using the audioplayers package.
///
/// This class provides all the functionality needed to play audio files
/// and track the playback state and position.
class AudioPlaybackController implements AudioPlayback {
  // Core audio player
  late AudioPlayer _audioPlayer;

  // Current state of audio playback
  PlaybackState _state = PlaybackState.initial;

  // Streams for notifying UI components about state and position changes
  final _stateController = StreamController<PlaybackState>.broadcast();
  final _positionController = StreamController<int>.broadcast();

  // Currently loaded audio file
  AudioFile? _currentFile;

  // Timer for position updates
  Timer? _positionUpdateTimer;

  // Flag for initialization state
  bool _isInitialized = false;

  // Logger for debugging
  final _logger = Logger();

  /// Creates a new instance of [AudioPlaybackController].
  AudioPlaybackController() {
    _audioPlayer = AudioPlayer();
    _setupEventListeners();
  }

  void _setupEventListeners() {
    // Listen to state changes from the audio player
    _audioPlayer.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          _updateState(PlaybackState.playing);
          _startPositionUpdates();
          break;
        case PlayerState.paused:
          _updateState(PlaybackState.paused);
          _stopPositionUpdates();
          break;
        case PlayerState.stopped:
          _updateState(PlaybackState.stopped);
          _stopPositionUpdates();
          break;
        case PlayerState.completed:
          _updateState(PlaybackState.stopped);
          _stopPositionUpdates();
          break;
        default:
          // Handle any other states if needed
          break;
      }
    }, onError: (error) {
      _logger.error('AudioPlaybackController: Player state error: $error');
      _updateState(PlaybackState.stopped);
    });

    // Listen to completion event
    _audioPlayer.onPlayerComplete.listen((_) {
      _updateState(PlaybackState.stopped);
      _stopPositionUpdates();
    });
  }

  void _updateState(PlaybackState newState) {
    if (_state != newState) {
      _state = newState;
      if (!_stateController.isClosed) {
        _stateController.add(_state);
      }
    }
  }

  void _startPositionUpdates() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (_state == PlaybackState.playing && !_positionController.isClosed) {
        try {
          final position = await this.position;
          _positionController.add(position);
          _logger.debug('Position update: $position ms');
        } catch (e) {
          _logger.error('Error getting position: $e');
        }
      }
    });
  }

  void _stopPositionUpdates() {
    _positionUpdateTimer?.cancel();
    _positionUpdateTimer = null;
  }

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      _isInitialized = true;
      return true;
    } catch (e) {
      _logger.error('AudioPlaybackController: Initialization error: $e');
      return false;
    }
  }

  @override
  Future<bool> load(AudioFile file) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _updateState(PlaybackState.loading);

      // Verify file exists
      final fileExists = await File(file.path).exists();
      if (!fileExists) {
        _logger.error('AudioPlaybackController: File not found: ${file.path}');
        _updateState(PlaybackState.initial);
        return false;
      }

      // Load the audio file
      await _audioPlayer.stop();
      final source = DeviceFileSource(file.path);
      await _audioPlayer.setSourceDeviceFile(file.path);

      _currentFile = file;
      _updateState(PlaybackState.paused);
      return true;
    } catch (e) {
      _logger.error('AudioPlaybackController: Error loading file: $e');
      _updateState(PlaybackState.initial);
      return false;
    }
  }

  @override
  Future<bool> play() async {
    if (!_isInitialized || _currentFile == null) return false;

    try {
      _logger.debug('AudioPlaybackController: Attempting to play/resume audio');
      _logger.debug('AudioPlaybackController: Current state: $_state');

      // If we're in stopped state, we need to reload
      if (_state == PlaybackState.stopped && _currentFile != null) {
        _logger
            .debug('AudioPlaybackController: In stopped state, reloading file');
        await load(_currentFile!);
      }

      // Then play/resume
      await _audioPlayer.resume();

      // Give the player a moment to update its state
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify play was successful
      final playerState = _audioPlayer.state;
      _logger.debug(
          'AudioPlaybackController: Player state after play: $playerState');

      if (playerState == PlayerState.playing) {
        _updateState(PlaybackState.playing);
        _startPositionUpdates();
        _logger.debug('AudioPlaybackController: Successfully playing audio');
        return true;
      } else {
        _logger.error(
            'AudioPlaybackController: Failed to play audio, player in state: $playerState');
        // If resume didn't work, try a full reload and play
        _logger.debug('AudioPlaybackController: Trying full reload and play');
        await load(_currentFile!);
        await _audioPlayer.resume();

        final retryState = _audioPlayer.state;
        if (retryState == PlayerState.playing) {
          _updateState(PlaybackState.playing);
          _startPositionUpdates();
          _logger.debug(
              'AudioPlaybackController: Successfully playing audio after retry');
          return true;
        } else {
          _logger.error(
              'AudioPlaybackController: Failed to play audio even after retry');
          return false;
        }
      }
    } catch (e) {
      _logger.error('AudioPlaybackController: Error playing audio: $e');
      return false;
    }
  }

  @override
  Future<bool> pause() async {
    if (!_isInitialized) return false;

    try {
      _logger.debug('AudioPlaybackController: Attempting to pause audio');
      await _audioPlayer.pause();

      // Give the player a moment to update its state
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify the pause was successful by checking player state
      final playerState = _audioPlayer.state;
      _logger.debug(
          'AudioPlaybackController: Player state after pause: $playerState');

      if (playerState == PlayerState.paused) {
        _updateState(PlaybackState.paused);
        _stopPositionUpdates();
        _logger.debug('AudioPlaybackController: Successfully paused audio');
        return true;
      } else if (playerState == PlayerState.stopped) {
        // If the player stopped instead of paused, that's still acceptable
        _updateState(PlaybackState.paused);
        _stopPositionUpdates();
        _logger.debug(
            'AudioPlaybackController: Audio stopped, treating as paused');
        return true;
      } else {
        _logger.debug(
            'AudioPlaybackController: Pause may not have worked as expected, player state: $playerState');
        // Don't force stop here - just update state and let the UI handle it
        _updateState(PlaybackState.paused);
        _stopPositionUpdates();
        return true;
      }
    } catch (e) {
      _logger.error('AudioPlaybackController: Error pausing audio: $e');
      // Even if there's an error, treat it as paused
      _updateState(PlaybackState.paused);
      _stopPositionUpdates();
      return true;
    }
  }

  @override
  Future<bool> stop() async {
    if (!_isInitialized) return false;

    try {
      _logger.debug('AudioPlaybackController: Attempting to stop audio');

      // First check current state
      final currentPlayerState = _audioPlayer.state;
      _logger.debug(
          'AudioPlaybackController: Current player state before stop: $currentPlayerState');

      // Stop the audio
      await _audioPlayer.stop();

      // Verify stop was successful
      final newPlayerState = _audioPlayer.state;
      _logger.debug(
          'AudioPlaybackController: Player state after stop: $newPlayerState');

      // Force release resources
      await _audioPlayer.release();

      // Update state regardless of player response
      _updateState(PlaybackState.stopped);
      _stopPositionUpdates();
      _logger.debug('AudioPlaybackController: Successfully stopped audio');

      return true;
    } catch (e) {
      _logger.error('AudioPlaybackController: Error stopping audio: $e');
      // Try to update state anyway
      _updateState(PlaybackState.stopped);
      _stopPositionUpdates();
      return false;
    }
  }

  @override
  Future<bool> seekTo(int position) async {
    if (!_isInitialized || _currentFile == null) {
      _logger.error(
          'AudioPlaybackController: Cannot seek, not initialized or no file loaded');
      return false;
    }

    try {
      _logger
          .debug('AudioPlaybackController: Seeking to position $position ms');

      // First check if we have valid duration to prevent seeking beyond the end
      final audioDuration = await duration;
      if (position > audioDuration) {
        _logger.debug(
            'AudioPlaybackController: Position $position exceeds duration $audioDuration, clamping');
        position = audioDuration;
      }

      // Seek to position
      await _audioPlayer.seek(Duration(milliseconds: position));

      // Verify seek was successful
      final newPosition = await this.position;
      _logger.debug(
          'AudioPlaybackController: Position after seek: $newPosition ms');

      // Position updates aren't immediate, but we should be within a reasonable range
      final bool seekSuccessful =
          (newPosition - position).abs() < 500; // Within 500ms

      return seekSuccessful;
    } catch (e) {
      _logger.error('AudioPlaybackController: Error seeking: $e');
      return false;
    }
  }

  @override
  Future<int> get position async {
    if (!_isInitialized || _currentFile == null) return 0;

    try {
      final position = await _audioPlayer.getCurrentPosition();
      return position?.inMilliseconds ?? 0;
    } catch (e) {
      _logger.error('AudioPlaybackController: Error getting position: $e');
      return 0;
    }
  }

  @override
  Future<int> get duration async {
    if (!_isInitialized || _currentFile == null) return 0;

    try {
      final duration = await _audioPlayer.getDuration();
      return duration?.inMilliseconds ?? _currentFile!.duration.inMilliseconds;
    } catch (e) {
      _logger.error('AudioPlaybackController: Error getting duration: $e');
      return _currentFile?.duration.inMilliseconds ?? 0;
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
    _stopPositionUpdates();

    try {
      await _audioPlayer.stop();
      await _audioPlayer.dispose();

      await _stateController.close();
      await _positionController.close();

      _isInitialized = false;
    } catch (e) {
      _logger.error('AudioPlaybackController: Error disposing: $e');
    }
  }

  /// Force stop the audio playback completely, recreating the player if needed
  @override
  Future<bool> forceStop() async {
    _logger.debug('AudioPlaybackController: Force stopping audio');

    try {
      // Try normal stop first
      await _audioPlayer.stop();

      // Release resources
      await _audioPlayer.release();

      // Recreate player to ensure clean state
      _audioPlayer = AudioPlayer();
      _setupEventListeners();

      // Update state
      _updateState(PlaybackState.stopped);
      _stopPositionUpdates();

      _logger
          .debug('AudioPlaybackController: Successfully force stopped audio');
      return true;
    } catch (e) {
      _logger.error('AudioPlaybackController: Error force stopping audio: $e');

      // Try to recreate player anyway to recover
      try {
        _audioPlayer = AudioPlayer();
        _setupEventListeners();
        _updateState(PlaybackState.stopped);
        _stopPositionUpdates();
      } catch (innerE) {
        _logger.error(
            'AudioPlaybackController: Failed to recreate player: $innerE');
      }

      return false;
    }
  }
}
