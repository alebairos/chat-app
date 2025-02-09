import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/screens/chat_screen.dart';
import 'package:character_ai_clone/models/chat_message_model.dart';
import 'package:character_ai_clone/models/message_type.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/services/chat_storage_service.dart';
import '../lib/services/claude_service.dart';
import 'chat_screen_test.mocks.dart'; // Import the generated mocks

@GenerateMocks([ChatStorageService, ClaudeService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockChatStorageService mockStorage;
  late MockClaudeService mockClaude;

  setUp(() {
    mockStorage = MockChatStorageService();
    mockClaude = MockClaudeService();

    // Setup mock responses
    when(mockStorage.getMessages()).thenAnswer((_) async => [
          ChatMessageModel(
            text: 'Test message',
            isUser: true,
            type: MessageType.text,
            timestamp: DateTime.now(),
          )..id = 1
        ]);

    when(mockStorage.editMessage(any, any)).thenAnswer((_) async {});
    when(mockStorage.db).thenAnswer((_) async => throw UnimplementedError());

    when(mockClaude.sendMessage(any)).thenAnswer((_) async => 'Mock response');
  });

  group('ChatScreen Edit Functionality', () {
    late Widget testWidget;

    setUp(() async {
      // Mock environment variables instead of loading from file
      dotenv.testLoad(fileInput: '''
        ANTHROPIC_API_KEY=test_key
        OPENAI_API_KEY=test_key
      ''');

      testWidget = MaterialApp(
        home: ChatScreen(
          storageService: mockStorage,
          claudeService: mockClaude,
        ),
      );
    });

    testWidgets('shows edit dialog when edit menu item is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Open message menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap edit option
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Verify edit dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Message'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('edit dialog shows current message text',
        (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Open message menu and edit dialog
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Find the TextField by key
      final textField = find.byKey(const Key('edit-message-field'));
      expect(textField, findsOneWidget);
      expect((tester.widget(textField) as TextField).controller?.text,
          'Test message');
    });

    testWidgets('can edit message text and save changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Open message menu and edit dialog
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Test editing
      await tester.enterText(
          find.byKey(const Key('edit-message-field')), 'Edited message');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify storage service was called
      verify(mockStorage.editMessage(any, 'Edited message')).called(1);

      // Verify success message
      expect(find.text('Message edited'), findsOneWidget);
    });

    testWidgets('cannot save empty message text', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Open message menu and edit dialog
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Try to save empty text
      await tester.enterText(
          find.byKey(const Key('edit-message-field')), '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify storage service was not called
      verifyNever(mockStorage.editMessage(any, any));

      // Verify error message
      expect(find.text('Message cannot be empty'), findsOneWidget);
    });

    testWidgets('can cancel edit without saving', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Open message menu and edit dialog
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Enter new text but cancel
      await tester.enterText(
          find.byKey(const Key('edit-message-field')), 'Should not be saved');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify storage service was not called
      verifyNever(mockStorage.editMessage(any, any));

      // Verify dialog is closed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('handles storage errors gracefully',
        (WidgetTester tester) async {
      // Setup storage to throw error
      when(mockStorage.editMessage(any, any))
          .thenThrow(Exception('Storage error'));

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Open message menu and edit dialog
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Try to save changes
      await tester.enterText(
          find.byKey(const Key('edit-message-field')), 'Updated message');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Error editing message: Exception: Storage error'),
          findsOneWidget);
    });

    testWidgets('only user messages can be edited',
        (WidgetTester tester) async {
      // Setup mock with bot message
      final botMessage = ChatMessageModel(
        text: 'Bot message',
        isUser: false,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );
      botMessage.id = 2;

      when(mockStorage.getMessages(limit: any))
          .thenAnswer((_) async => [botMessage]);

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Open message menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify edit option is not present
      expect(find.text('Edit'), findsNothing);
    });
  });
}
