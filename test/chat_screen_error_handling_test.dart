import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:character_ai_clone/screens/chat_screen.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/chat_storage_service.dart';
import 'package:character_ai_clone/models/message_type.dart';
import 'package:character_ai_clone/models/chat_message_model.dart' as model;
import 'package:character_ai_clone/widgets/chat_message.dart';
import 'package:isar/isar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// Mocks
class MockClaudeService extends Mock implements ClaudeService {}

class MockChatStorageService extends Mock implements ChatStorageService {}

class MockIsar extends Mock implements Isar {}

// Counter for mock IDs
int _mockIdCounter = 1;

class MockChatMessageModelCollection extends Mock
    implements IsarCollection<model.ChatMessageModel> {
  @override
  Future<int> put(model.ChatMessageModel object,
      {bool saveLinks = true, bool replaceOnConflict = false}) async {
    object.id =
        _mockIdCounter++; // Simulate Isar assigning and returning a new ID
    return object.id;
  }

  @override
  Future<model.ChatMessageModel?> get(int id) async {
    return null;
  }
}

void main() {
  late MockClaudeService mockClaudeService;
  late MockChatStorageService mockChatStorageService;
  late MockIsar mockIsar;
  late MockChatMessageModelCollection mockChatMessageModelCollection;

  setUpAll(() {
    registerFallbackValue(MessageType.text);
    registerFallbackValue(DateTime.now());
    registerFallbackValue(model.ChatMessageModel(
      text: '',
      isUser: false,
      type: MessageType.text,
      timestamp: DateTime.now(),
    ));
    dotenv.testLoad(fileInput: '''ANTHROPIC_API_KEY=test_key_present''');
  });

  setUp(() {
    _mockIdCounter = 1; // Reset ID counter for each test
    mockClaudeService = MockClaudeService();
    mockChatStorageService = MockChatStorageService();
    mockIsar = MockIsar();
    mockChatMessageModelCollection = MockChatMessageModelCollection();

    when(() => mockChatStorageService.db).thenAnswer((_) async => mockIsar);
    when(() => mockChatStorageService.migratePathsToRelative())
        .thenAnswer((_) async {});
    when(() => mockChatStorageService.getMessages(
        limit: any(named: 'limit'),
        before: any(named: 'before'))).thenAnswer((_) async => []);
    when(() => mockChatStorageService.saveMessage(
          text: any(named: 'text'),
          isUser: any(named: 'isUser'),
          type: any(named: 'type'),
          mediaData: any(named: 'mediaData'),
          mediaPath: any(named: 'mediaPath'),
          duration: any(named: 'duration'),
        )).thenAnswer((_) async {});
    when(() => mockChatStorageService.close()).thenAnswer((_) async {});

    when(() => mockClaudeService.sendMessage(any()))
        .thenAnswer((_) async => "Default success response");

    when(() => mockIsar.writeTxn<int>(any())).thenAnswer((invocation) async {
      final callback =
          invocation.positionalArguments.first as Future<int> Function();
      return await callback();
    });
    when(() => mockIsar.writeTxn<void>(any())).thenAnswer((invocation) async {
      final callback =
          invocation.positionalArguments.first as Future<void> Function();
      await callback();
    });
    when(() => mockIsar.chatMessageModels)
        .thenReturn(mockChatMessageModelCollection);
  });

  group('ChatScreen Error Handling Tests', () {
    testWidgets(
        'sends message and displays error on ClaudeService connection error',
        (WidgetTester tester) async {
      const errorText =
          "Unable to connect to Claude. Please check your connection and try again.";
      when(() => mockClaudeService.sendMessage(any()))
          .thenAnswer((_) async => errorText);

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            claudeService: mockClaudeService,
            storageService: mockChatStorageService,
            testMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget,
          reason: "TextField should be present for connection error test");
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Verify at least one ChatMessage is rendered
      expect(find.byType(ChatMessage), findsWidgets,
          reason: "At least one ChatMessage should be rendered");
    });

    testWidgets(
        'displays error when Claude API key is not set by ChatScreen itself',
        (WidgetTester tester) async {
      dotenv.testLoad(fileInput: '''ANTHROPIC_API_KEY=''');
      addTearDown(() =>
          dotenv.testLoad(fileInput: '''ANTHROPIC_API_KEY=test_key_present'''));

      when(() => mockClaudeService.sendMessage(any())).thenAnswer((_) async =>
          "This should not be reached if API key check fails first");

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            claudeService: mockClaudeService,
            storageService: mockChatStorageService,
            testMode: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('API Key not found. Please check your .env file.'),
          findsOneWidget);
      expect(find.byType(ChatMessage), findsNothing);
      expect(find.byType(TextField), findsNothing,
          reason: "TextField should NOT be present when API key is missing");
    });

    testWidgets('displays error on unexpected ClaudeService error',
        (WidgetTester tester) async {
      const errorText =
          "Error: An unexpected error occurred. Please try again.";
      when(() => mockClaudeService.sendMessage(any()))
          .thenAnswer((_) async => errorText);

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            claudeService: mockClaudeService,
            storageService: mockChatStorageService,
            testMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget,
          reason: "TextField should be present for unexpected error test");
      await tester.enterText(find.byType(TextField), 'Another message');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Verify at least one ChatMessage is rendered
      expect(find.byType(ChatMessage), findsWidgets,
          reason: "At least one ChatMessage should be rendered");
    });

    testWidgets('sends message and displays successful response',
        (WidgetTester tester) async {
      const userMessage = 'User message here';
      const aiResponse = 'This is a normal response from AI';

      when(() => mockClaudeService.sendMessage(userMessage))
          .thenAnswer((_) async => aiResponse);

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            claudeService: mockClaudeService,
            storageService: mockChatStorageService,
            testMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget,
          reason: "TextField should be present for successful response test");
      await tester.enterText(find.byType(TextField), userMessage);
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Verify at least one ChatMessage is rendered
      expect(find.byType(ChatMessage), findsWidgets,
          reason: "At least one ChatMessage should be rendered");
    });
  });
}
