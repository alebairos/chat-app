import 'package:flutter/material.dart';
import 'generate_test_audio.dart';

/// A simple app to test TTS functionality on a real device.
///
/// To run this app:
/// 1. Connect a real device
/// 2. Run: flutter run -t lib/features/audio_assistant/tools/test_tts_app.dart
void main() {
  runApp(const TestTTSApp());
}

class TestTTSApp extends StatelessWidget {
  const TestTTSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTS Test App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TestAudioGeneratorWidget(),
    );
  }
}
