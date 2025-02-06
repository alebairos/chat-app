import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAITranscriptionService {
  static const String _baseUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  late final String _apiKey;

  OpenAITranscriptionService() {
    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  }

  Future<String> transcribeAudio(String audioPath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl))
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..files.add(await http.MultipartFile.fromPath('file', audioPath))
        ..fields['model'] = 'whisper-1';

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['text'] ?? 'No transcription available';
      }
      return 'Transcription failed: ${response.statusCode}';
    } catch (e) {
      debugPrint('OpenAI Transcription error: $e');
      return 'Transcription unavailable';
    }
  }
}
