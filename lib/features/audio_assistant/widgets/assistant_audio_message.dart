import 'package:flutter/material.dart';
import 'dart:async';
import '../models/audio_file.dart';
import '../models/playback_state.dart';
import '../services/audio_playback_manager.dart';

/// A widget that displays an assistant's audio message with playback controls.
class AssistantAudioMessage extends StatefulWidget {
  /// The path to the audio file.
  final String audioPath;

  /// The transcription of the audio content.
  final String transcription;

  /// The duration of the audio file.
  final Duration duration;

  /// Unique identifier for this message.
  final String messageId;

  const AssistantAudioMessage({
    required this.audioPath,
    required this.transcription,
    required this.duration,
    required this.messageId,
    super.key,
  });

  @override
  State<AssistantAudioMessage> createState() => _AssistantAudioMessageState();
}

class _AssistantAudioMessageState extends State<AssistantAudioMessage> {
  final AudioPlaybackManager _playbackManager = AudioPlaybackManager();
  PlaybackState _playbackState = PlaybackState.initial;
  double _progress = 0.0;
  late final StreamSubscription<PlaybackStateUpdate> _playbackSubscription;
  late final StreamSubscription<int> _positionSubscription;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _setupPlaybackListeners();

    // Register with the manager
    _playbackManager.registerAudioPlayer(
      widget.messageId,
      _handleStopFromManager,
    );
  }

  void _handleStopFromManager() {
    if (mounted) {
      setState(() {
        _playbackState = PlaybackState.stopped;
        _progress = 0.0;
      });
    }
  }

  void _setupPlaybackListeners() {
    // Listen for playback state updates from the manager
    _playbackSubscription =
        _playbackManager.playbackStateStream.listen((update) {
      if (update.widgetId == widget.messageId && mounted) {
        setState(() {
          _playbackState = update.state;
          if (update.state == PlaybackState.stopped) {
            _progress = 0.0;
          }
        });
      }
    });

    // Listen for position updates from the controller
    _positionSubscription =
        _playbackManager.audioPlayback.onPositionChanged.listen((position) {
      if (_playbackManager.isPlaying(widget.messageId) && mounted) {
        setState(() {
          _progress = position / widget.duration.inMilliseconds;
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    final audioFile = AudioFile(
      path: widget.audioPath,
      duration: widget.duration,
      transcription: widget.transcription,
    );

    if (_playbackState == PlaybackState.playing) {
      // Pause the audio
      await _playbackManager.pauseAudio(widget.messageId);
    } else {
      // Notify the manager we're starting playback
      _playbackManager.startPlayback(widget.messageId);

      // Play the audio
      await _playbackManager.playAudio(widget.messageId, audioFile);
    }
  }

  void _toggleTranscription() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio player UI
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Play/pause button
                IconButton(
                  icon: Icon(
                    _playbackState == PlaybackState.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 32,
                    color: theme.primaryColor,
                  ),
                  onPressed: _togglePlayPause,
                ),

                // Progress indicator
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress bar
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      ),

                      // Duration text
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _playbackState == PlaybackState.playing
                                  ? _formatDuration(Duration(
                                      milliseconds:
                                          (widget.duration.inMilliseconds *
                                                  _progress)
                                              .round()))
                                  : '00:00',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              _formatDuration(widget.duration),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Transcription toggle button
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.primaryColor,
                  ),
                  onPressed: _toggleTranscription,
                ),
              ],
            ),
          ),

          // Transcription (collapsible)
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.transcription,
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _playbackSubscription.cancel();
    _positionSubscription.cancel();
    _playbackManager.unregisterAudioPlayer(widget.messageId);
    super.dispose();
  }
}
