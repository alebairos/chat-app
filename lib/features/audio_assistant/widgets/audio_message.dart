import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_playback_manager.dart';
import '../models/audio_file.dart';
import 'audio_waveform.dart';
import '../../../utils/logger.dart';

class AudioMessage extends StatefulWidget {
  final String messageId;
  final String audioPath;
  final Duration audioDuration;
  final bool isAssistantMessage;

  const AudioMessage({
    Key? key,
    required this.messageId,
    required this.audioPath,
    required this.audioDuration,
    this.isAssistantMessage = false,
  }) : super(key: key);

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  late AudioPlaybackManager _playbackManager;
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _playbackManager = AudioPlaybackManager();
    _audioPlayer = AudioPlayer();

    _playbackManager.registerAudioPlayer(widget.messageId, _stopPlayback);

    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        logDebugPrint('Player ${widget.messageId} state changed: $state');
        setState(() {
          _playerState = state;
        });
        if (state == PlayerState.completed) {
          _playbackManager.stopPlayback(widget.messageId);
          _currentPosition = Duration.zero;
        }
      }
    }, onError: (error) {
      logDebugPrint('Player ${widget.messageId} state error: $error');
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
        });
        _playbackManager.stopPlayback(widget.messageId);
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && _playerState == PlayerState.playing) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  void _togglePlayback() async {
    logDebugPrint(
        'Toggling playback for ${widget.messageId}. Current state: $_playerState');
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
      logDebugPrint('Paused ${widget.messageId}');
    } else if (_playerState == PlayerState.paused) {
      _playbackManager.startPlayback(widget.messageId);
      await _audioPlayer.resume();
      logDebugPrint('Resumed ${widget.messageId}');
    } else {
      final file = File(widget.audioPath);
      if (await file.exists()) {
        _playbackManager.startPlayback(widget.messageId);
        try {
          await _audioPlayer.play(DeviceFileSource(widget.audioPath));
          logDebugPrint('Started playing ${widget.messageId}');
          setState(() {
            _currentPosition = Duration.zero;
          });
        } catch (e) {
          logDebugPrint('Error playing ${widget.messageId}: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error playing audio: ${e.toString()}')),
          );
          _playbackManager.stopPlayback(widget.messageId);
          setState(() {
            _playerState = PlayerState.stopped;
          });
        }
      } else {
        logDebugPrint(
            'Audio file not found for ${widget.messageId}: ${widget.audioPath}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio file not found')),
        );
        _playbackManager.stopPlayback(widget.messageId);
        setState(() {
          _playerState = PlayerState.stopped;
        });
      }
    }
  }

  void _stopPlayback() async {
    logDebugPrint('Received stop command for ${widget.messageId}');
    if (mounted &&
        (_playerState == PlayerState.playing ||
            _playerState == PlayerState.paused)) {
      await _audioPlayer.stop();
      logDebugPrint('Stopped player for ${widget.messageId}');
      setState(() {
        _currentPosition = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    logDebugPrint('Disposing AudioMessage ${widget.messageId}');
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer.release();
    _audioPlayer.dispose();
    _playbackManager.unregisterAudioPlayer(widget.messageId);
    super.dispose();
  }

  bool get _isPlaying => _playerState == PlayerState.playing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0),
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: widget.isAssistantMessage
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: _togglePlayback,
          ),

          // Waveform visualization
          AudioWaveform(
            audioPath: widget.audioPath,
            audioDuration: widget.audioDuration,
            isPlaying: _isPlaying,
            currentPosition: _currentPosition,
          ),

          // Duration text
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              _formatDuration(
                  _isPlaying ? _currentPosition : widget.audioDuration),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
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
