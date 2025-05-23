import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/audio_file.dart';
import '../models/playback_state.dart';
import '../services/audio_playback_manager.dart';
import '../../../utils/logger.dart';
import '../../../utils/path_utils.dart';

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

class _AssistantAudioMessageState extends State<AssistantAudioMessage>
    with SingleTickerProviderStateMixin {
  final AudioPlaybackManager _playbackManager = AudioPlaybackManager();
  final Logger _logger = Logger();
  PlaybackState _playbackState = PlaybackState.initial;
  double _progress = 0.0;
  late final StreamSubscription<PlaybackStateUpdate> _playbackSubscription;
  late final StreamSubscription<int> _positionSubscription;
  bool _isExpanded = false;
  String? _errorMessage;
  late AnimationController _animationController;
  int _lastPosition = 0;

  @override
  void initState() {
    super.initState();
    _setupPlaybackListeners();
    _setupAnimationController();

    // Register with the manager
    _playbackManager.registerAudioPlayer(
      widget.messageId,
      _handleStopFromManager,
    );

    // Log audio path for debugging
    _logger.debug(
        'AssistantAudioMessage initialized with path: ${widget.audioPath}');
  }

  void _setupAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Loop animation when playing
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _playbackState == PlaybackState.playing) {
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  void _handleStopFromManager() {
    if (mounted) {
      setState(() {
        _playbackState = PlaybackState.stopped;
        _progress = 0.0;
        _animationController.reset();
      });
    }
  }

  void _setupPlaybackListeners() {
    // Listen for playback state updates from the manager
    _playbackSubscription =
        _playbackManager.playbackStateStream.listen((update) {
      if (update.widgetId == widget.messageId && mounted) {
        _logger.debug('Received playback state update: ${update.state}');

        setState(() {
          _playbackState = update.state;

          // Handle animation based on state
          if (update.state == PlaybackState.playing) {
            if (!_animationController.isAnimating) {
              _animationController.forward();
            }
          } else if (update.state == PlaybackState.paused) {
            _animationController.stop();
          } else if (update.state == PlaybackState.stopped) {
            _progress = 0.0;
            _lastPosition = 0;
            _animationController.reset();
          }
        });
      }
    });

    // Listen for position updates from the controller
    _positionSubscription =
        _playbackManager.audioPlayback.onPositionChanged.listen((position) {
      if (_playbackManager.isPlaying(widget.messageId) && mounted) {
        final duration = widget.duration.inMilliseconds;
        if (duration > 0) {
          // Prevent division by zero
          setState(() {
            _progress = position / duration;
            _lastPosition = position;

            // For debugging position tracking
            if (position % 1000 < 100) {
              // Log roughly every second
              _logger.debug(
                  'Position update: $position ms, Progress: ${(_progress * 100).toStringAsFixed(1)}%');
            }

            // Ensure animation is running if we're receiving position updates
            if (_playbackState == PlaybackState.playing &&
                !_animationController.isAnimating) {
              _animationController.forward();
            }
          });
        }
      }
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      _logger.debug('Toggling play/pause for audio: ${widget.audioPath}');
      _logger.debug('Current playback state: $_playbackState');

      // Check if file exists (only needed for initial play)
      if (_playbackState == PlaybackState.initial ||
          _playbackState == PlaybackState.stopped) {
        final fileExists = await PathUtils.fileExists(widget.audioPath);
        if (!fileExists) {
          _logger.error('Audio file does not exist: ${widget.audioPath}');
          setState(() {
            _errorMessage = 'Audio file not found';
          });
          return;
        }
      }

      // Get absolute path if it's a relative path
      String resolvedPath = widget.audioPath;
      if (!PathUtils.isAbsolutePath(widget.audioPath)) {
        _logger
            .debug('Converting relative path to absolute: ${widget.audioPath}');
        resolvedPath = await PathUtils.relativeToAbsolute(widget.audioPath);
        _logger.debug('Resolved path: $resolvedPath');
      }

      // Create audio file object for playing
      final audioFile = AudioFile(
        path: resolvedPath,
        duration: widget.duration,
        transcription: widget.transcription,
      );

      bool result = false;

      if (_playbackState == PlaybackState.playing) {
        // Currently playing, so pause properly using the manager
        _logger.debug('Currently playing, pausing: $resolvedPath');
        _animationController.stop();

        // Use the manager's pause method instead of forceStop
        result = await _playbackManager.pauseAudio(widget.messageId);
        _logger.debug('Pause result: $result');

        // The state will be updated through the stream listener
        // but we can update the animation immediately
        if (result) {
          setState(() {
            _errorMessage = null;
          });
        }
      } else if (_playbackState == PlaybackState.paused) {
        // We're paused, so resume playback
        _logger.debug('Resuming playback: $resolvedPath');

        // Use the manager's resume method
        result = await _playbackManager.resumeAudio(widget.messageId);
        _logger.debug('Resume result: $result');

        if (result) {
          _animationController.forward();
          // State will be updated through stream listener
        }
      } else {
        // First play or stopped state, start from beginning
        _logger.debug('Starting new playback: $resolvedPath');
        _lastPosition = 0;

        // Notify manager and play
        _playbackManager.startPlayback(widget.messageId);
        result = await _playbackManager.playAudio(widget.messageId, audioFile);
        _logger.debug('Play result: $result');

        if (result) {
          _animationController.forward();
          // State will be updated through stream listener
        } else {
          // Only show error for serious failures
          _logger.error('Failed to play audio: $resolvedPath');
          if (audioFile.path.isEmpty) {
            setState(() {
              _errorMessage = 'Invalid audio file';
            });
          }
        }
      }
    } catch (e) {
      _logger.error('Error in _togglePlayPause: $e');
      // Don't show technical error messages to users
      setState(() {
        _errorMessage = null;
      });
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
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio player UI
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Controls and visualizer row
                Row(
                  children: [
                    // Play/pause button
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: theme.primaryColorLight.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _playbackState == PlaybackState.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 30,
                          color: theme.primaryColor,
                        ),
                        onPressed: _togglePlayPause,
                        padding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Wave animation container
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: WaveformPainter(
                                color: _playbackState == PlaybackState.playing
                                    ? theme.primaryColor
                                    : Colors.grey,
                                animationValue: _animationController.value,
                                isPlaying:
                                    _playbackState == PlaybackState.playing,
                              ),
                              size: Size.infinite,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress row
                Row(
                  children: [
                    // Current time
                    Text(
                      _formatDuration(
                        Duration(
                          milliseconds:
                              (_progress * widget.duration.inMilliseconds)
                                  .round(),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),

                    // Progress bar
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: LinearProgressIndicator(
                          value: _progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(theme.primaryColor),
                          minHeight: 4,
                        ),
                      ),
                    ),

                    // Total duration
                    Text(
                      _formatDuration(widget.duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Expand/collapse button
                    InkWell(
                      onTap: _toggleTranscription,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Error message if any
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          // Transcription (collapsible)
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                widget.transcription,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
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
    _animationController.dispose();
    super.dispose();
  }
}

/// Custom painter that draws a waveform animation
class WaveformPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final bool isPlaying;

  WaveformPainter({
    required this.color,
    required this.animationValue,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const int waveCount = 20; // More waves for smoother appearance
    final double width = size.width;
    final double height = size.height;
    final double centerY = height / 2;

    if (!isPlaying) {
      // Draw static sine wave when paused
      final path = Path();

      for (int i = 0; i < width; i += 3) {
        // Less points for better performance
        final x = i.toDouble();
        // Small gentle wave when paused
        final y = centerY + math.sin(i / 15) * 4;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
      return;
    }

    // Draw animated waveform when playing - combining a bar graph and a wave
    final double barSpacing = width / waveCount;

    // Draw wave bars with varying heights
    for (int i = 0; i < waveCount; i++) {
      final double x = i * barSpacing;

      // Combine sine wave animation with random variation
      final double phase = (i / waveCount) * 2 * math.pi;
      final double offset = math.sin(animationValue * 2 * math.pi + phase);

      // Create more variance across the bars
      final double variance = 0.3 +
          0.7 *
              math.sin(
                  (i / waveCount * math.pi) + animationValue * math.pi * 2);

      // Calculate bar height (larger in the middle for a more natural look)
      final double centerEffect = 0.5 +
          0.5 * (1 - math.pow((i - waveCount / 2) / (waveCount / 2), 2).abs());
      final double barHeight = height * 0.6 * variance * centerEffect;

      // Draw bar
      canvas.drawLine(
        Offset(x + barSpacing / 2, centerY - barHeight / 2),
        Offset(x + barSpacing / 2, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.isPlaying != isPlaying;
  }
}
