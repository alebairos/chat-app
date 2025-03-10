import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import '../services/text_to_speech_service.dart';

/// A utility class to generate test audio files on a real device.
///
/// This can be used to test the TTS functionality and generate sample audio files
/// for use in the app. It's designed to be run from a simple Flutter app.
class TestAudioGenerator {
  final TextToSpeechService _ttsService;
  final FlutterTts _flutterTts;

  TestAudioGenerator()
      : _flutterTts = FlutterTts(),
        _ttsService = TextToSpeechService(FlutterTts());

  /// Initialize the TTS service
  Future<bool> initialize() async {
    return await _ttsService.initialize();
  }

  /// Generate a test audio file with the given text
  Future<String> generateTestAudio(String text,
      {String language = 'en-US'}) async {
    try {
      // Set the language
      await _flutterTts.setLanguage(language);

      // Generate the audio file
      final audioFile = await _ttsService.generate(text);

      // Verify the file exists
      final file = File(audioFile.path);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0) {
          return 'Generated audio file at: ${audioFile.path}\nSize: $fileSize bytes\nDuration: ${audioFile.duration.inMilliseconds}ms';
        } else {
          return 'Error: Generated file exists but is empty: ${audioFile.path}';
        }
      } else {
        return 'Error: Failed to generate audio file at: ${audioFile.path}';
      }
    } catch (e) {
      return 'Error generating audio: $e';
    }
  }

  /// Copy the generated audio file to the assets directory
  Future<String> copyToAssets(String sourcePath, String assetName) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return 'Error: Source file does not exist: $sourcePath';
      }

      // Get the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final assetDir = Directory('${appDir.path}/assets/audio');
      if (!await assetDir.exists()) {
        await assetDir.create(recursive: true);
      }

      // Copy the file
      final targetPath = '${assetDir.path}/$assetName';
      await sourceFile.copy(targetPath);

      return 'Copied audio file to: $targetPath';
    } catch (e) {
      return 'Error copying file: $e';
    }
  }
}

/// A simple widget to test audio generation on a real device
class TestAudioGeneratorWidget extends StatefulWidget {
  const TestAudioGeneratorWidget({Key? key}) : super(key: key);

  @override
  State<TestAudioGeneratorWidget> createState() =>
      _TestAudioGeneratorWidgetState();
}

class _TestAudioGeneratorWidgetState extends State<TestAudioGeneratorWidget> {
  final TestAudioGenerator _generator = TestAudioGenerator();
  final TextEditingController _textController = TextEditingController();
  String _result = 'Press the button to generate audio';
  bool _isGenerating = false;
  String _language = 'en-US';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final initialized = await _generator.initialize();
    setState(() {
      _result = initialized
          ? 'TTS service initialized successfully. Enter text and press Generate.'
          : 'Failed to initialize TTS service';
    });
  }

  Future<void> _generateAudio() async {
    if (_textController.text.isEmpty) {
      setState(() {
        _result = 'Please enter some text';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _result = 'Generating audio...';
    });

    final result = await _generator.generateTestAudio(
      _textController.text,
      language: _language,
    );

    setState(() {
      _isGenerating = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Audio Generator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text to convert to speech',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _language,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'en-US', child: Text('English (US)')),
                DropdownMenuItem(
                    value: 'pt-BR', child: Text('Portuguese (Brazil)')),
                DropdownMenuItem(
                    value: 'es-ES', child: Text('Spanish (Spain)')),
                DropdownMenuItem(
                    value: 'fr-FR', child: Text('French (France)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateAudio,
              child: _isGenerating
                  ? const CircularProgressIndicator()
                  : const Text('Generate Audio'),
            ),
            const SizedBox(height: 16),
            const Text('Result:'),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(_result),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
