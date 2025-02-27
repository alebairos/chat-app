import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/utils/logger.dart';
import 'package:character_ai_clone/services/life_plan_service.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Mock implementation of main function logic
Future<void> mockMainStartup() async {
  // Initialize logger with appropriate settings
  final logger = Logger();

  // Enable general logging but disable startup logging by default
  // This will prevent logging all past chat history when the app starts
  logger.setLogging(true);
  logger.setStartupLogging(false);

  logger.info('Starting application');

  await dotenv.load(fileName: '.env').catchError((_) {
    // Ignore .env file loading errors in tests
    return null;
  });

  // Initialize services with logging settings
  final lifePlanService = LifePlanService();
  lifePlanService.setLogging(true);
  lifePlanService.setStartupLogging(false);

  // Initialize Claude service
  final claudeService = ClaudeService();
  claudeService.setLogging(true);

  // Log some additional information
  logger.info('Application initialized');
  logger.logStartup('This startup message should not appear');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Main Function Startup Logging', () {
    late StringBuffer logOutput;
    late ZoneSpecification spec;
    late Zone zone;

    setUp(() {
      logOutput = StringBuffer();

      // Create a zone specification that redirects print to our StringBuffer
      spec = ZoneSpecification(
        print: (_, __, ___, String message) {
          logOutput.writeln(message);
        },
      );

      // Run tests in a custom zone to capture print output
      zone = Zone.current.fork(specification: spec);

      // Load environment variables for testing
      dotenv.testLoad(fileInput: '''
        ANTHROPIC_API_KEY=test_key
        OPENAI_API_KEY=test_key
      ''');
    });

    test('main function startup logging behaves as expected', () async {
      await zone.run(() async {
        // Run the mock main startup function
        await mockMainStartup();

        // Verify regular logs appear
        expect(
            logOutput.toString(), contains('ℹ️ [INFO] Starting application'));
        expect(logOutput.toString(),
            contains('ℹ️ [INFO] Application initialized'));

        // Verify startup logs don't appear when disabled
        expect(
            logOutput.toString(),
            isNot(contains(
                '🚀 [STARTUP] This startup message should not appear')));
      });
    });

    test('main function with startup logging enabled', () async {
      await zone.run(() async {
        // Initialize logger with startup logging enabled
        final logger = Logger();
        logger.setLogging(true);
        logger.setStartupLogging(true);

        logger.info('Starting application');
        logger.logStartup('Application startup initiated');

        // Initialize services with logging settings
        final lifePlanService = LifePlanService();
        lifePlanService.setLogging(true);
        lifePlanService.setStartupLogging(true);

        // Verify both regular and startup logs appear
        expect(
            logOutput.toString(), contains('ℹ️ [INFO] Starting application'));
        expect(logOutput.toString(),
            contains('🚀 [STARTUP] Application startup initiated'));
      });
    });
  });
}
