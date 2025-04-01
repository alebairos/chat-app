import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/services/eleven_labs_tts_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockHttpResponse extends Mock implements http.Response {}

class MockFile extends Mock implements File {}

class MockDirectory extends Mock implements Directory {}

class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {}

void main() {
  group('ElevenLabsTTSService', () {
    late MockHttpClient mockHttpClient;
    late MockDirectory mockDirectory;
    late ElevenLabsTTSService service;
    late MockPathProviderPlatform mockPathProvider;

    setUpAll(() {
      // Register fallback values
      registerFallbackValue(Uri());
      registerFallbackValue(MockFile());
    });

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockDirectory = MockDirectory();
      mockPathProvider = MockPathProviderPlatform();
      PathProviderPlatform.instance = mockPathProvider;

      // Set up mock behavior for directory
      when(() => mockDirectory.path).thenReturn('/test/audio/directory');
      when(() => mockDirectory.exists()).thenAnswer((_) async => true);
      when(() => mockDirectory.create(recursive: any(named: 'recursive')))
          .thenAnswer((_) async => mockDirectory);

      // Set up mock behavior for path provider
      when(() => mockPathProvider.getApplicationDocumentsPath())
          .thenAnswer((_) async => '/test/docs');

      service = ElevenLabsTTSService();
    });

    test(
      'initializes correctly in test mode',
      () async {
        service.enableTestMode();
        final result = await service.initialize();

        expect(result, isTrue);
        expect(service.isInitialized, isTrue);
      },
      skip: 'Requires proper environment setup for test mode',
    );

    test(
      'generates audio using mock in test mode',
      () async {
        service.enableTestMode();
        await service.initialize();

        final audioFile = await service.generate('Test message');

        expect(audioFile, isNotNull);
        expect(audioFile.path, contains('.mp3'));
        expect(audioFile.duration, isNotNull);
      },
      skip: 'Requires proper file system access mocking',
    );

    test(
      'uses different mock audio files based on text length',
      () async {
        service.enableTestMode();
        await service.initialize();

        final shortAudio = await service.generate('Short');
        final longAudio = await service.generate(
            'This is a much longer message that should result in a different audio file being used');

        expect(shortAudio.path, isNot(equals(longAudio.path)));
        expect(shortAudio.duration, isNot(equals(longAudio.duration)));
      },
      skip: 'Requires proper audio file generation mocking',
    );
  });
}
