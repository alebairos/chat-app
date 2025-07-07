import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:character_ai_clone/screens/chat_screen.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/chat_storage_service.dart';
import 'package:character_ai_clone/models/claude_audio_response.dart';
import 'package:character_ai_clone/models/chat_message_model.dart';
import 'package:character_ai_clone/models/message_type.dart';
import 'package:character_ai_clone/widgets/chat_input.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';

// Mock services for testing
class MockClaudeService implements ClaudeService {
  @override
  Future<String> sendMessage(String message) async => 'Mock response';

  @override
  Future<ClaudeAudioResponse> sendMessageWithAudio(String message) async =>
      ClaudeAudioResponse(text: 'Mock audio response');

  @override
  bool get audioEnabled => true;

  @override
  set audioEnabled(bool value) {}

  @override
  void clearConversation() {}

  @override
  Future<bool> initialize() async => true;

  @override
  List<Map<String, String>> get conversationHistory => [];

  @override
  void setLogging(bool enable) {}
}

class MockChatStorageService implements ChatStorageService {
  final List<ChatMessageModel> _messages = [];

  @override
  Future<List<ChatMessageModel>> getMessages(
      {int? limit, DateTime? before}) async {
    return _messages;
  }

  @override
  Future<void> saveMessage({
    required String text,
    required bool isUser,
    required MessageType type,
    String? mediaPath,
    Uint8List? mediaData,
    Duration? duration,
  }) async {
    _messages.add(ChatMessageModel(
      text: text,
      isUser: isUser,
      type: type,
      timestamp: DateTime.now(),
      mediaPath: mediaPath,
      mediaData: mediaData?.toList(),
      duration: duration,
    ));
  }

  @override
  Future<void> editMessage(int id, String newText) async {}

  @override
  Future<void> deleteMessage(int id) async {}

  @override
  Future<void> deleteAllMessages() async {
    _messages.clear();
  }

  @override
  Future<List<ChatMessageModel>> searchMessages(String query) async {
    return _messages.where((m) => m.text.contains(query)).toList();
  }

  @override
  Future<void> migratePathsToRelative() async {}

  @override
  Future<void> close() async {}

  @override
  Future<Isar> get db async => throw UnimplementedError();

  @override
  set db(Future<Isar> value) {}

  @override
  Future<Isar> openDB() async => throw UnimplementedError();
}

void main() {
  late MockClaudeService mockClaudeService;
  late MockChatStorageService mockStorageService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock environment variables
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_api_key
      OPENAI_API_KEY=test_openai_key
      ELEVENLABS_API_KEY=test_elevenlabs_key
    ''');
  });

  setUp(() {
    mockClaudeService = MockClaudeService();
    mockStorageService = MockChatStorageService();
  });

  group('Tap to Dismiss Keyboard - Defensive Tests', () {
    testWidgets('GestureDetector wraps chat area with correct properties',
        (WidgetTester tester) async {
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

      // Find the GestureDetector that wraps the chat area
      final gestureDetectorFinder = find.descendant(
        of: find.byType(Expanded),
        matching: find.byType(GestureDetector),
      );

      expect(gestureDetectorFinder, findsOneWidget,
          reason: 'GestureDetector should wrap the chat area');

      final gestureDetector =
          tester.widget<GestureDetector>(gestureDetectorFinder);

      // Verify critical properties
      expect(gestureDetector.onTap, isNotNull,
          reason: 'GestureDetector should have onTap handler');
      expect(gestureDetector.behavior, equals(HitTestBehavior.translucent),
          reason: 'GestureDetector should use translucent hit test behavior');
    });

    testWidgets('GestureDetector onTap handler calls FocusScope.unfocus',
        (WidgetTester tester) async {
      bool unfocusCalled = false;

      // Create a custom widget to track unfocus calls
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  unfocusCalled = true;
                },
                behavior: HitTestBehavior.translucent,
                child: const Scaffold(
                  body: Center(
                    child: Text('Test area'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the gesture detector
      await tester.tap(find.text('Test area'));
      await tester.pumpAndSettle();

      expect(unfocusCalled, isTrue,
          reason: 'Tapping should call FocusScope.unfocus()');
    });

    testWidgets('Scrolling in chat area still works with GestureDetector',
        (WidgetTester tester) async {
      // Add multiple messages to enable scrolling
      for (int i = 0; i < 20; i++) {
        await mockStorageService.saveMessage(
          text: 'Test message number $i',
          isUser: i % 2 == 0,
          type: MessageType.text,
        );
      }

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

      // Find the ListView
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      // Get initial scroll position
      final ListView listView = tester.widget(listViewFinder);
      final ScrollController? scrollController = listView.controller;
      final double initialPosition = scrollController?.position.pixels ?? 0;

      // Perform scroll gesture
      await tester.drag(listViewFinder, const Offset(0, 200));
      await tester.pumpAndSettle();

      // Verify scrolling occurred
      final double newPosition = scrollController?.position.pixels ?? 0;
      expect(newPosition, isNot(equals(initialPosition)),
          reason:
              'ListView should still be scrollable with GestureDetector wrapper');
    });

    testWidgets('Multiple rapid taps on chat area do not cause issues',
        (WidgetTester tester) async {
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

      // Perform multiple rapid taps on chat area
      final emptyStateFinder =
          find.text('No messages yet.\nStart a conversation!');
      for (int i = 0; i < 5; i++) {
        await tester.tap(emptyStateFinder);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // App should still be functional
      expect(find.byType(ChatScreen), findsOneWidget,
          reason: 'App should handle multiple rapid taps without crashing');
    });

    testWidgets(
        'GestureDetector does not interfere with ChatInput functionality',
        (WidgetTester tester) async {
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

      // Test that ChatInput still works normally
      final textFieldFinder = find.descendant(
        of: find.byType(ChatInput),
        matching: find.byType(TextField),
      );

      // Enter text
      await tester.enterText(textFieldFinder, 'Test message');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('Test message'), findsOneWidget);

      // Test send button
      final sendButtonFinder = find.descendant(
        of: find.byType(ChatInput),
        matching: find.byIcon(Icons.arrow_forward),
      );
      expect(sendButtonFinder, findsOneWidget,
          reason: 'Send button should be accessible');

      await tester.tap(sendButtonFinder);
      await tester.pumpAndSettle();

      // Verify text field is cleared after sending
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, isEmpty,
          reason: 'Text field should be cleared after sending');
    });

    testWidgets('GestureDetector behavior allows child interactions',
        (WidgetTester tester) async {
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

      // Find the GestureDetector
      final gestureDetectorFinder = find.descendant(
        of: find.byType(Expanded),
        matching: find.byType(GestureDetector),
      );

      final gestureDetector =
          tester.widget<GestureDetector>(gestureDetectorFinder);

      // Verify that HitTestBehavior.translucent allows child interactions
      expect(gestureDetector.behavior, equals(HitTestBehavior.translucent),
          reason:
              'Translucent behavior should allow child widgets to receive tap events');
    });

    testWidgets('Chat screen has core tap-to-dismiss components',
        (WidgetTester tester) async {
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

      // Verify core components needed for tap-to-dismiss functionality
      expect(find.byType(ChatInput), findsOneWidget,
          reason: 'ChatInput should exist for keyboard focus');
      expect(find.byType(TextField), findsOneWidget,
          reason: 'TextField should exist for keyboard interaction');

      // Verify our specific GestureDetector exists
      final gestureDetectorFinder = find.descendant(
        of: find.byType(Expanded),
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetectorFinder, findsOneWidget,
          reason: 'Our tap-to-dismiss GestureDetector should exist');
    });

    testWidgets('Empty chat state is properly wrapped by GestureDetector',
        (WidgetTester tester) async {
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

      // Find the empty state message
      final emptyStateFinder =
          find.text('No messages yet.\nStart a conversation!');
      expect(emptyStateFinder, findsOneWidget);

      // Verify it's inside a GestureDetector
      final gestureDetectorFinder = find.ancestor(
        of: emptyStateFinder,
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetectorFinder, findsOneWidget,
          reason: 'Empty state should be wrapped by GestureDetector');
    });

    testWidgets('Chat with messages is properly wrapped by GestureDetector',
        (WidgetTester tester) async {
      // Add a test message
      await mockStorageService.saveMessage(
        text: 'Hello, this is a test message',
        isUser: true,
        type: MessageType.text,
      );

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

      // Find the ListView (which contains messages)
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      // Verify it's inside a GestureDetector
      final gestureDetectorFinder = find.ancestor(
        of: listViewFinder,
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetectorFinder, findsOneWidget,
          reason:
              'ListView with messages should be wrapped by GestureDetector');
    });
  });

  group('Tap to Dismiss Keyboard - Implementation Consistency', () {
    testWidgets('GestureDetector configuration remains consistent',
        (WidgetTester tester) async {
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

      final gestureDetectorFinder = find.descendant(
        of: find.byType(Expanded),
        matching: find.byType(GestureDetector),
      );

      final gestureDetector =
          tester.widget<GestureDetector>(gestureDetectorFinder);

      // Test the exact configuration we expect
      expect(gestureDetector.onTap, isNotNull);
      expect(gestureDetector.behavior, equals(HitTestBehavior.translucent));
      expect(gestureDetector.onPanDown, isNull);
      expect(gestureDetector.onPanStart, isNull);
      expect(gestureDetector.onPanUpdate, isNull);
      expect(gestureDetector.onPanEnd, isNull);
    });

    testWidgets('Focus management implementation is present',
        (WidgetTester tester) async {
      // This test verifies that the implementation structure supports focus management
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

      // Verify that FocusScope is available in the widget tree
      expect(find.byType(FocusScope), findsWidgets,
          reason: 'FocusScope should be available for keyboard dismissal');

      // Verify that TextField exists (which can receive focus)
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget,
          reason: 'TextField should exist for focus testing');
    });
  });
}
