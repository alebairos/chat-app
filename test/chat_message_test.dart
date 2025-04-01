import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import services for MethodChannel
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:character_ai_clone/widgets/chat_message.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/audio_message.dart';
import 'package:character_ai_clone/features/audio_assistant/widgets/assistant_audio_message.dart';
import 'package:character_ai_clone/features/audio_assistant/services/audio_playback.dart';
import 'package:character_ai_clone/features/audio_assistant/models/audio_file.dart';
import 'package:character_ai_clone/features/audio_assistant/models/playback_state.dart';
import 'helpers/test_messages.dart';
import 'package:mocktail/mocktail.dart';

// Mock using mocktail - simplified, no specific method setup needed here now
class MockAudioPlayback extends Mock implements AudioPlayback {
  final _stateController = StreamController<PlaybackState>.broadcast();
  final _positionController = StreamController<int>.broadcast();

  @override
  Stream<PlaybackState> get onStateChanged => _stateController.stream;

  @override
  Stream<int> get onPositionChanged => _positionController.stream;

  @override
  PlaybackState get state => PlaybackState.stopped;

  @override
  Future<void> dispose() async {
    _stateController.close();
    _positionController.close();
  }
}

void main() {
  // Ensure binding is initialized for platform channel mocking
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // Register fallback values for mocktail
  registerFallbackValue(AudioFile(path: '', duration: Duration.zero));

  // Mock the audioplayers platform channel before tests run
  setUpAll(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async {
        // Handle the 'create' call that causes the MissingPluginException
        if (methodCall.method == 'create') {
          return 1; // Return a valid player ID
        }
        // Handle other methods if they cause issues later
        return null;
      },
    );
  });

  // Clear the mock handler after tests
  tearDownAll(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'), null);
  });

  late MockAudioPlayback mockAudioPlayback;

  setUp(() {
    mockAudioPlayback = MockAudioPlayback();

    // Set up default responses for the mock
    when(() => mockAudioPlayback.initialize()).thenAnswer((_) async => true);
    when(() => mockAudioPlayback.load(any())).thenAnswer((_) async => true);
    when(() => mockAudioPlayback.play()).thenAnswer((_) async => true);
    when(() => mockAudioPlayback.pause()).thenAnswer((_) async => true);
    when(() => mockAudioPlayback.stop()).thenAnswer((_) async => true);
    when(() => mockAudioPlayback.seekTo(any())).thenAnswer((_) async => true);
  });

  tearDown(() {
    mockAudioPlayback.dispose();
  });

  group('ChatMessage Widget', () {
    // Helper function simplified
    Widget createTestWidget({
      String? text,
      bool isUser = false,
      String? audioPath,
      Duration? duration,
      String? transcription,
      bool isTest = true,
      AudioPlayback? audioPlayback,
      Key? key,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChatMessage(
            text: text ?? transcription ?? '',
            isUser: isUser,
            audioPath: audioPath,
            duration: duration,
            isTest: isTest,
            audioPlayback: audioPlayback,
            key: key,
          ),
        ),
      );
    }

    group('Text Messages', () {
      testWidgets('renders text message with correct styling', (tester) async {
        await tester.pumpWidget(createTestWidget(text: 'Test message'));
        await tester.pumpAndSettle();

        // Verify text content
        expect(find.text('Test message'), findsOneWidget);

        // Verify container styling
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('Test message'),
            matching: find.byType(Container),
          ),
        );
        expect(container.decoration, isNotNull);
        expect((container.decoration as BoxDecoration).color,
            equals(Colors.grey[200]));
      });

      testWidgets('renders user message with correct styling', (tester) async {
        await tester
            .pumpWidget(createTestWidget(text: 'User message', isUser: true));
        await tester.pumpAndSettle();

        // Verify text content and styling
        expect(find.text('User message'), findsOneWidget);
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('User message'),
            matching: find.byType(Container),
          ),
        );
        expect((container.decoration as BoxDecoration).color,
            equals(Colors.blue[100]));
      });
    });

    group('ChatMessage Widget Audio Messages', () {
      testWidgets('renders audio message correctly', (tester) async {
        final key = UniqueKey();
        final audioPath = 'test_audio.mp3';
        final transcription = 'Test transcription';
        final duration = const Duration(seconds: 30);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatMessage(
                key: key,
                text: transcription,
                audioPath: audioPath,
                duration: duration,
                audioPlayback: mockAudioPlayback,
                isUser: false,
                isTest: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the transcription is displayed
        expect(find.text(transcription), findsOneWidget);

        // Verify the play icon is present
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      });

      testWidgets('renders fallback message when audio is unavailable',
          (tester) async {
        final key = UniqueKey();
        final transcription = 'Test transcription';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatMessage(
                key: key,
                text: transcription,
                audioPath: 'nonexistent.m4a',
                duration: const Duration(seconds: 30),
                audioPlayback: mockAudioPlayback,
                isUser: false,
                isTest: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify both the transcription and fallback message are displayed
        expect(find.text(transcription), findsOneWidget);
        expect(find.text('Audio unavailable'), findsOneWidget);
      });
    });

    group('Message Actions', () {
      testWidgets('shows menu options for user messages', (tester) async {
        await tester.pumpWidget(createTestWidget(
          text: 'User message',
          isUser: true,
        ));
        await tester.pumpAndSettle();

        // Open menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Verify menu options
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);
        expect(find.text('Report'), findsOneWidget);
      });

      testWidgets('shows limited menu options for bot messages',
          (tester) async {
        await tester.pumpWidget(createTestWidget(text: 'Bot message'));
        await tester.pumpAndSettle();

        // Open menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Verify menu options
        expect(find.text('Edit'), findsNothing);
        expect(find.text('Delete'), findsNothing);
        expect(find.text('Copy'), findsOneWidget);
        expect(find.text('Report'), findsOneWidget);
      });
    });
  });
}
