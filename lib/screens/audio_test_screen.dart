import 'dart:io';
import 'package:flutter/material.dart';
import '../features/audio_assistant/models/audio_file.dart';
import '../features/audio_assistant/services/audio_playback_manager.dart';
import '../features/audio_assistant/services/eleven_labs_tts_service.dart';
import '../features/audio_assistant/services/tts_service_factory.dart';

class AudioTestScreen extends StatefulWidget {
  const AudioTestScreen({Key? key}) : super(key: key);

  @override
  State<AudioTestScreen> createState() => _AudioTestScreenState();
}

class _AudioTestScreenState extends State<AudioTestScreen> {
  final TextEditingController _textController = TextEditingController();
  final AudioPlaybackManager _playbackManager = AudioPlaybackManager();
  late ElevenLabsTTSService _ttsService;
  bool _isInitialized = false;
  bool _isGenerating = false;
  bool _isPlaying = false;
  String _statusMessage = 'Initializing...';
  AudioFile? _generatedAudio;
  bool _testMode = true;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    setState(() {
      _statusMessage = 'Initializing TTS service...';
    });

    try {
      // Create the TTS service
      _ttsService = ElevenLabsTTSService();

      // Initialize in test mode by default
      if (_testMode) {
        _ttsService.enableTestMode();
      }

      final initialized = await _ttsService.initialize();

      setState(() {
        _isInitialized = initialized;
        _statusMessage = initialized
            ? 'TTS service initialized successfully'
            : 'Failed to initialize TTS service';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing TTS service: $e';
      });
    }
  }

  Future<void> _generateAudio() async {
    if (!_isInitialized) {
      setState(() {
        _statusMessage = 'TTS service not initialized';
      });
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter some text';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating audio...';
    });

    try {
      final audioFile = await _ttsService.generate(text);

      setState(() {
        _generatedAudio = audioFile;
        _isGenerating = false;
        _statusMessage = 'Audio generated successfully: ${audioFile.path}';
      });

      // Verify the file exists
      final file = File(audioFile.path);
      final exists = await file.exists();
      final fileSize = exists ? await file.length() : 0;

      setState(() {
        _statusMessage += '\nFile exists: $exists, Size: $fileSize bytes';
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _statusMessage = 'Error generating audio: $e';
      });
    }
  }

  Future<void> _playAudio() async {
    if (_generatedAudio == null) {
      setState(() {
        _statusMessage = 'No audio to play';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Playing audio...';
    });

    try {
      final widgetId = 'test_screen_${DateTime.now().millisecondsSinceEpoch}';
      final result =
          await _playbackManager.playAudio(widgetId, _generatedAudio!);

      setState(() {
        _isPlaying = result;
        _statusMessage = result ? 'Audio playing' : 'Failed to play audio';
      });
    } catch (e) {
      setState(() {
        _isPlaying = false;
        _statusMessage = 'Error playing audio: $e';
      });
    }
  }

  void _toggleTestMode() {
    setState(() {
      _testMode = !_testMode;
      if (_testMode) {
        _ttsService.enableTestMode();
        _statusMessage = 'Test mode enabled - using mock audio';
      } else {
        _ttsService.disableTestMode();
        _statusMessage = 'Test mode disabled - using real ElevenLabs API';
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Integration Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to convert to speech',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateAudio,
                    child: _isGenerating
                        ? const CircularProgressIndicator()
                        : const Text('Generate Audio'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _generatedAudio == null ? null : _playAudio,
                    child: const Text('Play Audio'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Test Mode'),
              subtitle: Text(_testMode
                  ? 'Using mock audio (no API calls)'
                  : 'Using real ElevenLabs API'),
              value: _testMode,
              onChanged: (_) => _toggleTestMode(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(_statusMessage),
                ),
              ),
            ),
            if (_generatedAudio != null) ...[
              const SizedBox(height: 16),
              Text(
                'Audio Duration: ${_generatedAudio!.duration.inSeconds}.${_generatedAudio!.duration.inMilliseconds % 1000} seconds',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
