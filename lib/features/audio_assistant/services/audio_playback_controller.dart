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
        Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (_state == PlaybackState.playing && !_positionController.isClosed) {
        final position = await this.position;
        _positionController.add(position);
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
      await _audioPlayer.resume();
      return true;
    } catch (e) {
      _logger.error('AudioPlaybackController: Error playing audio: $e');
      return false;
    }
  }

  @override
  Future<bool> pause() async {
    if (!_isInitialized || _state != PlaybackState.playing) return false;

    try {
      await _audioPlayer.pause();
      return true;
    } catch (e) {
      _logger.error('AudioPlaybackController: Error pausing audio: $e');
      return false;
    }
  }

  @override
  Future<bool> stop() async {
    if (!_isInitialized ||
        (_state != PlaybackState.playing && _state != PlaybackState.paused)) {
      return false;
    }

    try {
      await _audioPlayer.stop();
      return true;
    } catch (e) {
      _logger.error('AudioPlaybackController: Error stopping audio: $e');
      return false;
    }
  }

  @override
  Future<bool> seekTo(int position) async {
    if (!_isInitialized || _currentFile == null) return false;

    try {
      await _audioPlayer.seek(Duration(milliseconds: position));
      return true;
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
}
