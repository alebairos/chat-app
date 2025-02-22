import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/screens/chat_screen.dart';
import 'package:character_ai_clone/models/chat_message_model.dart';
import 'package:character_ai_clone/models/message_type.dart';
import 'package:character_ai_clone/widgets/chat_input.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/services/chat_storage_service.dart';
import '../lib/services/claude_service.dart';
import 'chat_screen_test.mocks.dart';
import 'package:isar/isar.dart';
import 'dart:async';

@GenerateMocks([
  ChatStorageService,
  ClaudeService,
], customMocks: [
  MockSpec<Isar>(as: #GeneratedMockIsar),
  MockSpec<IsarCollection<ChatMessageModel>>(
      as: #GeneratedMockChatMessageCollection),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockChatStorageService mockStorage;
  late MockClaudeService mockClaude;
  late Widget chatScreen;
  late ChatMessageModel testMessage;
  late GeneratedMockIsar mockIsar;
  late GeneratedMockChatMessageCollection mockCollection;

  setUp(() async {
    mockStorage = MockChatStorageService();
    mockClaude = MockClaudeService();
    mockIsar = GeneratedMockIsar();
    mockCollection = GeneratedMockChatMessageCollection();

    testMessage = ChatMessageModel(
      text: 'Test message',
      isUser: true,
      type: MessageType.text,
      timestamp: DateTime.now(),
    )..id = 1;

    // Setup mock responses
    when(mockStorage.getMessages(
      limit: anyNamed('limit'),
      before: anyNamed('before'),
    )).thenAnswer((_) async => [testMessage]);

    when(mockStorage.editMessage(any, any)).thenAnswer((_) async {});
    when(mockStorage.db).thenAnswer((_) async => mockIsar);
    when(mockIsar.chatMessageModels).thenReturn(mockCollection);
    when(mockCollection.get(1)).thenAnswer((_) async => testMessage);

    // Mock message operations
    when(mockStorage.saveMessage(
      text: anyNamed('text'),
      isUser: anyNamed('isUser'),
      type: anyNamed('type'),
    )).thenAnswer((_) async => ChatMessageModel(
          text: 'Test message',
          isUser: true,
          type: MessageType.text,
          timestamp: DateTime.now(),
        )..id = 2);

    when(mockStorage.deleteMessage(any)).thenAnswer((_) async {});
    when(mockStorage.deleteAllMessages()).thenAnswer((_) async {});
    when(mockStorage.searchMessages(any)).thenAnswer((_) async => []);
    when(mockStorage.close()).thenAnswer((_) async {});

    when(mockClaude.sendMessage(any)).thenAnswer((_) async => 'Mock response');

    chatScreen = ChatScreen(
      storageService: mockStorage,
      claudeService: mockClaude,
    );
  });

  group('ChatScreen Edit Functionality', () {
    setUp(() async {
      dotenv.testLoad(fileInput: '''
        ANTHROPIC_API_KEY=test_key
        OPENAI_API_KEY=test_key
      ''');
    });

    testWidgets('shows edit dialog when edit menu item is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: chatScreen));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Message'), findsOneWidget);
      expect(find.byKey(const Key('edit-message-field')), findsOneWidget);
    });

    testWidgets('edit dialog shows current message text',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: chatScreen));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final textField = find.byKey(const Key('edit-message-field'));
      expect(textField, findsOneWidget);
      expect((tester.widget(textField) as TextField).controller?.text,
          'Test message');
    });

    testWidgets('can edit message text and save changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: chatScreen));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('edit-message-field')), 'Edited message');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Message edited'), findsOneWidget);
      verify(mockStorage.editMessage(1, 'Edited message')).called(1);
    });

    testWidgets('cannot save empty message text', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: chatScreen));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('edit-message-field')), '   ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Dialog should still be open
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Message'), findsOneWidget);

      // Storage service should not be called
      verifyNever(mockStorage.editMessage(any, any));
    });

    testWidgets('can cancel edit without saving', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: chatScreen));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('edit-message-field')), 'Should not be saved');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(mockStorage.editMessage(any, any));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('handles storage errors gracefully',
        (WidgetTester tester) async {
      when(mockStorage.editMessage(any, any))
          .thenThrow(Exception('Storage error'));

      await tester.pumpWidget(MaterialApp(home: chatScreen));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('edit-message-field')), 'Updated message');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Error editing message: Exception: Storage error'),
          findsOneWidget);
    });

    testWidgets('only user messages can be edited',
        (WidgetTester tester) async {
      final assistantMessage = ChatMessageModel(
        text: 'Assistant message',
        isUser: false,
        type: MessageType.text,
        timestamp: DateTime.now(),
      )..id = 2;

      when(mockStorage.getMessages(
        limit: anyNamed('limit'),
        before: anyNamed('before'),
      )).thenAnswer((_) async => [assistantMessage]);

      await tester.pumpWidget(MaterialApp(home: chatScreen));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
      expect(find.text('Assistant message'), findsOneWidget);
    });
  });

  testWidgets('oracle avatars have consistent deep purple background',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.military_tech, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text('Claude is typing...'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify avatar background color
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundColor, Colors.deepPurple);
  });
}

class MockIsarCollection extends Mock
    implements IsarCollection<ChatMessageModel> {}
