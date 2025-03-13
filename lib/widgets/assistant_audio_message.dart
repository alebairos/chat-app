import 'dart:async';
import 'package:flutter/material.dart';
import '../features/audio_assistant/models/audio_file.dart';
import '../features/audio_assistant/models/playback_state.dart';
import '../features/audio_assistant/services/audio_playback.dart';

class AssistantAudioMessage extends StatefulWidget {
  final AudioFile audioFile;
  final String transcription;
  final AudioPlayback audioPlayback;

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
  StreamSubscription<PlaybackState>? _playbackSubscription;

  void _toggleAudio() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final audioPath = widget.audioFile.path;
      final shortTranscription = widget.transcription.length > 30
          ? '${widget.transcription.substring(0, 30)}...'
          : widget.transcription;

      debugPrint('=== ASSISTANT AUDIO PLAYBACK DEBUG ===');
      debugPrint('Widget ID: ${identityHashCode(this)}');
      debugPrint('Transcription: $shortTranscription');
      debugPrint('Audio Path: $audioPath');
      debugPrint('Audio Duration: ${widget.audioFile.duration}');

      if (_isPlaying) {
        debugPrint('Action: Pausing assistant audio');
        await widget.audioPlayback.pause();
        setState(() {
          _isPlaying = false;
          _isLoading = false;
        });
      } else {
        debugPrint('Action: Playing assistant audio');

        // Load the audio file
        debugPrint('Loading assistant audio file: ${widget.audioFile.path}');
        await widget.audioPlayback.load(widget.audioFile);

        // Start playback
        final playResult = await widget.audioPlayback.play();
        debugPrint('Assistant play result: $playResult');

        if (playResult) {
          setState(() {
            _isPlaying = true;
          });

          // Listen for playback completion
          _playbackSubscription =
              widget.audioPlayback.onStateChanged.listen((state) {
            debugPrint('Assistant audio state changed: $state');
            if (state == PlaybackState.stopped && _isPlaying) {
              debugPrint(
                  'Assistant audio playback completed for: $shortTranscription');
              if (mounted) {
                setState(() {
                  _isPlaying = false;
                });
              }
            }
          });
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error toggling assistant audio: $e');
      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
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
