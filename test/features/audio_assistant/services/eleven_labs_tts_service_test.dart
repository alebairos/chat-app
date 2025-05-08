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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;

class MockHttpClient extends Mock implements http.Client {}

class MockHttpResponse extends Mock implements http.Response {}

class MockFile extends Mock implements File {}

class MockDirectory extends Mock implements Directory {
  final String mockPath;
  MockDirectory(this.mockPath);

  @override
  String get path => mockPath;
}

class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ElevenLabsTTSService', () {
    late MockHttpClient mockHttpClient;
    late MockDirectory mockDirectory;
    late ElevenLabsTTSService service;
    late MockPathProviderPlatform mockPathProvider;

    setUpAll(() async {
      // Load .env file
      await dotenv.load(fileName: '.env');

      // Register fallback values
      registerFallbackValue(Uri());
      registerFallbackValue(MockFile());
      registerFallbackValue(MockDirectory('/test/audio/directory'));
    });

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockDirectory = MockDirectory('/test/docs/eleven_labs_audio');
      mockPathProvider = MockPathProviderPlatform();
      PathProviderPlatform.instance = mockPathProvider;

      // Set up mock behavior for directory
      when(() => mockDirectory.exists()).thenAnswer((_) async => false);
      when(() => mockDirectory.create(recursive: any(named: 'recursive')))
          .thenAnswer((_) async => mockDirectory);

      // Set up mock behavior for path provider
      when(() => mockPathProvider.getApplicationDocumentsPath())
          .thenAnswer((_) async => '/test/docs');

      service = ElevenLabsTTSService(mockDirectory);
    });

    test(
      'initializes correctly in test mode',
      () async {
        service.enableTestMode();
        final result = await service.initialize();

        expect(result, isTrue);
        expect(service.isInitialized, isTrue);

        // Verify the directory was created
        verify(() => mockDirectory.exists()).called(1);
        verify(() => mockDirectory.create(recursive: true)).called(1);
      },
    );

    test(
      'generates audio using mock in test mode',
      () async {
        service.enableTestMode();
        await service.initialize();

        final audioFile = await service.generate('Test message');

        expect(audioFile, isNotNull);
        expect(audioFile.path, equals('assets/audio/welcome_message.aiff'));
        expect(audioFile.duration, equals(const Duration(seconds: 3)));
      },
    );

    test(
      'uses different mock audio files based on text length',
      () async {
        service.enableTestMode();
        await service.initialize();

        final shortAudio = await service.generate('Short');
        final longAudio = await service.generate(
            'This is a much longer message that should result in a different audio file being used. ' +
                'We need to make sure this text is over 100 characters long to trigger the different audio file selection. ' +
                'This should be more than enough text to exceed the threshold.');

        expect(shortAudio.path, equals('assets/audio/welcome_message.aiff'));
        expect(shortAudio.duration, equals(const Duration(seconds: 3)));
        expect(longAudio.path, equals('assets/audio/assistant_response.aiff'));
        expect(longAudio.duration, equals(const Duration(seconds: 14)));
      },
    );
  });
}
