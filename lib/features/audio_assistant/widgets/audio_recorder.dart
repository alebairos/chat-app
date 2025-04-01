import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/audio_file.dart';

class AudioRecorder extends StatefulWidget {
  final Function(AudioFile) onAudioRecorded;

  const AudioRecorder({
    Key? key,
    required this.onAudioRecorded,
  }) : super(key: key);

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          if (_isRecording)
            Container(
              width: 12.0,
              height: 12.0,
              margin: EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),

          // Recording duration
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                _formatDuration(_recordingDuration),
                style: theme.textTheme.bodyMedium,
              ),
            ),

          // Start recording button
          if (!_isRecording)
            IconButton(
              icon: Icon(Icons.mic, color: theme.colorScheme.primary),
              onPressed: _startRecording,
              tooltip: 'Start recording',
            ),

          // Stop recording button - ensure this is visible when recording
          if (_isRecording)
            IconButton(
              icon: Icon(Icons.stop, color: Colors.red),
              onPressed: _stopRecording,
              tooltip: 'Stop recording',
            ),
        ],
      ),
    );
  }

  void _startRecording() async {
    // Request microphone permissions if needed

    setState(() {
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingDuration = Duration.zero;
    });

    // Start a timer to update the recording duration
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && _isRecording && _recordingStartTime != null) {
        setState(() {
          _recordingDuration = DateTime.now().difference(_recordingStartTime!);
        });
      }
    });

    // Actual recording logic would go here
    // For now, we'll just simulate recording
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();

    // Simulate creating an audio file
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final audioPath = '${dir.path}/recording_$timestamp.mp3';

    // Create a dummy file
    await File(audioPath).create();

    // Create an AudioFile object
    final audioFile = AudioFile(
      path: audioPath,
      duration: _recordingDuration,
    );

    // Notify parent widget
    widget.onAudioRecorded(audioFile);

    // Reset state
    setState(() {
      _isRecording = false;
      _recordingStartTime = null;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
