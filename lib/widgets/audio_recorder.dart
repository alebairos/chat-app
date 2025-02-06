import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class AudioRecorder extends StatefulWidget {
  final Function(String path, Duration duration)? onSendAudio;

  const AudioRecorder({
    this.onSendAudio,
    super.key,
  });

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  final _audioRecorder = Record();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  Duration _recordDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() => _isPlaying = false);
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/audio_note.m4a';

        await _audioRecorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration += const Duration(seconds: 1));
        });

        setState(() {
          _isRecording = true;
          _recordedFilePath = filePath;
        });
      }
    } catch (e) {
      debugPrint('Error recording audio: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();
      await _audioRecorder.stop();
      setState(() => _isRecording = false);
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null) {
      try {
        if (_isPlaying) {
          await _audioPlayer.stop();
          setState(() => _isPlaying = false);
        } else {
          await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
          setState(() => _isPlaying = true);
        }
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    }
  }

  Future<void> _sendAudio() async {
    if (_recordedFilePath != null) {
      widget.onSendAudio?.call(_recordedFilePath!, _recordDuration);
      setState(() {
        _recordedFilePath = null;
        _recordDuration = Duration.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isRecording && _recordedFilePath == null)
            IconButton(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.grey[200],
              ),
            ),
          if (_isRecording)
            IconButton(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop, color: Colors.red),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.red[100],
              ),
            ),
          if (_recordedFilePath != null) ...[
            IconButton(
              onPressed: _playRecording,
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.grey[200],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendAudio,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
