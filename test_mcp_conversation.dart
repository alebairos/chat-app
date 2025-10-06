import 'dart:convert';
import 'package:ai_personas_app/services/system_mcp_service.dart';

Future<void> main() async {
  print('🔍 Testing MCP conversation context...');

  try {
    final mcpService = SystemMCPService();

    // Get last 10 messages via MCP
    final response = await mcpService.processCommand(
        '{"action": "get_message_stats", "limit": 10, "full_text": true}');
    final data = json.decode(response);

    if (data['status'] == 'success') {
      final messages = data['data']['messages'] as List;

      print('\n📝 Last ${messages.length} messages:');
      print('=' * 60);

      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final speaker = msg['is_user'] ? 'USER' : 'ASSISTANT';
        final timestamp = msg['timestamp'];
        final text = msg['text'];

        print('${i + 1}. [$timestamp] $speaker:');
        print('   "$text"');
        print('');
      }
    } else {
      print('❌ Error: ${data['message']}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
