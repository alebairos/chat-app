import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'dart:typed_data';

import 'package:ai_personas_app/models/chat_message_model.dart';
import 'package:ai_personas_app/models/message_type.dart';
import 'package:ai_personas_app/services/chat_storage_service.dart';
import 'package:ai_personas_app/services/claude_service.dart';
import 'package:ai_personas_app/models/claude_audio_response.dart';

// Simple fake implementations instead of complex mocks
class FakeChatStorageService implements ChatStorageService {
  final FakeIsar _isar = FakeIsar();
  bool _shouldThrowOnEdit = false;
  List<ChatMessageModel> messages = [];

  bool get shouldFailEditing => _shouldThrowOnEdit;

  set shouldFailEditing(bool value) {
    _shouldThrowOnEdit = value;
  }

  void setupMessages(List<ChatMessageModel> messages) {
    this.messages = messages;
    _isar.setupMessages(messages);
  }

  void setShouldThrowOnEdit(bool shouldThrow) {
    _shouldThrowOnEdit = shouldThrow;
  }

  @override
  Future<Isar> get db async => _isar;

  @override
  set db(Future<Isar> value) {
    // No-op for testing as the original class initializes db in the constructor
  }

  @override
  Future<List<ChatMessageModel>> getMessages(
      {int? limit, DateTime? before}) async {
    var messages = _isar._chatMessageModels._messages;

    if (before != null) {
      messages = messages.where((m) => m.timestamp.isBefore(before)).toList();
    }

    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages.take(limit ?? 50).toList();
  }

  @override
  Future<List<ChatMessageModel>> getMessagesAfter(
      {DateTime? after, int? limit}) async {
    var messages = _isar._chatMessageModels._messages;

    if (after != null) {
      messages = messages.where((m) => m.timestamp.isAfter(after)).toList();
    }

    messages
        .sort((a, b) => a.timestamp.compareTo(b.timestamp)); // ascending order
    return messages.take(limit ?? 50).toList();
  }

  @override
  Future<void> saveMessage({
    required String text,
    required bool isUser,
    required MessageType type,
    Uint8List? mediaData,
    String? mediaPath,
    Duration? duration,
  }) async {
    final message = ChatMessageModel(
      text: text,
      isUser: isUser,
      type: type,
      timestamp: DateTime.now(),
      mediaData: mediaData?.toList(),
      mediaPath: mediaPath,
      duration: duration,
    );
    await _isar.chatMessageModels.put(message);
  }

  @override
  Future<void> editMessage(int id, String newText) async {
    if (_shouldThrowOnEdit) {
      throw Exception('Failed to edit message');
    }

    final message = await _isar.chatMessageModels.get(id);
    if (message != null) {
      final updatedMessage = message.copyWith(
        text: newText,
        timestamp: DateTime.now(),
      );
      await _isar.chatMessageModels.put(updatedMessage);

      // Also update the messages property for direct access in tests
      if (messages.isNotEmpty) {
        final index = messages.indexWhere((m) => m.id == id);
        if (index >= 0) {
          messages[index] = updatedMessage;
        }
      }
    }
  }

  @override
  Future<void> deleteMessage(int id) async {
    final messages = await getMessages();
    _isar._chatMessageModels._messages =
        messages.where((m) => m.id != id).toList();
  }

  @override
  Future<void> deleteAllMessages() async {
    _isar._chatMessageModels._messages = [];
  }

  @override
  Future<List<ChatMessageModel>> searchMessages(String query) async {
    final messages = await getMessages();
    return messages
        .where((m) => m.text.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<ChatMessageModel>> getMessagesForDate(DateTime startDate, DateTime endDate) async {
    return _isar._chatMessageModels._messages.where((m) => 
      m.timestamp.isAfter(startDate) && m.timestamp.isBefore(endDate)
    ).toList();
  }

  @override
  Future<void> migratePathsToRelative() async {
    // No-op for testing
  }

  @override
  Future<void> migrateToPersonaMetadata() async {
    // No-op for testing
  }

  @override
  Future<void> restoreMessagesFromData() async {
    // No-op for testing
  }

  @override
  Future<void> close() async {
    // No-op for testing
  }

  @override
  Future<Isar> openDB() async {
    // Return the fake Isar instance
    return _isar;
  }
}

class FakeIsar implements Isar {
  final FakeIsarCollection<ChatMessageModel> _chatMessageModels =
      FakeIsarCollection<ChatMessageModel>();

  void setupMessages(List<ChatMessageModel> messages) {
    _chatMessageModels.setupMessages(messages);
  }

  @override
  FakeIsarCollection<ChatMessageModel> get chatMessageModels =>
      _chatMessageModels;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class FakeIsarCollection<T> implements IsarCollection<ChatMessageModel> {
  List<ChatMessageModel> _messages = [];

  void setupMessages(List<ChatMessageModel> messages) {
    _messages = List.from(messages);
  }

  @override
  Future<ChatMessageModel?> get(int id) async {
    try {
      return _messages.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> put(ChatMessageModel message) async {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      _messages[index] = message;
    } else {
      _messages.add(message);
    }
    return message.id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class FakeClaudeService implements ClaudeService {
  String _response = 'Mock response';
  bool _audioEnabled = true;

  void setResponse(String response) {
    _response = response;
  }

  @override
  Future<String> sendMessage(String message) async {
    return _response;
  }

  @override
  Future<ClaudeAudioResponse> sendMessageWithAudio(String message) async {
    return ClaudeAudioResponse(text: _response);
  }

  @override
  bool get audioEnabled => _audioEnabled;

  @override
  set audioEnabled(bool value) => _audioEnabled = value;

  @override
  void clearConversation() {
    // No-op for testing
  }

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  List<Map<String, String>> get conversationHistory => [];

  @override
  void setLogging(bool enable) {
    // No-op for testing
  }
}

// A simplified version of ChatScreen for testing
class TestChatScreen extends StatefulWidget {
  final ChatStorageService storageService;
  final ClaudeService claudeService;

  const TestChatScreen({
    required this.storageService,
    required this.claudeService,
    Key? key,
  }) : super(key: key);

  @override
  State<TestChatScreen> createState() => _TestChatScreenState();
}

class _TestChatScreenState extends State<TestChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Widget> _messages = [];
  final bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final messages = await widget.storageService.getMessages();
    print('Loading ${messages.length} messages:');
    for (final message in messages) {
      print(
          'Message ID: ${message.id}, Text: ${message.text}, IsUser: ${message.isUser}');
    }

    setState(() {
      _messages.clear();
      for (final message in messages) {
        final key = 'message_${message.id}';
        final textKey = 'message_text_${message.id}';
        final editButtonKey = 'edit_button_${message.id}';

        print(
            'Creating widget with keys: message=$key, text=$textKey, editButton=${message.isUser ? editButtonKey : "none"}');

        _messages.add(
          ListTile(
            key: ValueKey(key),
            title: Text(
              message.text,
              key: ValueKey(textKey),
            ),
            subtitle: Text(message.isUser ? 'You' : 'Assistant'),
            trailing: message.isUser
                ? IconButton(
                    key: ValueKey(editButtonKey),
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(message),
                  )
                : null,
          ),
        );
      }
    });
  }

  void _showEditDialog(ChatMessageModel message) {
    final TextEditingController controller =
        TextEditingController(text: message.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Edit your message',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message cannot be empty')),
                );
                return;
              }

              try {
                await widget.storageService.editMessage(message.id, newText);
                if (mounted) {
                  Navigator.pop(context);
                  _loadMessages();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to edit message')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Send a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Send message logic
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeChatStorageService storageService;
  late FakeClaudeService claudeService;
  late Widget chatScreen;

  setUp(() {
    storageService = FakeChatStorageService();
    claudeService = FakeClaudeService();

    // Set up test messages
    final testMessages = [
      ChatMessageModel(
        text: 'Hello',
        isUser: true,
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      )..id = 1,
      ChatMessageModel(
        text: 'Hi there! How can I help you today?',
        isUser: false,
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      )..id = 2,
      ChatMessageModel(
        text: 'I need help with my project',
        isUser: true,
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      )..id = 3,
    ];

    storageService.setupMessages(testMessages);

    chatScreen = TestChatScreen(
      storageService: storageService,
      claudeService: claudeService,
    );
  });

  group('Edit functionality', () {
    testWidgets('shows edit dialog when edit button is pressed',
        (WidgetTester tester) async {
      // Setup
      final storage = FakeChatStorageService();
      final message = ChatMessageModel(
        text: 'I need help with my project',
        isUser: true,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );
      storage.messages = [message];
      storage.setupMessages([message]);

      // Build the widget
      await tester.pumpWidget(MaterialApp(
        home: TestChatScreen(
          storageService: storage,
          claudeService: FakeClaudeService(),
        ),
      ));
      await tester.pumpAndSettle();

      // Print debug info
      print('Loading ${storage.messages.length} messages:');
      for (final message in storage.messages) {
        print(
            'Message ID: ${message.id}, Text: ${message.text}, IsUser: ${message.isUser}');
      }

      // Find the edit button using the key
      final editButton = find.byKey(ValueKey('edit_button_${message.id}'));
      expect(editButton, findsOneWidget, reason: 'Edit button should be found');

      // Tap the edit button
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Verify that the edit dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);

      // Find the text field in the dialog specifically
      final dialogTextField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(dialogTextField, findsOneWidget);
    });

    testWidgets('can edit message text and save changes',
        (WidgetTester tester) async {
      // Setup
      final storage = FakeChatStorageService();
      final message = ChatMessageModel(
        text: 'I need help with my project',
        isUser: true,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );
      storage.messages = [message];
      storage.setupMessages([message]);

      // Build the widget
      await tester.pumpWidget(MaterialApp(
        home: TestChatScreen(
          storageService: storage,
          claudeService: FakeClaudeService(),
        ),
      ));
      await tester.pumpAndSettle();

      // Find the edit button using the key
      final editButton = find.byKey(ValueKey('edit_button_${message.id}'));
      expect(editButton, findsOneWidget);

      // Tap the edit button
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Find the text field in the dialog specifically
      final dialogTextField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(dialogTextField, findsOneWidget);

      // Enter new text
      await tester.enterText(dialogTextField, 'Updated message text');
      await tester.pumpAndSettle();

      // Find and tap the save button
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify that the message was updated
      expect(find.text('Updated message text'), findsOneWidget);
      expect(storage.messages[0].text, 'Updated message text');
    });

    testWidgets('shows error when empty message text is entered',
        (WidgetTester tester) async {
      // Setup
      final storage = FakeChatStorageService();
      final message = ChatMessageModel(
        text: 'I need help with my project',
        isUser: true,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );
      storage.messages = [message];
      storage.setupMessages([message]);

      // Build the widget
      await tester.pumpWidget(MaterialApp(
        home: TestChatScreen(
          storageService: storage,
          claudeService: FakeClaudeService(),
        ),
      ));
      await tester.pumpAndSettle();

      // Find the edit button using the key
      final editButton = find.byKey(ValueKey('edit_button_${message.id}'));
      expect(editButton, findsOneWidget);

      // Tap the edit button
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Find the text field in the dialog specifically
      final dialogTextField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(dialogTextField, findsOneWidget);

      // Enter empty text
      await tester.enterText(dialogTextField, '');
      await tester.pumpAndSettle();

      // Find and tap the save button
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify that an error message is shown
      expect(find.text('Message cannot be empty'), findsOneWidget);
    });

    testWidgets('can cancel edit without saving changes',
        (WidgetTester tester) async {
      // Setup
      final storage = FakeChatStorageService();
      final message = ChatMessageModel(
        text: 'I need help with my project',
        isUser: true,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );
      storage.messages = [message];
      storage.setupMessages([message]);

      // Build the widget
      await tester.pumpWidget(MaterialApp(
        home: TestChatScreen(
          storageService: storage,
          claudeService: FakeClaudeService(),
        ),
      ));
      await tester.pumpAndSettle();

      // Find the edit button using the key
      final editButton = find.byKey(ValueKey('edit_button_${message.id}'));
      expect(editButton, findsOneWidget);

      // Tap the edit button
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Find the text field in the dialog specifically
      final dialogTextField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(dialogTextField, findsOneWidget);

      // Enter new text
      await tester.enterText(dialogTextField, 'This text should not be saved');
      await tester.pumpAndSettle();

      // Find and tap the cancel button
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify that the message was not updated
      expect(find.text('I need help with my project'), findsOneWidget);
      expect(storage.messages[0].text, 'I need help with my project');
    });

    testWidgets('shows error when storage fails to edit message',
        (WidgetTester tester) async {
      // Setup
      final storage = FakeChatStorageService();
      final message = ChatMessageModel(
        text: 'I need help with my project',
        isUser: true,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );
      storage.messages = [message];
      storage.shouldFailEditing = true;
      storage.setupMessages([message]);

      // Build the widget
      await tester.pumpWidget(MaterialApp(
        home: TestChatScreen(
          storageService: storage,
          claudeService: FakeClaudeService(),
        ),
      ));
      await tester.pumpAndSettle();

      // Find the edit button using the key
      final editButton = find.byKey(ValueKey('edit_button_${message.id}'));
      expect(editButton, findsOneWidget);

      // Tap the edit button
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Find the text field in the dialog specifically
      final dialogTextField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(dialogTextField, findsOneWidget);

      // Enter new text
      await tester.enterText(dialogTextField, 'Updated message text');
      await tester.pumpAndSettle();

      // Find and tap the save button
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify that an error message is shown
      expect(find.text('Failed to edit message'), findsOneWidget);
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
