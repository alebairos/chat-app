import 'dart:io';
import 'package:http/http.dart' as http;

class TranscriptionService {
  static const String _baseUrl = 'YOUR_TRANSCRIPTION_API';

  Future<String> transcribeAudio(String audioPath) async {
    try {
      final audioFile = File(audioPath);
      final bytes = await audioFile.readAsBytes();

      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl))
        ..files.add(http.MultipartFile.fromBytes('audio', bytes,
            filename: 'audio.m4a'));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Parse transcription from response
        return responseData;
      } else {
        throw Exception('Transcription failed');
      }
    } catch (e) {
      return 'Transcription unavailable';
    }
  }
}
