import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAITranscriptionService {
  static const String _baseUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  final String _apiKey;
  final http.Client _client;
  bool _initialized = false;

  OpenAITranscriptionService({http.Client? client})
      : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '',
        _client = client ?? http.Client() {
    _initialized = _apiKey.isNotEmpty;
  }

  bool get isInitialized => _initialized;

  Future<String> transcribeAudio(String audioPath) async {
    if (!isInitialized) {
      return 'Transcription unavailable: Service not initialized';
    }

    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        return 'Transcription unavailable';
      }

      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl))
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..headers['Accept'] = 'application/json; charset=utf-8'
        ..headers['Content-Type'] = 'multipart/form-data; charset=utf-8'
        ..files.add(await http.MultipartFile.fromPath('file', audioPath))
        ..fields['model'] = 'whisper-1';

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return jsonResponse['text'] ?? 'No transcription available';
      }
      return 'Transcription failed: ${response.statusCode}';
    } catch (e) {
      // Just return the error message without printing during tests
      return 'Transcription unavailable';
    }
  }
}
