import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:character_ai_clone/life_plan/services/life_plan_command_handler.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/models/life_plan/dimensions.dart';

@GenerateMocks([ClaudeService])
import 'life_plan_command_handler_test.mocks.dart';

void main() {
  late LifePlanCommandHandler handler;
  late MockClaudeService mockClaudeService;

  setUp(() {
    print('\n🔄 Setting up test environment...');
    mockClaudeService = MockClaudeService();
    handler = LifePlanCommandHandler(claudeService: mockClaudeService);
    print('✓ Mock Claude service and handler initialized');
  });

  group('LifePlanCommandHandler', () {
    group('Command Validation', () {
      test('correctly identifies life plan commands', () {
        print('\n🧪 Testing life plan command identification...');
        final results = {
          '/plan': handler.isLifePlanCommand('/plan'),
          '/explore SF': handler.isLifePlanCommand('/explore SF'),
          '/help': handler.isLifePlanCommand('/help'),
        };
        print('📋 Command validation results: $results');

        expect(results['/plan'], isTrue);
        expect(results['/explore SF'], isTrue);
        expect(results['/help'], isTrue);
        print('✓ All commands correctly identified');
      });

      test('correctly identifies non-life plan commands', () {
        print('\n🧪 Testing non-life plan command identification...');
        final results = {
          'hello': handler.isLifePlanCommand('hello'),
          '/invalid': handler.isLifePlanCommand('/invalid'),
          '': handler.isLifePlanCommand(''),
        };
        print('📋 Non-command validation results: $results');

        expect(results['hello'], isFalse);
        expect(results['/invalid'], isFalse);
        expect(results[''], isFalse);
        print('✓ All non-commands correctly identified');
      });
    });

    group('Plan Command', () {
      test('handles plan command', () async {
        print('\n🧪 Testing /plan command handling...');
        final response = await handler.handleCommand('/plan');
        print('📤 Response received: ${response.substring(0, 50)}...');

        expect(response, contains('*adjusts chronometer* `⚔️`'));
        expect(response, contains('Salve, time wanderer!'));
        expect(response, contains('Choose a dimension:'));
        expect(response, contains('SF: Physical Health'));
        expect(response, contains('SM: Mental Health'));
        expect(response, contains('R: Relationships'));

        print('🔍 Verifying Claude service was not called...');
        verifyNever(mockClaudeService.sendMessage(any));
        print('✓ Plan command test completed successfully');
      });
    });

    group('Help Command', () {
      test('handles help command', () async {
        print('\n🧪 Testing /help command handling...');
        final response = await handler.handleCommand('/help');
        print('📤 Response received: ${response.substring(0, 50)}...');

        expect(response, contains('*unfurls ancient scroll* `📜`'));
        expect(response, contains('/plan'));
        expect(response, contains('/explore SF'));
        expect(response, contains('/explore SM'));
        expect(response, contains('/explore R'));

        print('🔍 Verifying Claude service was not called...');
        verifyNever(mockClaudeService.sendMessage(any));
        print('✓ Help command test completed successfully');
      });
    });

    group('Explore Command', () {
      test('handles explore command without dimension', () async {
        print('\n🧪 Testing /explore command without dimension...');
        final response = await handler.handleCommand('/explore');
        print('📤 Response received: ${response.substring(0, 50)}...');

        expect(response, contains('*adjusts spectacles* `🧐`'));
        expect(
            response, contains('Which dimension would you like to explore?'));
        expect(response, contains('SF for Physical'));
        expect(response, contains('SM for Mental'));
        expect(response, contains('R for Relationships'));

        print('🔍 Verifying Claude service was not called...');
        verifyNever(mockClaudeService.sendMessage(any));
        print('✓ Explore without dimension test completed successfully');
      });

      test('handles explore command with physical dimension', () async {
        print('\n🧪 Testing /explore ${Dimensions.physical.code} command...');
        when(mockClaudeService.sendMessage(any)).thenAnswer(
            (_) async => 'Claude\'s response for physical dimension');
        print('✓ Mock Claude service configured');

        final response =
            await handler.handleCommand('/explore ${Dimensions.physical.code}');
        print('📤 Response received: $response');

        expect(response, contains('Claude\'s response for physical dimension'));

        print('🔍 Verifying Claude service call...');
        verify(mockClaudeService
                .sendMessage(argThat(contains('physical health improvement'))))
            .called(1);
        print('✓ Physical dimension explore test completed successfully');
      });

      test('handles explore command with mental dimension', () async {
        print('\n🧪 Testing /explore ${Dimensions.mental.code} command...');
        when(mockClaudeService.sendMessage(any))
            .thenAnswer((_) async => 'Claude\'s response for mental dimension');
        print('✓ Mock Claude service configured');

        final response =
            await handler.handleCommand('/explore ${Dimensions.mental.code}');
        print('📤 Response received: $response');

        expect(response, contains('Claude\'s response for mental dimension'));

        print('🔍 Verifying Claude service call...');
        verify(mockClaudeService
                .sendMessage(argThat(contains('mental wellbeing'))))
            .called(1);
        print('✓ Mental dimension explore test completed successfully');
      });

      test('handles explore command with relationships dimension', () async {
        print(
            '\n🧪 Testing /explore ${Dimensions.relationships.code} command...');
        when(mockClaudeService.sendMessage(any)).thenAnswer(
            (_) async => 'Claude\'s response for relationships dimension');
        print('✓ Mock Claude service configured');

        final response = await handler
            .handleCommand('/explore ${Dimensions.relationships.code}');
        print('📤 Response received: $response');

        expect(response,
            contains('Claude\'s response for relationships dimension'));

        print('🔍 Verifying Claude service call...');
        verify(mockClaudeService
                .sendMessage(argThat(contains('stronger relationships'))))
            .called(1);
        print('✓ Relationships dimension explore test completed successfully');
      });

      test('handles explore command with invalid dimension', () async {
        print('\n🧪 Testing /explore with invalid dimension...');
        final response = await handler.handleCommand('/explore INVALID');
        print('📤 Response received: ${response.substring(0, 50)}...');

        expect(response, contains('*adjusts spectacles* `🧐`'));
        expect(
            response, contains('Which dimension would you like to explore?'));

        print('🔍 Verifying Claude service was not called...');
        verifyNever(mockClaudeService.sendMessage(any));
        print('✓ Invalid dimension test completed successfully');
      });
    });

    group('Planning Mode', () {
      test('accepts dimension codes after /plan command', () async {
        print('\n🧪 Testing dimension code handling in planning mode...');

        // Start planning mode
        await handler.handleCommand('/plan');

        // Test dimension code handling
        when(mockClaudeService.sendMessage(any)).thenAnswer(
            (_) async => 'Claude\'s response for physical dimension');

        final response = await handler.handleCommand(Dimensions.physical.code);
        print('📤 Response received: $response');

        expect(response, contains('Claude\'s response for physical dimension'));
        verify(mockClaudeService.sendMessage(any)).called(1);
        print('✓ Dimension code handling test completed successfully');
      });

      test('rejects dimension codes outside planning mode', () async {
        print('\n🧪 Testing dimension code handling outside planning mode...');

        final response = await handler.handleCommand(Dimensions.physical.code);
        print('📤 Response received: ${response.substring(0, 50)}...');

        expect(response, contains('*unfurls ancient scroll* `📜`'));
        expect(response, contains('/plan'));
        verifyNever(mockClaudeService.sendMessage(any));
        print('✓ Outside planning mode test completed successfully');
      });

      test('handles invalid dimension codes in planning mode', () async {
        print('\n🧪 Testing invalid dimension code handling...');

        // Start planning mode
        await handler.handleCommand('/plan');

        final response = await handler.handleCommand('INVALID');
        print('📤 Response received: ${response.substring(0, 50)}...');

        expect(response, contains('*adjusts spectacles* `🧐`'));
        expect(response, contains('Invalid dimension code'));
        verifyNever(mockClaudeService.sendMessage(any));
        print('✓ Invalid dimension code test completed successfully');
      });

      test('exits planning mode after successful dimension exploration',
          () async {
        print('\n🧪 Testing planning mode exit after exploration...');

        // Start planning mode
        await handler.handleCommand('/plan');

        when(mockClaudeService.sendMessage(any))
            .thenAnswer((_) async => 'Claude\'s response');

        // Explore a dimension
        await handler.handleCommand('SF');

        // Try another dimension code
        final response = await handler.handleCommand('SM');
        print('📤 Response received: ${response.substring(0, 50)}...');

        expect(response, contains('*unfurls ancient scroll* `📜`'));
        verify(mockClaudeService.sendMessage(any)).called(1);
        print('✓ Planning mode exit test completed successfully');
      });
    });

    group('Error Handling', () {
      test('handles Claude service errors gracefully', () async {
        print('\n🧪 Testing Claude service error handling...');
        when(mockClaudeService.sendMessage(any))
            .thenThrow(Exception('Claude service error'));
        print('✓ Mock Claude service configured to throw error');

        final response = await handler.handleCommand('/explore SF');
        print('📤 Response received: $response');

        expect(response, contains('*adjusts spectacles* `🧐`'));
        expect(response, contains('Error getting response from Claude'));

        print('🔍 Verifying Claude service call...');
        verify(mockClaudeService.sendMessage(any)).called(1);
        print('✓ Error handling test completed successfully');
      });

      test('handles unknown commands', () async {
        print('\n🧪 Testing unknown command handling...');
        final response = await handler.handleCommand('/unknown');
        print('📤 Response received: ${response.substring(0, 50)}...');

        expect(response, contains('*unfurls ancient scroll* `📜`'));
        expect(response, contains('/plan'));
        expect(response, contains('/explore SF'));

        print('🔍 Verifying Claude service was not called...');
        verifyNever(mockClaudeService.sendMessage(any));
        print('✓ Unknown command test completed successfully');
      });
    });
  });
}
