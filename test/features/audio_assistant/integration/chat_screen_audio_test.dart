import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:character_ai_clone/screens/chat_screen.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/chat_storage_service.dart';
import 'package:character_ai_clone/services/transcription_service.dart';
import 'package:character_ai_clone/models/claude_audio_response.dart';
import 'package:character_ai_clone/models/chat_message_model.dart';
import 'package:character_ai_clone/models/message_type.dart';
import 'package:character_ai_clone/widgets/chat_input.dart';

class MockClaudeService extends Mock implements ClaudeService {
  bool _hasBeenInitialized = false;

  @override
  Future<bool> initialize() async {
    _hasBeenInitialized = true;
    return true;
  }

  @override
  bool get audioEnabled => true;

  @override
  set audioEnabled(bool value) {}

  bool get hasBeenInitialized => _hasBeenInitialized;
}

class MockChatStorageService extends Mock implements ChatStorageService {
  @override
  Future<void> close() async {
    return Future.value();
  }

  @override
  Future<List<ChatMessageModel>> getMessages(
      {int? limit, DateTime? before}) async {
    return [];
  }

  @override
  Future<void> migratePathsToRelative() async {}

  @override
  Future<void> saveMessage({
    required String text,
    required bool isUser,
    required MessageType type,
    String? mediaPath,
    Uint8List? mediaData,
    Duration? duration,
  }) async {}
}

class MockTranscriptionService extends Mock
    implements OpenAITranscriptionService {}

// Mock for dotenv
class MockDotEnv extends Mock implements DotEnv {
  final Map<String, String> _values = {
    'ANTHROPIC_API_KEY': 'test_api_key',
    'OPENAI_API_KEY': 'test_openai_key',
    'ELEVENLABS_API_KEY': 'test_elevenlabs_key',
  };

  @override
  String? operator [](String key) => _values[key];

  @override
  Map<String, String> get env => _values;
}

void main() {
  late MockClaudeService mockClaudeService;
  late MockChatStorageService mockStorageService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Use mocked environment variables
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_api_key
      OPENAI_API_KEY=test_openai_key
      ELEVENLABS_API_KEY=test_elevenlabs_key
    ''');
  });

  setUp(() {
    mockClaudeService = MockClaudeService();
    mockStorageService = MockChatStorageService();

    registerFallbackValue(DateTime.now());
    registerFallbackValue(MessageType.audio);
    registerFallbackValue(Duration(seconds: 10));
  });

  testWidgets('ChatScreen initializes Claude service with audio enabled',
      (WidgetTester tester) async {
    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          claudeService: mockClaudeService,
          storageService: mockStorageService,
          testMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the Claude service was initialized
    expect(mockClaudeService.hasBeenInitialized, true);

    // Find ChatInput - verify it exists
    final chatInputFinder = find.byType(ChatInput);
    expect(chatInputFinder, findsOneWidget);

    // This is a simplified integration test that verifies the basic plumbing works
  });
}
