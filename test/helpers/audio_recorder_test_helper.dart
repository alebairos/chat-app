import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAudioRecorder extends StatefulWidget {
  final Function(String, Duration)? onSendAudio;
  final bool isRecorded;
  final bool isRecording;

  const TestAudioRecorder({
    this.onSendAudio,
    this.isRecorded = false,
    this.isRecording = false,
    super.key,
  });

  @override
  State<TestAudioRecorder> createState() => _TestAudioRecorderState();
}

class _TestAudioRecorderState extends State<TestAudioRecorder> {
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isDeleting = false;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    if (widget.isRecorded) {
      _recordedFilePath = 'test_path';
    }
    _isRecording = widget.isRecording;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isRecording &&
              !_isPlaying &&
              !_isDeleting &&
              _recordedFilePath == null)
            IconButton(
              onPressed: () {
                setState(() {
                  _isRecording = true;
                });
              },
              icon: const Icon(Icons.mic),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.grey[200],
                minimumSize: const Size(48.0, 48.0),
              ),
              tooltip: 'Record audio message',
            ),
          if (_isRecording)
            IconButton(
              onPressed: () {
                setState(() {
                  _isRecording = false;
                  _recordedFilePath = 'test_path';
                });
              },
              icon: const Icon(Icons.stop, color: Colors.red),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.red[100],
                minimumSize: const Size(48.0, 48.0),
              ),
              tooltip: 'Stop recording',
            ),
          if (_recordedFilePath != null && !_isRecording && !_isDeleting) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _recordedFilePath = null;
                  _isPlaying = false;
                });
              },
              icon: const Icon(Icons.delete),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.grey[200],
                minimumSize: const Size(48.0, 48.0),
              ),
              tooltip: 'Delete recording',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.grey[200],
                minimumSize: const Size(48.0, 48.0),
              ),
              tooltip: _isPlaying ? 'Stop playback' : 'Play recording',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: !_isPlaying
                  ? () {
                      widget.onSendAudio
                          ?.call(_recordedFilePath!, Duration.zero);
                      setState(() {
                        _recordedFilePath = null;
                      });
                    }
                  : null,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(48.0, 48.0),
              ),
              tooltip: 'Send audio message',
            ),
          ],
        ],
      ),
    );
  }
}

class AudioRecorderTestHelper {
  static Widget buildTestWidget({
    Function(String, Duration)? onSendAudio,
    bool isRecorded = false,
    bool isRecording = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TestAudioRecorder(
          onSendAudio: onSendAudio,
          isRecorded: isRecorded,
          isRecording: isRecording,
        ),
      ),
    );
  }

  static Future<void> simulateRecording(WidgetTester tester) async {
    // Start recording
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();

    // Verify recording state
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsNothing);

    // Stop recording
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();

    // Verify post-recording state
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  }

  static Future<void> simulateRecordingComplete(WidgetTester tester) async {
    // Initial state check
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byIcon(Icons.send), findsNothing);

    // Rebuild with recorded state
    await tester.pumpWidget(buildTestWidget(isRecorded: true));
    await tester.pump();

    // Verify post-recording state
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsNothing);
    expect(find.byIcon(Icons.mic), findsNothing);
  }

  static Future<void> verifyButtonOrder(WidgetTester tester) async {
    final deleteRect = tester.getRect(find.byIcon(Icons.delete));
    final playRect = tester.getRect(find.byIcon(Icons.play_arrow));
    final sendRect = tester.getRect(find.byIcon(Icons.send));

    expect(deleteRect.left, lessThan(playRect.left));
    expect(playRect.left, lessThan(sendRect.left));
  }

  static Future<void> verifyButtonSpacing(WidgetTester tester) async {
    // Get button positions
    final deleteButton = find.byIcon(Icons.delete);
    final playButton = find.byIcon(Icons.play_arrow);
    final sendButton = find.byIcon(Icons.send);

    // Verify all buttons are present
    expect(deleteButton, findsOneWidget);
    expect(playButton, findsOneWidget);
    expect(sendButton, findsOneWidget);

    // Get button positions
    final deleteRect = tester.getRect(deleteButton);
    final playRect = tester.getRect(playButton);
    final sendRect = tester.getRect(sendButton);

    // Verify buttons are in the correct order with consistent spacing
    expect(deleteRect.right, lessThan(playRect.left));
    expect(playRect.right, lessThan(sendRect.left));

    // Verify spacing is consistent (should be equal between all buttons)
    final spacing1 = playRect.left - deleteRect.right;
    final spacing2 = sendRect.left - playRect.right;
    expect(spacing1, equals(spacing2),
        reason: 'Spacing between buttons should be consistent');
  }

  static Future<void> verifyButtonStyle(
    WidgetTester tester,
    IconData icon, {
    Color? backgroundColor,
    Color? foregroundColor,
  }) async {
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(icon),
        matching: find.byType(IconButton),
      ),
    );

    if (backgroundColor != null) {
      expect(button.style?.backgroundColor?.resolve({}), backgroundColor);
    }
    if (foregroundColor != null) {
      expect(button.style?.foregroundColor?.resolve({}), foregroundColor);
    }
    expect(button.style?.shape?.resolve({}), isA<CircleBorder>());
  }
}
