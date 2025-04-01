import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/models/playback_state.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback_manager.dart';

class AssistantAudioMessage extends StatefulWidget {
  final AudioFile audioFile;
  final String transcription;
  final AudioPlayback audioPlayback; // Kept for backward compatibility

  const AssistantAudioMessage({
    Key? key,
    required this.audioFile,
    required this.transcription,
    required this.audioPlayback,
  }) : super(key: key);

  @override
  State<AssistantAudioMessage> createState() => _AssistantAudioMessageState();
}

class _AssistantAudioMessageState extends State<AssistantAudioMessage> {
  bool _isLoading = false;
  bool _isPlaying = false;
  late final String _widgetId;
  late final AudioPlaybackManager _playbackManager;
  StreamSubscription<PlaybackStateUpdate>? _playbackSubscription;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // Generate a unique ID for this widget instance
    _widgetId = 'assistant_audio_${identityHashCode(this)}';
    _playbackManager = AudioPlaybackManager();

    // Delay setup to avoid potential issues during widget initialization
    Future.microtask(() {
      if (!_disposed) {
        _setupPlaybackListener();
      }
    });
  }

  void _setupPlaybackListener() {
    // Cancel any existing subscription first
    _playbackSubscription?.cancel();

    // Listen for playback state updates
    _playbackSubscription = _playbackManager.playbackStateStream.listen(
      (update) {
        // Only process updates if the widget is still mounted and not disposed
        if (_disposed) return;

        if (!mounted) {
          // If not mounted anymore, just cancel the subscription
          _playbackSubscription?.cancel();
          _playbackSubscription = null;
          return;
        }

        // Now it's safe to call setState
        if (update.widgetId == _widgetId) {
          debugPrint(
              'AssistantAudioMessage: Received state update for $_widgetId: ${update.state}');
          setState(() {
            _isPlaying = update.state == PlaybackState.playing;
          });
        } else if (_isPlaying) {
          // If another widget is playing and this one was playing, update our state
          setState(() {
            _isPlaying = false;
          });
        }
      },
      onError: (error) {
        debugPrint('AssistantAudioMessage: Error in playback stream: $error');
      },
      onDone: () {
        debugPrint('AssistantAudioMessage: Playback stream closed');
      },
    );
  }

  void _toggleAudio() async {
    if (_isLoading || _disposed) return;

    if (!mounted) {
      debugPrint(
          'AssistantAudioMessage: Widget not mounted, cannot toggle audio');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final audioPath = widget.audioFile.path;
      final shortTranscription = widget.transcription.length > 30
          ? '${widget.transcription.substring(0, 30)}...'
          : widget.transcription;

      debugPrint('=== ASSISTANT AUDIO PLAYBACK DEBUG ===');
      debugPrint('Widget ID: $_widgetId');
      debugPrint('Transcription: $shortTranscription');
      debugPrint('Audio Path: $audioPath');
      debugPrint('Audio Duration: ${widget.audioFile.duration}');

      // Verify file exists before attempting to play
      final file = File(audioPath);
      final exists = await file.exists();
      if (!exists) {
        debugPrint('Audio file does not exist: $audioPath');
        if (mounted && !_disposed) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      if (_isPlaying) {
        debugPrint('Action: Pausing assistant audio');
        await _playbackManager.pauseAudio(_widgetId);
        if (mounted && !_disposed) {
          setState(() {
            _isPlaying = false;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('Action: Playing assistant audio');

        // Play the audio file using the manager
        final playResult =
            await _playbackManager.playAudio(_widgetId, widget.audioFile);
        debugPrint('Assistant play result: $playResult');

        if (mounted && !_disposed) {
          setState(() {
            _isPlaying = playResult;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling assistant audio: $e');
      if (mounted && !_disposed) {
        setState(() {
          _isPlaying = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    debugPrint('AssistantAudioMessage: Disposing widget $_widgetId');
    _disposed = true;

    // Cancel subscription first
    if (_playbackSubscription != null) {
      _playbackSubscription!.cancel();
      _playbackSubscription = null;
    }

    // If this widget is playing audio when disposed, stop it
    if (_isPlaying) {
      _playbackManager.stopAudio();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.transcription,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.blue,
                      ),
                onPressed: _toggleAudio,
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.0, // TODO: Implement progress tracking
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[300]!),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(widget.audioFile.duration),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
