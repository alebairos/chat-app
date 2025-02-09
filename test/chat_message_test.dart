import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../lib/widgets/chat_message.dart';
import '../lib/widgets/audio_message.dart';
import 'helpers/test_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatMessage Widget', () {
    late Widget testWidget;

    setUpAll(() async {
      // Create fake asset bundle
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          return Uint8List(0).buffer.asByteData();
        },
      );
    });

    setUp(() {
      testWidget = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: TestMessage.formattedMessage,
            isUser: false,
            isTest: true,
          ),
        ),
      );
    });

    testWidgets('renders formatted text correctly', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Verify text content is present
      expect(find.textContaining(TestMessage.gesture), findsOneWidget);
      expect(find.textContaining(TestMessage.greeting), findsOneWidget);
      expect(find.textContaining(TestMessage.boldText), findsOneWidget);
      expect(find.textContaining(TestMessage.italicText), findsOneWidget);
      expect(find.textContaining(TestMessage.emoji), findsOneWidget);
    });

    testWidgets('applies correct text styling', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Find markdown text
      final markdownFinder = find.byType(MarkdownBody);
      expect(markdownFinder, findsOneWidget);

      // Verify text styling through markdown
      final markdownBody = tester.widget<MarkdownBody>(markdownFinder);
      expect(markdownBody.data, contains('**${TestMessage.boldText}**'));
      expect(markdownBody.data, contains('_${TestMessage.italicText}_'));
    });

    testWidgets('renders user message correctly', (tester) async {
      final userMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'User message',
            isUser: true,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(userMessage);
      await tester.pumpAndSettle();

      // User messages should be blue and aligned to the right
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Container),
              matching: find.byWidgetPredicate(
                (widget) => widget is Container && widget.decoration != null,
              ),
            )
            .last,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.blue));

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, equals(MainAxisAlignment.end));

      // User messages should not have an avatar
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('renders audio message correctly', (tester) async {
      final audioMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: 'Audio transcription',
            isUser: true,
            audioPath: 'test_audio.m4a',
            duration: const Duration(seconds: 30),
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(audioMessage);
      await tester.pumpAndSettle();

      expect(find.byType(AudioMessage), findsOneWidget);

      final audioWidget =
          tester.widget<AudioMessage>(find.byType(AudioMessage));
      expect(audioWidget.audioPath, equals('test_audio.m4a'));
      expect(audioWidget.duration, equals(const Duration(seconds: 30)));
      expect(audioWidget.transcription, equals('Audio transcription'));
    });

    test('copyWith creates correct copy', () {
      const original = ChatMessage(
        text: 'Original',
        isUser: false,
        audioPath: null,
        duration: null,
      );

      final copy = original.copyWith(
        text: 'Modified',
        isUser: true,
        audioPath: 'audio.m4a',
        duration: const Duration(seconds: 10),
      );

      expect(copy.text, equals('Modified'));
      expect(copy.isUser, isTrue);
      expect(copy.audioPath, equals('audio.m4a'));
      expect(copy.duration, equals(const Duration(seconds: 10)));

      // Test partial updates
      final partialCopy = original.copyWith(text: 'Only text changed');
      expect(partialCopy.text, equals('Only text changed'));
      expect(partialCopy.isUser, equals(original.isUser));
      expect(partialCopy.audioPath, equals(original.audioPath));
      expect(partialCopy.duration, equals(original.duration));
    });

    testWidgets('handles empty text gracefully', (tester) async {
      final emptyMessage = MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: '',
            isUser: false,
            isTest: true,
          ),
        ),
      );

      await tester.pumpWidget(emptyMessage);
      await tester.pumpAndSettle();

      expect(find.byType(MarkdownBody), findsOneWidget);
      final markdownBody =
          tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      expect(markdownBody.data, isEmpty);
    });
  });
}

// Helper class to mock network images
class NetworkImageTester {
  static void mockNetworkImages(Future<void> Function() callback) {
    HttpOverrides.runZoned(
      () async {
        await callback();
      },
      createHttpClient: (SecurityContext? context) {
        return _createMockImageHttpClient(context);
      },
    );
  }

  static HttpClient _createMockImageHttpClient(SecurityContext? context) {
    final client = _MockHttpClient();
    return client;
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
