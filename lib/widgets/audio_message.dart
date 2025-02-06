import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioMessage extends StatefulWidget {
  final String audioPath;
  final bool isUser;
  final String? transcription;
  final Duration duration;

  const AudioMessage({
    required this.audioPath,
    required this.isUser,
    this.transcription,
    required this.duration,
    super.key,
  });

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

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
        await _player.play(DeviceFileSource(widget.audioPath));
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isUser ? Colors.blue : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _togglePlayback,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: widget.isUser ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${widget.duration.inMinutes}:${(widget.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: widget.isUser ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          if (widget.transcription != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
              child: Text(
                widget.transcription!,
                style: TextStyle(
                  color: widget.isUser ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
