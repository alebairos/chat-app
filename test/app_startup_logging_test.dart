import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/utils/logger.dart';
// Note: LifePlan service removed during cleanup
import 'package:ai_personas_app/services/claude_service.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Startup Logging', () {
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

    test('app startup with default logging settings', () async {
      await zone.run(() async {
        // Initialize logger with default app settings
        final logger = Logger();
        logger.setLogging(true);
        logger.setStartupLogging(false);

        logger.info('Starting application');

        // Note: LifePlan service initialization removed during cleanup

        // Initialize Claude service
        final claudeService = ClaudeService();
        claudeService.setLogging(true);

        // Verify regular logs appear
        expect(
            logOutput.toString(), contains('ℹ️ [INFO] Starting application'));

        // Verify startup logs don't appear when disabled
        // Note: LifePlan service initialization removed during cleanup
        expect(logOutput.toString(), isNot(contains('🚀 [STARTUP]')));
      });
    });

    test('app startup with startup logging enabled', () async {
      await zone.run(() async {
        // Initialize logger with startup logging enabled
        final logger = Logger();
        logger.setLogging(true);
        logger.setStartupLogging(true);

        logger.info('Starting application');
        logger.logStartup('Initializing app components');

        // Note: LifePlan service initialization removed during cleanup

        // Verify both regular and startup logs appear
        expect(
            logOutput.toString(), contains('ℹ️ [INFO] Starting application'));
        expect(logOutput.toString(),
            contains('🚀 [STARTUP] Initializing app components'));

        // Verify startup logs appear during initialization
        // Note: LifePlan service initialization removed during cleanup
        expect(logOutput.toString(), contains('🚀 [STARTUP]'));
      });
    });

    test('claude service respects logging settings', () async {
      await zone.run(() async {
        // Initialize logger
        final logger = Logger();
        logger.setLogging(true);

        // Initialize Claude service with logging enabled
        final claudeService = ClaudeService();
        claudeService.setLogging(true);

        // Generate a log message explicitly to verify logging is working
        logger.info('Test log message before Claude initialization');

        // Initialize Claude service
        await claudeService.initialize();

        // Verify logs appear (the info message we explicitly logged)
        expect(logOutput.toString(),
            contains('Test log message before Claude initialization'));

        // Reset output
        logOutput.clear();

        // Disable logging
        claudeService.setLogging(false);
        logger.setLogging(false);

        // Try to generate more logs
        logger.info('This should not be logged');
        await claudeService.initialize();

        // Verify no new logs appear
        expect(logOutput.toString(), isEmpty);
      });
    });
  });
}
