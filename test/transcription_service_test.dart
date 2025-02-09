import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/transcription_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'dart:convert';
import 'dart:io';

import 'transcription_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late OpenAITranscriptionService transcriptionService;
  late MockClient mockClient;

  setUp(() async {
    await dotenv.load(fileName: '.env');
    mockClient = MockClient();
    transcriptionService = OpenAITranscriptionService(client: mockClient);
  });

  group('Service Initialization', () {
    test('OpenAI service initializes correctly', () {
      expect(transcriptionService.isInitialized, true,
          reason:
              'OpenAI service should be initialized with API key from .env');
    });

    test('Handles missing API key gracefully', () {
      dotenv.env.remove('OPENAI_API_KEY');
      final serviceWithoutKey = OpenAITranscriptionService(client: mockClient);
      expect(serviceWithoutKey.isInitialized, isFalse);
      dotenv.env['OPENAI_API_KEY'] = 'test_key'; // Restore for other tests
    });

    test('Initializes with custom client', () {
      final customService = OpenAITranscriptionService(client: mockClient);
      expect(customService.isInitialized, true);
    });
  });

  group('Error Handling', () {
    test('Transcription handles invalid path gracefully', () async {
      final result =
          await transcriptionService.transcribeAudio('invalid_path.m4a');
      expect(result, 'Transcription unavailable');
    });

    test('Handles API error gracefully', () async {
      final file = File('test/assets/test_audio.m4a');
      await file.writeAsString('test audio content');

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('Error')),
          400,
        );
      });

      final result = await transcriptionService
          .transcribeAudio('test/assets/test_audio.m4a');
      expect(result, startsWith('Transcription failed'));

      await file.delete();
    });

    test('Handles network errors gracefully', () async {
      final file = File('test/assets/test_audio.m4a');
      await file.writeAsString('test audio content');

      when(mockClient.send(any)).thenThrow(Exception('Network error'));

      final result = await transcriptionService
          .transcribeAudio('test/assets/test_audio.m4a');
      expect(result, 'Transcription unavailable');

      await file.delete();
    });

    test('Handles malformed JSON response', () async {
      final file = File('test/assets/test_audio.m4a');
      await file.writeAsString('test audio content');

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"malformed json')),
          200,
        );
      });

      final result = await transcriptionService
          .transcribeAudio('test/assets/test_audio.m4a');
      expect(result, 'Transcription unavailable');

      await file.delete();
    });

    test('Handles empty response body', () async {
      final file = File('test/assets/test_audio.m4a');
      await file.writeAsString('test audio content');

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
        );
      });

      final result = await transcriptionService
          .transcribeAudio('test/assets/test_audio.m4a');
      expect(result, 'Transcription unavailable');

      await file.delete();
    });
  });

  group('Successful Transcription', () {
    test('Handles successful transcription', () async {
      final file = File('test/assets/test_audio.m4a');
      await file.writeAsString('test audio content');

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(
              utf8.encode(json.encode({'text': 'Test transcription'}))),
          200,
        );
      });

      final result = await transcriptionService
          .transcribeAudio('test/assets/test_audio.m4a');
      expect(result, 'Test transcription');

      await file.delete();
    });

    test('Handles successful transcription with special characters', () async {
      final file = File('test/assets/test_audio.m4a');
      await file.writeAsString('test audio content');

      final specialText = 'Test with special chars: áéíóú ñ';
      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(json.encode({'text': specialText}))),
          200,
        );
      });

      final result = await transcriptionService
          .transcribeAudio('test/assets/test_audio.m4a');
      expect(result, specialText);

      await file.delete();
    });

    test('Handles successful transcription with empty text', () async {
      final file = File('test/assets/test_audio.m4a');
      await file.writeAsString('test audio content');

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(json.encode({'text': null}))),
          200,
        );
      });

      final result = await transcriptionService
          .transcribeAudio('test/assets/test_audio.m4a');
      expect(result, 'No transcription available');

      await file.delete();
    });
  });

  group('Request Validation', () {
    test('Sends correct headers and model', () async {
      final file = File('test/assets/test_audio.m4a');
      await file.writeAsString('test audio content');

      http.MultipartRequest? capturedRequest;
      when(mockClient.send(any)).thenAnswer((invocation) async {
        capturedRequest =
            invocation.positionalArguments.first as http.MultipartRequest;
        return http.StreamedResponse(
          Stream.value(utf8.encode(json.encode({'text': 'Test'}))),
          200,
        );
      });

      await transcriptionService.transcribeAudio('test/assets/test_audio.m4a');

      expect(capturedRequest!.headers['Authorization'], startsWith('Bearer '));
      expect(capturedRequest!.fields['model'], equals('whisper-1'));

      await file.delete();
    });
  });
}
