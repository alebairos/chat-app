import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/path_utils.dart';

class AudioMessage extends StatefulWidget {
  final String audioPath;
  final bool isUser;
  final String transcription;
  final Duration duration;

  const AudioMessage({
    required this.audioPath,
    required this.isUser,
    required this.transcription,
    required this.duration,
    super.key,
  });

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      setState(() => _isPlaying = false);
    });
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _player.pause();
        setState(() => _isPlaying = false);
      } else {
        setState(() => _isLoading = true);

        // Get absolute path if needed
        String absolutePath;
        if (PathUtils.isAbsolutePath(widget.audioPath)) {
          absolutePath = widget.audioPath;
        } else {
          absolutePath = await PathUtils.relativeToAbsolute(widget.audioPath);
        }

        // Check if file exists
        final file = File(absolutePath);
        if (!await file.exists()) {
          throw Exception('Audio file not found at ${widget.audioPath}');
        }

        // Stop any currently playing audio first
        await _player.stop();

        // Set up the audio source
        await _player.setSourceDeviceFile(absolutePath);

        // Start playback
        await _player.resume();
        setState(() {
          _isPlaying = true;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() {
        _isPlaying = false;
        _isLoading = false;
        _errorMessage = 'Error playing audio: ${e.toString()}';
      });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Audio controls in a more subtle color
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey[700],
                  ),
                )
              else
                IconButton(
                  onPressed: _togglePlayback,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.grey[700],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
              Text(
                '${widget.duration.inMinutes}:${(widget.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 4),
          // Transcription text
          Text(
            widget.transcription,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }
}
