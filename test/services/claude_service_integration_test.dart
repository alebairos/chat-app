import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/system_mcp_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../mock_config_loader.dart';
import 'claude_service_integration_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  print('\n🚀 Starting Claude Service Integration Tests');

  late ClaudeService claudeService;
  late SystemMCPService mcpService;
  late MockClient mockClient;

  setUpAll(() async {
    print('\n📝 Setting up test environment...');

    // Load environment variables
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_key
      OPENAI_API_KEY=test_key
    ''');
    print('✓ Environment variables loaded');

    // Initialize services
    mcpService = SystemMCPService();
    mcpService.setLogging(false); // Disable logging for tests
    print('✓ System MCP Service initialized');
  });

  setUp(() {
    print('\n🔄 Setting up test case...');
    mockClient = MockClient();

    // Configure mock client with default response
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
      encoding: anyNamed('encoding'),
    )).thenAnswer((_) async => http.Response(
          json.encode({
            'content': [
              {'text': 'This is a test response from Claude.'}
            ]
          }),
          200,
        ));
    print('✓ Mock client configured with default response');

    claudeService = ClaudeService(
      client: mockClient,
      systemMCP: mcpService,
      configLoader: MockConfigLoader(),
    );
    print('✓ Claude Service initialized with mock dependencies');
  });

  group('Claude Service System Integration', () {
    test('successfully gets current time via MCP', () async {
      print('\n🧪 Testing current time retrieval...');

      final command = json.encode({'action': 'get_current_time'});
      print('📤 Sending command: $command');

      final response = await claudeService.sendMessage(command);
      print('📥 Received response: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      expect(decoded['status'], equals('success'));
      expect(decoded['data'], isA<Map<String, dynamic>>());

      // Verify the response contains valid time data
      final timeData = decoded['data'] as Map<String, dynamic>;
      expect(timeData['timestamp'], isA<String>());
      expect(timeData['hour'], isA<int>());
      expect(timeData['minute'], isA<int>());
      expect(timeData['dayOfWeek'], isA<String>());
      expect(timeData['timeOfDay'], isA<String>());

      print('✓ Test completed successfully');
    });

    test('handles unknown MCP commands gracefully', () async {
      print('\n🧪 Testing unknown command handling...');

      final command = json.encode({'action': 'unknown_function'});
      print('📤 Sending command: $command');

      final response = await claudeService.sendMessage(command);
      print('📥 Received response: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      expect(decoded['status'], equals('error'));
      expect(decoded['message'], contains('Unknown action'));

      print('✓ Test completed successfully');
    });

    test('processes normal chat messages', () async {
      print('\n🧪 Testing normal message processing...');

      final message = 'Hello, how are you?';
      print('📤 Sending message: $message');

      final response = await claudeService.sendMessage(message);
      print('📥 Received response: $response');

      expect(response, isA<String>());
      expect(response, isNotEmpty);
      expect(response, contains('test response'));

      print('✓ Test completed successfully');
    });
  });
}
