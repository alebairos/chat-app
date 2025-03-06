import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/utils/logger.dart';
import 'dart:async';

void main() {
  group('Logger', () {
    late Logger logger;
    late StringBuffer logOutput;
    late ZoneSpecification spec;
    late Zone zone;

    setUp(() {
      logger = Logger();
      logOutput = StringBuffer();

      // Create a zone specification that redirects print to our StringBuffer
      spec = ZoneSpecification(
        print: (_, __, ___, String message) {
          logOutput.writeln(message);
        },
      );

      // Run tests in a custom zone to capture print output
      zone = Zone.current.fork(specification: spec);
    });

    test('general logging can be enabled and disabled', () async {
      await zone.run(() async {
        // Initially logging should be disabled
        logger.info('This should not be logged');
        expect(logOutput.toString(), isEmpty);

        // Enable logging
        logger.setLogging(true);
        logger.info('This should be logged');
        expect(
            logOutput.toString(), contains('ℹ️ [INFO] This should be logged'));

        // Disable logging
        logger.setLogging(false);
        logger.info('This should not be logged again');
        expect(logOutput.toString(),
            isNot(contains('This should not be logged again')));
      });
    });

    test('startup logging can be enabled and disabled independently', () async {
      await zone.run(() async {
        // Enable general logging but keep startup logging disabled
        logger.setLogging(true);
        logger.setStartupLogging(false);

        logger.info('Regular log message');
        logger.logStartup('Startup message that should not appear');

        expect(logOutput.toString(), contains('Regular log message'));
        expect(logOutput.toString(),
            isNot(contains('Startup message that should not appear')));

        // Now enable startup logging
        logger.setStartupLogging(true);
        logger.logStartup('Startup message that should appear');

        expect(logOutput.toString(),
            contains('🚀 [STARTUP] Startup message that should appear'));
      });
    });

    test('startup logging requires general logging to be enabled', () async {
      await zone.run(() async {
        // Disable general logging but enable startup logging
        logger.setLogging(false);
        logger.setStartupLogging(true);

        logger.logStartup('This startup message should not appear');

        expect(logOutput.toString(), isEmpty);
      });
    });

    test('different log levels work correctly', () async {
      await zone.run(() async {
        logger.setLogging(true);

        logger.info('Info message');
        logger.error('Error message');
        logger.warning('Warning message');
        logger.debug('Debug message');

        expect(logOutput.toString(), contains('ℹ️ [INFO] Info message'));
        expect(logOutput.toString(), contains('❌ [ERROR] Error message'));
        expect(logOutput.toString(), contains('⚠️ [WARNING] Warning message'));
        // Debug messages only appear in debug mode, which may vary in test environment
      });
    });
  });
}
