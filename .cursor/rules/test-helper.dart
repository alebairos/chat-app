// Test helper utilities for this Flutter project
// Common test setup and utility functions

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Common test utilities and helpers
class TestHelper {
  /// Creates a basic MaterialApp wrapper for widget testing
  static Widget createTestApp({required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Pumps and settles a widget with common setup
  static Future<void> pumpWidget(
    WidgetTester tester,
    Widget widget, {
    Duration? duration,
  }) async {
    await tester.pumpWidget(createTestApp(child: widget));
    await tester.pumpAndSettle(duration);
  }

  /// Common finder patterns
  static Finder findByText(String text) => find.text(text);
  static Finder findByKey(Key key) => find.byKey(key);
  static Finder findByType<T extends Widget>() => find.byType(T);

  /// Tap and settle helper
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder, {
    Duration? duration,
  }) async {
    await tester.tap(finder);
    await tester.pumpAndSettle(duration);
  }

  /// Enter text and settle helper
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration? duration,
  }) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle(duration);
  }

  /// Wait for a condition to be true
  static Future<void> waitFor(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (!condition() && stopwatch.elapsed < timeout) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    if (!condition()) {
      throw Exception('Condition not met within timeout');
    }
  }
}

/// Test data builders for common scenarios
class TestDataBuilder {
  /// Creates test chat message data
  static Map<String, dynamic> chatMessage({
    String? sessionId,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? personaKey,
  }) {
    return {
      'sessionId': sessionId ?? 'test-session',
      'content': content ?? 'Test message',
      'isUser': isUser ?? false,
      'timestamp': timestamp ?? DateTime.now(),
      'personaKey': personaKey,
    };
  }

  /// Creates test persona configuration
  static Map<String, dynamic> personaConfig({
    String? key,
    String? displayName,
    String? description,
  }) {
    return {
      'key': key ?? 'test-persona',
      'displayName': displayName ?? 'Test Persona',
      'description': description ?? 'A test persona for testing',
    };
  }
}

