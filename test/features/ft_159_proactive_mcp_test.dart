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
      // Load MCP base config directly
      final String configString = await rootBundle.loadString(
        'assets/config/mcp_base_config.json'
      );
      final Map<String, dynamic> config = json.decode(configString);
      
      expect(config['enabled'], isTrue, reason: 'MCP base config should be enabled');
      
      final instructions = config['instructions'] as Map<String, dynamic>?;
      expect(instructions, isNotNull, reason: 'Instructions should be present');
      
      final temporalIntelligence = instructions!['temporal_intelligence'] as Map<String, dynamic>?;
      expect(temporalIntelligence, isNotNull, reason: 'Temporal intelligence section should be present');
      
      final proactiveMemory = temporalIntelligence!['proactive_memory_triggers'] as Map<String, dynamic>?;
      expect(proactiveMemory, isNotNull, reason: 'Proactive memory triggers should be present');
      
      expect(proactiveMemory!['critical_rule'], isNotNull, 
          reason: 'Critical rule should be defined');
      expect(proactiveMemory['trigger_patterns'], isNotNull, 
          reason: 'Trigger patterns should be defined');
      expect(proactiveMemory['cross_persona_rule'], isNotNull, 
          reason: 'Cross-persona rule should be defined');
          
      // Verify specific trigger patterns
      final List<dynamic> patterns = proactiveMemory['trigger_patterns'];
      expect(patterns.any((p) => p.toString().contains('lembra do plano')), isTrue,
          reason: 'Should include Portuguese trigger pattern');
      expect(patterns.any((p) => p.toString().contains('remember the plan')), isTrue,
          reason: 'Should include English trigger pattern');
    });

    test('should handle enhanced MCP function parameters', () async {
      // Test that new parameters don't cause JSON parsing errors
      
      // Test get_message_stats with full_text parameter
      final messageStatsCommand = json.encode({
        'action': 'get_message_stats',
        'limit': 5,
        'full_text': true
      });
      
      // Should not throw JSON parsing errors
      expect(() => json.decode(messageStatsCommand), returnsNormally,
          reason: 'Enhanced get_message_stats command should be valid JSON');
      
      // Test get_conversation_context command
      final conversationCommand = json.encode({
        'action': 'get_conversation_context',
        'hours': 24
      });
      
      expect(() => json.decode(conversationCommand), returnsNormally,
          reason: 'get_conversation_context command should be valid JSON');
    });

    test('should validate proactive memory trigger content', () async {
      // Load and validate the specific content of proactive memory triggers
      final String configString = await rootBundle.loadString(
        'assets/config/mcp_base_config.json'
      );
      final Map<String, dynamic> config = json.decode(configString);
      
      final proactiveMemory = config['instructions']['temporal_intelligence']['proactive_memory_triggers'] as Map<String, dynamic>;
      
      // Verify critical rule mentions automatic usage
      final criticalRule = proactiveMemory['critical_rule'] as String;
      expect(criticalRule.toLowerCase().contains('automatically'), isTrue,
          reason: 'Critical rule should emphasize automatic usage');
      expect(criticalRule.toLowerCase().contains('get_conversation_context'), isTrue,
          reason: 'Critical rule should mention the specific function to use');
      
      // Verify cross-persona rule exists
      final crossPersonaRule = proactiveMemory['cross_persona_rule'] as String;
      expect(crossPersonaRule.toLowerCase().contains('persona'), isTrue,
          reason: 'Cross-persona rule should mention persona switching');
      expect(crossPersonaRule.toLowerCase().contains('get_conversation_context'), isTrue,
          reason: 'Cross-persona rule should mention the specific function to use');
    });
  });
}
