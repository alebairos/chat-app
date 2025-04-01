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
  StreamSubscription<PlaybackState>? _stateSubscription;
  StreamSubscription<int>? _positionSubscription;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    if (!mounted) return;

    try {
      // Initialize audio playback if needed
      if (!await widget.audioPlayback.initialize()) {
        debugPrint('Failed to initialize audio playback');
        return;
      }

      // Load the audio file
      await widget.audioPlayback.load(widget.audioFile);

      if (!mounted) return;

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

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
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
                child: _WaveformProgressBar(
                  duration: widget.audioFile.duration,
                  position: _position,
                  isPlaying: _playbackState == PlaybackState.playing,
                  waveformData: widget.audioFile.waveformData,
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
    // Cancel subscriptions safely
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();

    // Release audio resources
    widget.audioPlayback.stop();

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
    // Calculate progress percentage, clamped for display purposes
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    // For time display, use the actual position even if it exceeds duration
    final displayPosition = position;
    final displayDuration = duration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Waveform visualization with LayoutBuilder for responsive sizing
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: _WaveformPainter(
                  waveformData: waveformData,
                  progress: progress,
                  playedColor: Colors.blue,
                  unplayedColor: Colors.grey[400]!,
                  isPlaying: isPlaying,
                  // Reduce the number of bars for shorter audio
                  barCount: (duration.inSeconds <= 5) ? 30 : 60,
                ),
                size: Size(constraints.maxWidth, 28),
              );
            },
          ),
        ),

        const SizedBox(height: 4),

        // Duration text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(displayPosition),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
            Text(
              _formatDuration(displayDuration),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Format duration as MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// A custom painter that draws a waveform visualization.
class _WaveformPainter extends CustomPainter {
  final List<double>? waveformData;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;
  final bool isPlaying;
  final int barCount;

  _WaveformPainter({
    this.waveformData,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
    required this.isPlaying,
    this.barCount = 60,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Ensure progress is clamped between 0.0 and 1.0
    final clampedProgress = progress.clamp(0.0, 1.0);
    final progressX = size.width * clampedProgress;

    // If we don't have waveform data, generate a static one for visualization
    // Use a fixed seed for random to ensure the pattern doesn't change
    final data = waveformData ?? _generateStaticWaveform(barCount);

    // Calculate bar width based on available space
    final barWidth = size.width / (data.length + 4); // Add padding
    final barSpacing = barWidth * 0.3; // Space between bars
    final centerY = size.height / 2;

    // Draw each bar in the waveform
    for (int i = 0; i < data.length; i++) {
      final x = (i * (barWidth + barSpacing)) + barWidth; // Add initial padding
      final amplitude = data[i] * size.height * 0.4;

      // Determine if this bar is before or after the progress point
      paint.color = x < progressX ? playedColor : unplayedColor;

      // Draw the bar
      canvas.drawLine(
        Offset(x, centerY - amplitude),
        Offset(x, centerY + amplitude),
        paint,
      );
    }

    // Draw progress indicator only when playing
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

  // Generate static waveform data for visualization
  List<double> _generateStaticWaveform(int count) {
    // Use a fixed seed for the random generator to ensure consistency
    final random = Random(42);
    return List.generate(count, (index) {
      // Create a smoother waveform by using a sine wave with some randomness
      final baseAmplitude = 0.3 + 0.2 * sin(index * 0.5);
      return baseAmplitude + random.nextDouble() * 0.15;
    });
  }
}
