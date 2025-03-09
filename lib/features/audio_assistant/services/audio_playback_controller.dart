import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../models/audio_file.dart';
import '../models/playback_state.dart';
import 'audio_playback.dart';

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
    try {
      // Set up listeners for player events
      _audioPlayer.onPlayerStateChanged.listen(_handlePlayerStateChange);
      _audioPlayer.onPositionChanged.listen(_handlePositionChange);
      _audioPlayer.onPlayerComplete
          .listen((_) => _updateState(PlaybackState.stopped));

      _initialized = true;
      return true;
    } catch (e) {
      print('Failed to initialize AudioPlaybackController: $e');
      return false;
    }
  }

  @override
  Future<bool> load(AudioFile file) async {
    if (!_initialized) {
      return false;
    }

    try {
      _updateState(PlaybackState.loading);

      // Stop any current playback
      await _audioPlayer.stop();

      // Load the new audio file
      await _audioPlayer.setSourceDeviceFile(file.path);

      _currentFile = file;
      _updateState(PlaybackState.stopped);
      return true;
    } catch (e) {
      print('Failed to load audio file: $e');
      _updateState(PlaybackState.initial);
      return false;
    }
  }

  @override
  Future<bool> play() async {
    if (!_initialized || _currentFile == null) {
      return false;
    }

    try {
      await _audioPlayer.resume();
      return true;
    } catch (e) {
      print('Failed to play audio: $e');
      return false;
    }
  }

  @override
  Future<bool> pause() async {
    if (!_initialized ||
        _currentFile == null ||
        _state != PlaybackState.playing) {
      return false;
    }

    try {
      await _audioPlayer.pause();
      return true;
    } catch (e) {
      print('Failed to pause audio: $e');
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
