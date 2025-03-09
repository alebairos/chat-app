import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/text_to_speech_service.dart';

/// A utility widget to generate audio samples for testing.
///
/// This widget can be used to generate audio samples and save them to the
/// assets directory. It should be run on a real device or emulator.
class GenerateAudioSamples extends StatefulWidget {
  const GenerateAudioSamples({Key? key}) : super(key: key);

  @override
  State<GenerateAudioSamples> createState() => _GenerateAudioSamplesState();
}

class _GenerateAudioSamplesState extends State<GenerateAudioSamples> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _isGenerating = false;
  String _status = 'Ready to generate audio samples';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    final initialized = await _ttsService.initialize();
    if (initialized) {
      setState(() {
        _status = 'TTS service initialized successfully';
        _logs.add('TTS service initialized successfully');
      });
    } else {
      setState(() {
        _status = 'Failed to initialize TTS service';
        _logs.add('Failed to initialize TTS service');
      });
    }
  }

  Future<void> _generateAudioSamples() async {
    if (!_ttsService.isInitialized) {
      setState(() {
        _status = 'TTS service not initialized';
        _logs.add('TTS service not initialized');
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Generating audio samples...';
      _logs.add('Starting audio sample generation');
    });

    try {
      // Create assets directory if it doesn't exist
      final assetDir = Directory('assets/audio');
      if (!await assetDir.exists()) {
        await assetDir.create(recursive: true);
        _addLog('Created assets/audio directory');
      }

      // Generate welcome message
      _addLog('Generating welcome message...');
      const welcomeMessage =
          'Welcome to the chat app! I can now respond with voice messages.';
      final welcomeAudioFile = await _ttsService.generate(welcomeMessage);

      final welcomeAssetPath = '${assetDir.path}/welcome_message.mp3';
      await File(welcomeAudioFile.path).copy(welcomeAssetPath);
      _addLog('Welcome message saved to: $welcomeAssetPath');
      _addLog('Duration: ${welcomeAudioFile.duration.inMilliseconds}ms');

      // Generate assistant response
      _addLog('Generating assistant response...');
      const assistantResponse =
          'I\'ve analyzed your code and found a few issues. '
          'First, there\'s a missing semicolon on line 42. '
          'Second, the function on line 78 could be optimized by using a more efficient algorithm. '
          'Would you like me to fix these issues for you?';
      final assistantAudioFile = await _ttsService.generate(assistantResponse);

      final assistantAssetPath = '${assetDir.path}/assistant_response.mp3';
      await File(assistantAudioFile.path).copy(assistantAssetPath);
      _addLog('Assistant response saved to: $assistantAssetPath');
      _addLog('Duration: ${assistantAudioFile.duration.inMilliseconds}ms');

      setState(() {
        _status = 'Audio samples generated successfully';
        _logs.add('Audio samples generated successfully');
        _logs.add(
            '\nReminder: Add the following to your pubspec.yaml assets section:');
        _logs.add('  - assets/audio/welcome_message.mp3');
        _logs.add('  - assets/audio/assistant_response.mp3');
      });
    } catch (e) {
      setState(() {
        _status = 'Error generating audio samples: $e';
        _logs.add('Error generating audio samples: $e');
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _addLog(String log) {
    setState(() {
      _logs.add(log);
    });
  }

  void _copyLogsToClipboard() {
    final text = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Audio Samples'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: 'Copy logs to clipboard',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _status,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateAudioSamples,
              child: Text(
                  _isGenerating ? 'Generating...' : 'Generate Audio Samples'),
            ),
            const SizedBox(height: 16),
            const Text('Logs:'),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(_logs[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entry point for the audio sample generation tool.
///
/// This function can be called from a main.dart file to run the tool.
/// Example:
/// ```dart
/// void main() {
///   runApp(MaterialApp(
///     home: GenerateAudioSamples(),
///   ));
/// }
/// ```
void runAudioSampleGenerator() {
  runApp(
    MaterialApp(
      title: 'Audio Sample Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GenerateAudioSamples(),
    ),
  );
}
