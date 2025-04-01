import 'dart:math';
import 'package:flutter/material.dart';

class AudioWaveform extends StatelessWidget {
  final String audioPath;
  final Duration audioDuration;
  final bool isPlaying;
  final Duration currentPosition;

  const AudioWaveform({
    Key? key,
    required this.audioPath,
    required this.audioDuration,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate waveform width based on duration
    final double waveformWidth = _calculateWaveformWidth();

    // Calculate progress indicator position
    final double progressPosition = _calculateProgressPosition(waveformWidth);

    return Container(
      height: 40.0,
      width: waveformWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: theme.colorScheme.surfaceVariant,
      ),
      child: Stack(
        children: [
          // Waveform visualization
          CustomPaint(
            size: Size(waveformWidth, 40.0),
            painter: WaveformPainter(),
          ),

          // Progress indicator
          if (isPlaying || currentPosition > Duration.zero)
            Positioned(
              left: progressPosition,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2.0,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  double _calculateWaveformWidth() {
    // Use a fixed width per second, with min/max constraints
    const double widthPerSecond = 20.0;
    const double minWidth = 150.0;
    const double maxWidth = 300.0;

    final double calculatedWidth =
        audioDuration.inMilliseconds / 1000 * widthPerSecond;
    return calculatedWidth.clamp(minWidth, maxWidth);
  }

  double _calculateProgressPosition(double totalWidth) {
    if (audioDuration.inMilliseconds == 0) return 0;

    return (totalWidth *
            currentPosition.inMilliseconds /
            audioDuration.inMilliseconds)
        .clamp(0.0, totalWidth);
  }
}

class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Create a simple waveform pattern
    const double barWidth = 3.0;
    const double gap = 2.0;
    final int barCount = (size.width / (barWidth + gap)).floor();

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap) + barWidth / 2;
      final height = (10 + (i % 3) * 10).toDouble(); // Simple pattern
      final startY = (size.height - height) / 2;

      canvas.drawLine(
        Offset(x, startY),
        Offset(x, startY + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
