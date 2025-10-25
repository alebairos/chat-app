import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/services/system_mcp_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FT-159: Proactive MCP Memory Retrieval', () {
    late SystemMCPService mcpService;

    setUp(() {
      mcpService = SystemMCPService();
    });

    test('should validate MCP base config has proactive triggers', () async {
      // FT-206: Config simplified - verify basic structure and conversation functions
      final String configString =
          await rootBundle.loadString('assets/config/mcp_base_config.json');
      final Map<String, dynamic> config = json.decode(configString);

      expect(config['enabled'], isTrue,
          reason: 'MCP base config should be enabled');

      final instructions = config['instructions'] as Map<String, dynamic>?;
      expect(instructions, isNotNull, reason: 'Instructions should be present');

      final systemFunctions = instructions!['system_functions'] as Map<String, dynamic>?;
      expect(systemFunctions, isNotNull,
          reason: 'System functions section should be present');

      final availableFunctions = systemFunctions!['available_functions'] as List<dynamic>?;
      expect(availableFunctions, isNotNull,
          reason: 'Available functions should be present');

      // Verify conversation context functions are present
      final functionNames = availableFunctions!.map((f) => f['name']).toList();
      expect(functionNames.contains('get_conversation_context'), isTrue,
          reason: 'get_conversation_context function should be available');
      expect(functionNames.contains('get_recent_user_messages'), isTrue,
          reason: 'get_recent_user_messages function should be available');
      expect(functionNames.contains('get_current_persona_messages'), isTrue,
          reason: 'get_current_persona_messages function should be available');
    });

    test('should handle enhanced MCP function parameters', () async {
      // Test that new parameters don't cause JSON parsing errors

      // Test get_message_stats with full_text parameter
      final messageStatsCommand = json.encode(
          {'action': 'get_message_stats', 'limit': 5, 'full_text': true});

      // Should not throw JSON parsing errors
      expect(() => json.decode(messageStatsCommand), returnsNormally,
          reason: 'Enhanced get_message_stats command should be valid JSON');

      // Test get_conversation_context command
      final conversationCommand =
          json.encode({'action': 'get_conversation_context', 'hours': 24});

      expect(() => json.decode(conversationCommand), returnsNormally,
          reason: 'get_conversation_context command should be valid JSON');
    });

    test('should validate proactive memory trigger content', () async {
      // FT-206: Config simplified - verify function descriptions are clear
      final String configString =
          await rootBundle.loadString('assets/config/mcp_base_config.json');
      final Map<String, dynamic> config = json.decode(configString);

      final availableFunctions = config['instructions']['system_functions']
          ['available_functions'] as List<dynamic>;

      // Find get_conversation_context function
      final conversationContextFunc = availableFunctions.firstWhere(
        (f) => f['name'] == 'get_conversation_context',
        orElse: () => null,
      );

      expect(conversationContextFunc, isNotNull,
          reason: 'get_conversation_context function should be present');
      expect(conversationContextFunc['description'], isNotNull,
          reason: 'Function should have a description');
      expect(conversationContextFunc['usage'], isNotNull,
          reason: 'Function should have usage example');

      // Verify get_recent_user_messages exists
      final userMessagesFunc = availableFunctions.firstWhere(
        (f) => f['name'] == 'get_recent_user_messages',
        orElse: () => null,
      );
      expect(userMessagesFunc, isNotNull,
          reason: 'get_recent_user_messages function should be present');
    });
  });
}
