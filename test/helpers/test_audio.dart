import 'dart:io';
import 'package:path/path.dart' as path;

class TestAudio {
  static Future<void> setupTestAudioDirectory() async {
    final audioDir = Directory('./test_audio_messages');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
  }

  static Future<String> createTestAudioFile(String filename) async {
    await setupTestAudioDirectory();
    final filePath = path.join('./test_audio_messages', filename);
    final file = File(filePath);
    await file.writeAsString('test audio content');
    return filePath;
  }

  static Future<void> cleanupTestAudioDirectory() async {
    final audioDir = Directory('./test_audio_messages');
    if (await audioDir.exists()) {
      await audioDir.delete(recursive: true);
    }
  }
}
