import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/path_utils.dart';
import 'dart:async';

class AudioRecorder extends StatefulWidget {
  final Function(String path, Duration duration)? onSendAudio;
  final Record? testRecord;
  final AudioPlayer? testPlayer;

  const AudioRecorder({
    this.onSendAudio,
    this.testRecord,
    this.testPlayer,
    super.key,
  });

  @override
  State<AudioRecorder> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  late final Record _audioRecorder;
  late final AudioPlayer _audioPlayer;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isDeleting = false;
  bool _isLoading = false;
  String? _recordedFilePath;
  Duration _recordDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = widget.testRecord ?? Record();
    _audioPlayer = widget.testPlayer ?? AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() => _isPlaying = false);
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Error: $message',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.0,
          ),
        ),
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
        elevation: 6.0,
        width: 400.0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _startRecording() async {
    debugPrint('\n🎙️ Starting recording process');
    try {
      if (await _audioRecorder.hasPermission()) {
        debugPrint('✓ Recording permission granted');

        final dir = await getApplicationDocumentsDirectory();
        debugPrint('📂 Documents directory: ${dir.path}');

        final audioDir = Directory('${dir.path}/audio');
        if (!await audioDir.exists()) {
          await audioDir.create(recursive: true);
          debugPrint('📁 Created audio directory: ${audioDir.path}');
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'audio_$timestamp.m4a';
        final filePath = '${audioDir.path}/$fileName';
        debugPrint('📝 Recording to file: $filePath');

        debugPrint('🎬 Starting record.start()');
        await _audioRecorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
        debugPrint('✓ record.start() completed');

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration += const Duration(seconds: 1);
            debugPrint('⏱️ Recording duration: ${_recordDuration.inSeconds}s');
          });
        });

        debugPrint('🔄 Updating recording state');
        setState(() {
          _isRecording = true;
          _recordedFilePath = filePath;
        });
        debugPrint('✓ State updated - isRecording: $_isRecording');
      } else {
        debugPrint('❌ No recording permission');
      }
    } catch (e) {
      debugPrint('❌ Error recording audio: $e');
      _showErrorSnackBar('Recording audio: $e');
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
    if (_isRecording) {
      _showErrorSnackBar('Cannot play while recording');
      return;
    }

    if (_recordedFilePath != null) {
      try {
        if (_isPlaying) {
          await _audioPlayer.stop();
          setState(() => _isPlaying = false);
        } else {
          setState(() => _isLoading = true);

          final file = File(_recordedFilePath!);
          if (!await file.exists()) {
            throw Exception('Audio file not found');
          }
          await _audioPlayer.stop(); // Ensure any previous playback is stopped
          await _audioPlayer.setSourceDeviceFile(_recordedFilePath!);
          await _audioPlayer.resume();
          setState(() {
            _isPlaying = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error playing audio: $e');
        setState(() => _isLoading = false);
        _showErrorSnackBar('Playing audio: $e');
      }
    }
  }

  Future<void> _sendAudio() async {
    if (_isRecording) {
      await _stopRecording();
    }

    if (_recordedFilePath != null) {
      try {
        // Convert absolute path to relative path for storage
        final relativePath =
            await PathUtils.absoluteToRelative(_recordedFilePath!);
        if (relativePath == null) {
          throw Exception('Failed to convert to relative path');
        }

        widget.onSendAudio?.call(_recordedFilePath!, _recordDuration);
        setState(() {
          _recordedFilePath = null;
          _recordDuration = Duration.zero;
        });
      } catch (e) {
        debugPrint('Error sending audio: $e');
        _showErrorSnackBar('Sending audio: $e');
      }
    }
  }

  Future<void> _deleteRecording() async {
    if (_recordedFilePath == null) return;

    try {
      setState(() => _isDeleting = true);

      // Stop playback if playing
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() => _isPlaying = false);
      }

      // Delete file
      final file = File(_recordedFilePath!);
      if (await file.exists()) {
        await file.delete();
      }

      // Reset state
      setState(() {
        _recordedFilePath = null;
        _recordDuration = Duration.zero;
        _isDeleting = false;
      });
    } catch (e) {
      debugPrint('❌ Error deleting audio: $e');
      _showErrorSnackBar('Deleting audio: $e');
      setState(() => _isDeleting = false);
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
                padding: const EdgeInsets.all(8.0),
                minimumSize: const Size(48.0, 48.0),
              ),
              tooltip: 'Record audio message',
            ),
          if (_isRecording)
            IconButton(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop, color: Colors.red),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.all(8.0),
                minimumSize: const Size(48.0, 48.0),
              ),
              tooltip: 'Stop recording',
            ),
          if (_recordedFilePath != null && !_isDeleting) ...[
            IconButton(
              onPressed: _deleteRecording,
              icon: const Icon(Icons.delete),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.all(8.0),
                minimumSize: const Size(48.0, 48.0),
              ),
              tooltip: 'Delete recording',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isDeleting ? null : _playRecording,
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),
                    )
                  : Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.all(8.0),
                minimumSize: const Size(48.0, 48.0),
              ),
              tooltip: _isPlaying ? 'Stop playback' : 'Play recording',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isDeleting ? null : _sendAudio,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(8.0),
                minimumSize: const Size(48.0, 48.0),
              ),
              tooltip: 'Send audio message',
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
