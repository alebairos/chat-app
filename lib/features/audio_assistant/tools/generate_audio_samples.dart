import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../services/text_to_speech_service.dart';

/// A utility widget to generate audio samples for testing.
///
/// This widget can be used to generate audio samples and save them to the
/// app's documents directory. The files can then be manually copied to the
/// assets directory for inclusion in the app bundle.
class GenerateAudioSamples extends StatefulWidget {
  const GenerateAudioSamples({Key? key}) : super(key: key);

  @override
  State<GenerateAudioSamples> createState() => _GenerateAudioSamplesState();
}

class _GenerateAudioSamplesState extends State<GenerateAudioSamples> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _isGenerating = false;
  String _status = 'Ready to generate audio samples';
  final List<String> _logs = [];
  String? _outputDirectory;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _setupOutputDirectory();
  }

  Future<void> _setupOutputDirectory() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${appDocDir.path}/audio_samples');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      setState(() {
        _outputDirectory = outputDir.path;
        _logs.add('Output directory: $_outputDirectory');
      });
    } catch (e) {
      setState(() {
        _status = 'Error setting up output directory: $e';
        _logs.add('Error setting up output directory: $e');
      });
    }
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

    if (_outputDirectory == null) {
      setState(() {
        _status = 'Output directory not set up';
        _logs.add('Output directory not set up');
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'Generating audio samples...';
      _logs.add('Starting audio sample generation');
    });

    try {
      // Generate welcome message
      _addLog('Generating welcome message...');
      const welcomeMessage =
          'Welcome to the chat app! I can now respond with voice messages.';
      final welcomeAudioFile = await _ttsService.generate(welcomeMessage);

      final welcomeOutputPath = '$_outputDirectory/welcome_message.mp3';
      await File(welcomeAudioFile.path).copy(welcomeOutputPath);
      _addLog('Welcome message saved to: $welcomeOutputPath');
      _addLog('Duration: ${welcomeAudioFile.duration.inMilliseconds}ms');

      // Generate assistant response
      _addLog('Generating assistant response...');
      const assistantResponse =
          'I\'ve analyzed your code and found a few issues. '
          'First, there\'s a missing semicolon on line 42. '
          'Second, the function on line 78 could be optimized by using a more efficient algorithm. '
          'Would you like me to fix these issues for you?';
      final assistantAudioFile = await _ttsService.generate(assistantResponse);

      final assistantOutputPath = '$_outputDirectory/assistant_response.mp3';
      await File(assistantAudioFile.path).copy(assistantOutputPath);
      _addLog('Assistant response saved to: $assistantOutputPath');
      _addLog('Duration: ${assistantAudioFile.duration.inMilliseconds}ms');

      setState(() {
        _status = 'Audio samples generated successfully';
        _logs.add('Audio samples generated successfully');
        _logs.add('\nNext steps:');
        _logs.add(
            '1. Copy the generated files from the app\'s documents directory to your project\'s assets/audio directory:');
        _logs.add('   - From: $welcomeOutputPath');
        _logs.add('   - To: <project_root>/assets/audio/welcome_message.mp3');
        _logs.add('   - From: $assistantOutputPath');
        _logs
            .add('   - To: <project_root>/assets/audio/assistant_response.mp3');
        _logs.add('2. Add the following to your pubspec.yaml assets section:');
        _logs.add('   - assets/audio/welcome_message.mp3');
        _logs.add('   - assets/audio/assistant_response.mp3');
        _logs.add('3. Run "flutter pub get" to update dependencies');
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

  void _shareFiles() async {
    if (_outputDirectory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No output directory available')),
      );
      return;
    }

    setState(() {
      _logs.add('\nTo access these files on your device:');
      _logs.add('1. Connect your device to your computer');
      _logs.add(
          '2. Use Finder (Mac) or File Explorer (Windows) to browse the device files');
      _logs.add('3. Navigate to the app\'s documents directory');
      _logs.add('4. Look for the "audio_samples" folder');
      _logs.add(
          '5. Copy the MP3 files to your project\'s assets/audio directory');
    });

    _copyLogsToClipboard();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instructions copied to clipboard')),
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
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareFiles,
            tooltip: 'Share files',
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
