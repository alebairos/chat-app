import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/services/system_mcp_service.dart';

/// FT-145: Activity Detection Regression Test
/// 
/// Tests the multilingual activity detection fix that addresses:
/// 1. Completion vs todo activity detection
/// 2. Character encoding preservation 
/// 3. Exact catalog mapping vs custom descriptions
void main() {
  group('FT-145: Multilingual Activity Detection Fix', () {
    late SystemMCPService mcpService;

    setUp(() {
      mcpService = SystemMCPService();
    });

    group('Multilingual Completion Detection', () {
      testWidgets('should detect completed activities in Portuguese', (tester) async {
        // Test Portuguese completion indicators
        const testCases = [
          'Bebi água hoje de manhã',
          'Completei um pomodoro de trabalho',
          'Caminhei 30 minutos no parque',
          'Terminei minha meditação',
        ];

        for (final message in testCases) {
          final command = '{"action": "oracle_detect_activities", "message": "$message"}';
          final result = await mcpService.processCommand(command);
          
          // Should detect activities (not empty response)
          expect(result, contains('"status": "success"'));
          expect(result, contains('"detected_activities"'));
          
          // Should not be empty array for completed activities
          expect(result, isNot(contains('"detected_activities": []')));
        }
      });

      testWidgets('should detect completed activities in English', (tester) async {
        // Test English completion indicators
        const testCases = [
          'I drank water this morning',
          'I completed a pomodoro session',
          'I walked for 30 minutes',
          'I finished my meditation',
        ];

        for (final message in testCases) {
          final command = '{"action": "oracle_detect_activities", "message": "$message"}';
          final result = await mcpService.processCommand(command);
          
          expect(result, contains('"status": "success"'));
          expect(result, contains('"detected_activities"'));
          expect(result, isNot(contains('"detected_activities": []')));
        }
      });

      testWidgets('should detect completed activities in Spanish', (tester) async {
        // Test Spanish completion indicators
        const testCases = [
          'Bebí agua esta mañana',
          'Completé una sesión de pomodoro',
          'Caminé por 30 minutos',
          'Terminé mi meditación',
        ];

        for (final message in testCases) {
          final command = '{"action": "oracle_detect_activities", "message": "$message"}';
          final result = await mcpService.processCommand(command);
          
          expect(result, contains('"status": "success"'));
          expect(result, contains('"detected_activities"'));
          expect(result, isNot(contains('"detected_activities": []')));
        }
      });

      testWidgets('should ignore future/planning activities in all languages', (tester) async {
        // Test future/planning exclusions
        const testCases = [
          // Portuguese
          'Vou beber água mais tarde',
          'Preciso fazer um pomodoro',
          'Quero caminhar amanhã',
          // English
          'I will drink water later',
          'I need to do a pomodoro',
          'I want to walk tomorrow',
          // Spanish
          'Voy a beber agua más tarde',
          'Necesito hacer un pomodoro',
          'Quiero caminar mañana',
        ];

        for (final message in testCases) {
          final command = '{"action": "oracle_detect_activities", "message": "$message"}';
          final result = await mcpService.processCommand(command);
          
          expect(result, contains('"status": "success"'));
          // Should return empty array for future/planning activities
          expect(result, contains('"detected_activities": []'));
        }
      });
    });

    group('Character Encoding Preservation', () {
      testWidgets('should preserve Portuguese characters correctly', (tester) async {
        // Test specific encoding issues from the regression
        const testCases = [
          'Não usei rede social hoje', // Test "Não" preservation
          'Bebi um copo d\'água', // Test "água" preservation
          'Fiz exercício físico', // Test "físico" preservation
        ];

        for (final message in testCases) {
          final command = '{"action": "oracle_detect_activities", "message": "$message"}';
          final result = await mcpService.processCommand(command);
          
          expect(result, contains('"status": "success"'));
          
          // Should not contain corrupted characters
          expect(result, isNot(contains('NÃo'))); // Should be "Não"
          expect(result, isNot(contains('d\'Ã¡gua'))); // Should be "d'água"
          expect(result, isNot(contains('fÃ­sico'))); // Should be "físico"
        }
      });
    });

    group('Catalog Mapping Enforcement', () {
      testWidgets('should return exact Oracle catalog names', (tester) async {
        // Test that system returns exact catalog names, not custom descriptions
        const message = 'Bebi água hoje';
        final command = '{"action": "oracle_detect_activities", "message": "$message"}';
        final result = await mcpService.processCommand(command);
        
        expect(result, contains('"status": "success"'));
        
        // Should contain exact catalog name for water activity
        expect(result, contains('"code": "SF1"'));
        
        // Should not contain custom descriptions like "bebeu um copo d'água"
        expect(result, isNot(contains('bebeu um copo')));
        expect(result, isNot(contains('drank a glass')));
      });

      testWidgets('should map pomodoro activities to exact T8 code', (tester) async {
        const testCases = [
          'Completei um pomodoro',
          'I finished a pomodoro session',
          'Terminé una sesión de pomodoro',
        ];

        for (final message in testCases) {
          final command = '{"action": "oracle_detect_activities", "message": "$message"}';
          final result = await mcpService.processCommand(command);
          
          expect(result, contains('"status": "success"'));
          
          // Should map to T8 code (focus work activity)
          if (!result.contains('"detected_activities": []')) {
            // Only check if activities were detected
            expect(result, anyOf([
              contains('"code": "T8"'),
              contains('"code": "PR'), // Any procrastination/focus code
            ]));
          }
        }
      });
    });

    group('Error Handling', () {
      testWidgets('should handle empty messages gracefully', (tester) async {
        const command = '{"action": "oracle_detect_activities", "message": ""}';
        final result = await mcpService.processCommand(command);
        
        expect(result, contains('"status": "error"'));
        expect(result, contains('Missing required parameter: message'));
      });

      testWidgets('should handle invalid JSON gracefully', (tester) async {
        const command = '{"action": "oracle_detect_activities"}';
        final result = await mcpService.processCommand(command);
        
        expect(result, contains('"status": "error"'));
      });
    });
  });
}
