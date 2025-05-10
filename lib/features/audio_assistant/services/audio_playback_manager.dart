import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/audio_file.dart';
import '../models/playback_state.dart';
import 'audio_playback.dart';
import 'audio_playback_controller.dart';
import '../../../utils/logger.dart';

/// Manages audio playback to ensure only one audio file plays at a time
class AudioPlaybackManager {
  static final AudioPlaybackManager _instance =
      AudioPlaybackManager._internal();

  factory AudioPlaybackManager() {
    return _instance;
  }

  AudioPlaybackManager._internal() {
    _initialize();
  }

  /// The shared audio playback controller
  late AudioPlayback _audioPlayback;

  /// Getter to access the audio playback controller
  AudioPlayback get audioPlayback => _audioPlayback;

  /// The ID of the currently active audio widget
  String? _activeWidgetId;

  /// Stream controller for notifying widgets about playback state changes
  final _playbackStateController =
      StreamController<PlaybackStateUpdate>.broadcast();

  /// Stream of playback state updates that widgets can listen to
  Stream<PlaybackStateUpdate> get playbackStateStream =>
      _playbackStateController.stream;

  /// Flag to track if initialization is complete
  bool _initialized = false;

  /// Initialize the audio playback controller
  Future<void> _initialize() async {
    if (_initialized) return;

    try {
      _audioPlayback = AudioPlaybackController();
      await _audioPlayback.initialize();

      // Listen to state changes from the audio playback controller
      _audioPlayback.onStateChanged.listen((state) {
        try {
          if (_activeWidgetId != null) {
            if (!_playbackStateController.isClosed) {
              _playbackStateController.add(
                PlaybackStateUpdate(
                  widgetId: _activeWidgetId!,
                  state: state,
                ),
              );
            }

            // Reset active widget when playback stops
            if (state == PlaybackState.stopped) {
              Logger().debug(
                  'AudioPlaybackManager: Playback stopped, resetting active widget');
              _activeWidgetId = null;
            }
          }
        } catch (e) {
          Logger()
              .error('AudioPlaybackManager: Error handling state change: $e');
        }
      }, onError: (error) {
        Logger().error(
            'AudioPlaybackManager: Error in audio playback state stream: $error');
      });

      _initialized = true;
      Logger().debug('AudioPlaybackManager initialized');
    } catch (e) {
      Logger().error('AudioPlaybackManager: Error during initialization: $e');
      // Try to recover by creating a new controller
      try {
        _audioPlayback = AudioPlaybackController();
        await _audioPlayback.initialize();
        _initialized = true;
        Logger()
            .debug('AudioPlaybackManager: Recovered from initialization error');
      } catch (e) {
        Logger().error(
            'AudioPlaybackManager: Failed to recover from initialization error: $e');
      }
    }
  }

  // Currently playing audio ID (message ID or unique identifier)
  String? _currentlyPlayingId;

  // Callbacks registered by audio players
  final Map<String, VoidCallback> _stopCallbacks = {};

  // Register an audio player with its stop callback
  void registerAudioPlayer(String audioId, VoidCallback stopCallback) {
    _stopCallbacks[audioId] = stopCallback;
  }

  // Unregister an audio player when no longer needed
  void unregisterAudioPlayer(String audioId) {
    _stopCallbacks.remove(audioId);
  }

  // Call this when starting playback of an audio
  void startPlayback(String audioId) {
    // If something else is playing, stop it first
    if (_currentlyPlayingId != null && _currentlyPlayingId != audioId) {
      _stopCallbacks[_currentlyPlayingId]?.call();
    }

    _currentlyPlayingId = audioId;
  }

  // Call this when playback completes or stops
  void stopPlayback(String audioId) {
    if (_currentlyPlayingId == audioId) {
      _currentlyPlayingId = null;
    }
  }

  /// Play audio for a specific widget
  Future<bool> playAudio(String widgetId, AudioFile audioFile) async {
    if (!_initialized) {
      Logger().debug('AudioPlaybackManager: Not initialized, initializing now');
      await _initialize();
    }

    Logger().debug(
        'AudioPlaybackManager: Request to play audio for widget $widgetId');
    Logger().debug('AudioPlaybackManager: Audio file path: ${audioFile.path}');

    try {
      // Verify file exists before attempting to play
      final file = File(audioFile.path);
      final exists = await file.exists();
      if (!exists) {
        Logger().error(
            'AudioPlaybackManager: Audio file does not exist: ${audioFile.path}');
        return false;
      }

      // If this widget is already active and playing, pause it
      if (_activeWidgetId == widgetId) {
        final currentState = _audioPlayback.state;
        if (currentState == PlaybackState.playing) {
          Logger().debug(
              'AudioPlaybackManager: Pausing current audio for widget $widgetId');
          await _audioPlayback.pause();

          // Notify all widgets that this widget is no longer playing
          if (!_playbackStateController.isClosed) {
            _playbackStateController.add(
              PlaybackStateUpdate(
                widgetId: widgetId,
                state: PlaybackState.paused,
              ),
            );
          }

          // Reset active widget
          _activeWidgetId = null;
          return false;
        }
      }
      // If another widget is active, stop it first
      else if (_activeWidgetId != null && _activeWidgetId != widgetId) {
        Logger().debug(
            'AudioPlaybackManager: Stopping audio for previous widget $_activeWidgetId');

        // Notify the previous widget that it's no longer playing
        if (!_playbackStateController.isClosed) {
          _playbackStateController.add(
            PlaybackStateUpdate(
              widgetId: _activeWidgetId!,
              state: PlaybackState.stopped,
            ),
          );
        }

        await _audioPlayback.stop();
      }

      // Set this widget as active
      _activeWidgetId = widgetId;

      // Load and play the audio file
      Logger()
          .debug('AudioPlaybackManager: Loading audio for widget $widgetId');
      try {
        await _audioPlayback.load(audioFile);
        final result = await _audioPlayback.play();
        Logger().debug(
            'AudioPlaybackManager: Play result for widget $widgetId: $result');

        // Notify all widgets about the state change
        if (!_playbackStateController.isClosed) {
          _playbackStateController.add(
            PlaybackStateUpdate(
              widgetId: widgetId,
              state: result ? PlaybackState.playing : PlaybackState.stopped,
            ),
          );
        }

        return result;
      } catch (e) {
        Logger().error(
            'AudioPlaybackManager: Error playing audio for widget $widgetId: $e');
        _activeWidgetId = null;

        // Notify all widgets about the error
        if (!_playbackStateController.isClosed) {
          _playbackStateController.add(
            PlaybackStateUpdate(
              widgetId: widgetId,
              state: PlaybackState.stopped,
            ),
          );
        }

        return false;
      }
    } catch (e) {
      Logger().error('AudioPlaybackManager: Error in playAudio: $e');
      return false;
    }
  }

  /// Pause the currently playing audio
  Future<bool> pauseAudio(String widgetId) async {
    if (!_initialized) {
      Logger().error('AudioPlaybackManager: Not initialized, cannot pause');
      return false;
    }

    try {
      if (_activeWidgetId != widgetId) {
        Logger().debug(
            'AudioPlaybackManager: Cannot pause - widget $widgetId is not active');
        return false;
      }

      Logger()
          .debug('AudioPlaybackManager: Pausing audio for widget $widgetId');
      final result = await _audioPlayback.pause();

      // Notify all widgets about the state change
      if (!_playbackStateController.isClosed) {
        _playbackStateController.add(
          PlaybackStateUpdate(
            widgetId: widgetId,
            state: PlaybackState.paused,
          ),
        );
      }

      return result;
    } catch (e) {
      Logger().error('AudioPlaybackManager: Error pausing audio: $e');
      return false;
    }
  }

  /// Stop the currently playing audio
  Future<bool> stopAudio() async {
    if (!_initialized) {
      Logger().error('AudioPlaybackManager: Not initialized, cannot stop');
      return false;
    }

    try {
      if (_activeWidgetId == null) {
        return false;
      }

      final currentWidgetId = _activeWidgetId;
      Logger().debug(
          'AudioPlaybackManager: Stopping audio for widget $_activeWidgetId');

      // Reset active widget before stopping to prevent race conditions
      _activeWidgetId = null;

      final result = await _audioPlayback.stop();

      // Notify all widgets about the state change
      if (!_playbackStateController.isClosed && currentWidgetId != null) {
        _playbackStateController.add(
          PlaybackStateUpdate(
            widgetId: currentWidgetId,
            state: PlaybackState.stopped,
          ),
        );
      }

      return result;
    } catch (e) {
      Logger().error('AudioPlaybackManager: Error stopping audio: $e');
      return false;
    }
  }

  /// Check if a specific widget is currently active and playing
  bool isPlaying(String widgetId) {
    if (!_initialized) return false;

    try {
      return _activeWidgetId == widgetId &&
          _audioPlayback.state == PlaybackState.playing;
    } catch (e) {
      Logger().error('AudioPlaybackManager: Error checking if playing: $e');
      return false;
    }
  }

  /// Dispose the manager and release resources
  Future<void> dispose() async {
    try {
      if (_initialized) {
        await _audioPlayback.dispose();
      }

      if (!_playbackStateController.isClosed) {
        await _playbackStateController.close();
      }

      _initialized = false;
      Logger().debug('AudioPlaybackManager disposed');
    } catch (e) {
      Logger().error('AudioPlaybackManager: Error during dispose: $e');
    }
  }
}

/// Class representing a playback state update
class PlaybackStateUpdate {
  final String widgetId;
  final PlaybackState state;

  PlaybackStateUpdate({
    required this.widgetId,
    required this.state,
  });
}
