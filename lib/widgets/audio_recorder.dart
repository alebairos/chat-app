import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
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
      if (_isRecording) {
        _showErrorSnackBar('Cannot start recording while already recording');
        return;
      }
      if (_isPlaying) {
        _showErrorSnackBar('Cannot record while playing');
        return;
      }
      if (_isDeleting) {
        _showErrorSnackBar('Cannot record while deleting');
        return;
      }

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
        final filePath = '${audioDir.path}/audio_$timestamp.m4a';
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
      if (!_isRecording) {
        debugPrint('❌ Not currently recording');
        return;
      }

      debugPrint('🛑 Stopping recording');
      _recordingTimer?.cancel();
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordDuration = Duration.zero;
        debugPrint('✓ Recording stopped');
      });
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    debugPrint('▶️ Starting playback operation');
    if (_recordedFilePath == null) {
      debugPrint('❌ No recorded file to play');
      return;
    }

    if (_isRecording) {
      debugPrint('❌ Cannot play while recording');
      _showErrorSnackBar('Cannot play while recording');
      return;
    }
    if (_isDeleting) {
      debugPrint('❌ Cannot play while deleting');
      _showErrorSnackBar('Cannot play while deleting');
      return;
    }

    try {
      if (_isPlaying) {
        debugPrint('⏹️ Stopping current playback');
        await _audioPlayer.stop();
        setState(() => _isPlaying = false);
        debugPrint('✓ Playback stopped');
      } else {
        final file = File(_recordedFilePath!);
        if (!await file.exists()) {
          debugPrint('❌ Audio file not found');
          throw Exception('Audio file not found');
        }
        debugPrint('▶️ Starting new playback');
        await _audioPlayer.stop(); // Ensure any previous playback is stopped
        await _audioPlayer.setSourceDeviceFile(_recordedFilePath!);
        await _audioPlayer.resume();
        setState(() => _isPlaying = true);
        debugPrint('✓ Playback started');
      }
    } catch (e) {
      debugPrint('❌ Error playing audio: $e');
      _showErrorSnackBar('Playing audio: $e');
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _deleteRecording() async {
    debugPrint('🗑️ Starting delete operation');
    if (_recordedFilePath == null) {
      debugPrint('❌ No recorded file to delete');
      return;
    }

    if (_isRecording) {
      _showErrorSnackBar('Cannot delete while recording');
      return;
    }
    if (_isPlaying) {
      _showErrorSnackBar('Cannot delete while playing');
      return;
    }
    if (_isDeleting) {
      _showErrorSnackBar('Cannot delete while deleting');
      return;
    }

    try {
      setState(() => _isDeleting = true);
      debugPrint('🗑️ Deleting file: $_recordedFilePath');

      final file = File(_recordedFilePath!);
      if (await file.exists()) {
        await file.delete();
        debugPrint('✓ File deleted successfully');
      }

      setState(() {
        _recordedFilePath = null;
        _isDeleting = false;
        _recordDuration = Duration.zero;
      });
      debugPrint('✓ Delete operation completed');
    } catch (e) {
      debugPrint('❌ Error deleting recording: $e');
      _showErrorSnackBar('Error deleting recording: $e');
      setState(() => _isDeleting = false);
    }
  }

  Future<void> _sendAudio() async {
    debugPrint('📤 Starting send operation');
    if (_recordedFilePath == null) {
      debugPrint('❌ No recorded file to send');
      return;
    }

    if (_isRecording) {
      _showErrorSnackBar('Cannot send while recording');
      return;
    }
    if (_isPlaying) {
      _showErrorSnackBar('Cannot send while playing');
      return;
    }
    if (_isDeleting) {
      _showErrorSnackBar('Cannot send while deleting');
      return;
    }

    try {
      final file = File(_recordedFilePath!);
      if (!await file.exists()) {
        throw Exception('Audio file not found');
      }

      debugPrint('📤 Sending audio file: $_recordedFilePath');
      widget.onSendAudio?.call(_recordedFilePath!, _recordDuration);
      debugPrint('✓ Audio sent successfully');

      // Reset state for next recording, but do not delete the file here.
      // The recipient of onSendAudio is now responsible for managing the file lifecycle.
      setState(() {
        _recordedFilePath = null;
        _recordDuration = Duration.zero;
        // _isRecording, _isPlaying, _isDeleting should already be false here
        // or handled by their respective actions. Ensure UI consistency.
      });
    } catch (e) {
      debugPrint('❌ Error sending audio: $e');
      _showErrorSnackBar('Error sending audio: $e');
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
              onPressed: !_isPlaying && !_isDeleting ? _startRecording : null,
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
          if (_recordedFilePath != null) ...[
            IconButton(
              onPressed: !_isRecording && !_isPlaying && !_isDeleting
                  ? _deleteRecording
                  : null,
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
              onPressed: !_isRecording && !_isPlaying && !_isDeleting
                  ? _playRecording
                  : null,
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
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
              onPressed: !_isRecording && !_isPlaying && !_isDeleting
                  ? _sendAudio
                  : null,
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
