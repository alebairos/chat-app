import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/audio_file.dart';
import '../models/playback_state.dart';
import '../services/audio_playback.dart';

/// A widget that displays an audio message from the assistant.
///
/// This widget includes a play/pause button, a waveform visualization,
/// and displays the duration and current position of the audio.
class AssistantAudioMessage extends StatefulWidget {
  /// The audio file to play.
  final AudioFile audioFile;

  /// The text transcription of the audio.
  final String transcription;

  /// The audio playback service.
  final AudioPlayback audioPlayback;

  /// Creates a new [AssistantAudioMessage] widget.
  const AssistantAudioMessage({
    required this.audioFile,
    required this.transcription,
    required this.audioPlayback,
    Key? key,
  }) : super(key: key);

  @override
  State<AssistantAudioMessage> createState() => _AssistantAudioMessageState();
}

class _AssistantAudioMessageState extends State<AssistantAudioMessage> {
  PlaybackState _playbackState = PlaybackState.stopped;
  Duration _position = Duration.zero;
  late StreamSubscription<PlaybackState> _stateSubscription;
  late StreamSubscription<int> _positionSubscription;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      // Initialize audio playback if needed
      if (!await widget.audioPlayback.initialize()) {
        debugPrint('Failed to initialize audio playback');
        return;
      }

      // Load the audio file
      await widget.audioPlayback.load(widget.audioFile);

      // Listen for playback state changes
      _stateSubscription = widget.audioPlayback.onStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _playbackState = state;
          });
        }
      });

      // Listen for position changes
      _positionSubscription =
          widget.audioPlayback.onPositionChanged.listen((positionMs) {
        if (mounted) {
          setState(() {
            _position = Duration(milliseconds: positionMs);
          });
        }
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_playbackState == PlaybackState.playing) {
        await widget.audioPlayback.pause();
      } else {
        await widget.audioPlayback.play();
      }
    } catch (e) {
      debugPrint('Error toggling playback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Audio player controls
          Row(
            children: [
              // Play/pause button
              IconButton(
                onPressed: _isInitialized ? _togglePlayback : null,
                icon: Icon(
                  _playbackState == PlaybackState.playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.blue,
                  size: 36,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),

              // Waveform visualization and progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Waveform with progress indicator
                    SizedBox(
                      height: 32,
                      child: _WaveformProgressBar(
                        duration: widget.audioFile.duration,
                        position: _position,
                        isPlaying: _playbackState == PlaybackState.playing,
                        waveformData: widget.audioFile.waveformData,
                      ),
                    ),

                    // Duration text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(widget.audioFile.duration),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Transcription text
          Text(
            widget.transcription,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    _positionSubscription.cancel();
    super.dispose();
  }
}

/// A custom widget that displays a waveform visualization with a progress indicator.
class _WaveformProgressBar extends StatelessWidget {
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final List<double>? waveformData;

  const _WaveformProgressBar({
    required this.duration,
    required this.position,
    required this.isPlaying,
    this.waveformData,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return CustomPaint(
      painter: _WaveformPainter(
        waveformData: waveformData,
        progress: progress,
        playedColor: Colors.blue,
        unplayedColor: Colors.grey[400]!,
        isPlaying: isPlaying,
      ),
      size: const Size(double.infinity, 32),
    );
  }
}

/// A custom painter that draws a waveform visualization.
class _WaveformPainter extends CustomPainter {
  final List<double>? waveformData;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;
  final bool isPlaying;

  _WaveformPainter({
    this.waveformData,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final progressX = size.width * progress;

    // If we don't have waveform data, generate a random one for visualization
    final data = waveformData ?? _generateRandomWaveform(60);

    final barWidth = size.width / data.length;
    final centerY = size.height / 2;

    // Draw each bar in the waveform
    for (int i = 0; i < data.length; i++) {
      final x = i * barWidth;
      final amplitude = data[i] * size.height * 0.4;

      // Determine if this bar is before or after the progress point
      paint.color = x < progressX ? playedColor : unplayedColor;

      // Draw the bar
      canvas.drawLine(
        Offset(x + barWidth / 2, centerY - amplitude),
        Offset(x + barWidth / 2, centerY + amplitude),
        paint,
      );
    }

    // Draw progress indicator
    if (isPlaying) {
      final progressPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(progressX, 0),
        Offset(progressX, size.height),
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }

  // Generate random waveform data for visualization
  List<double> _generateRandomWaveform(int count) {
    final random = Random();
    return List.generate(count, (index) {
      // Create a smoother waveform by using a sine wave with some randomness
      final baseAmplitude = 0.3 + 0.2 * sin(index * 0.5);
      return baseAmplitude + random.nextDouble() * 0.2;
    });
  }
}
