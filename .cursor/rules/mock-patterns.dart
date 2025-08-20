// Mock patterns for testing when simple approaches aren't sufficient
// AVOID MOCKS when possible - use simple, direct testing approaches first
// Only use mocking after simpler approaches are proven successful

import 'package:mocktail/mocktail.dart';

// Example service interfaces for mocking
abstract class ExampleService {
  Future<String> fetchData(String id);
  Stream<bool> get statusStream;
  void dispose();
}

// Use mocktail instead of mockito - no code generation needed
class MockExampleService extends Mock implements ExampleService {}

/// Mock usage patterns for testing (use sparingly)
class MockPatterns {
  /// Basic mock setup pattern using mocktail
  static MockExampleService createMockService() {
    final mock = MockExampleService();

    // Setup default behaviors with mocktail
    when(() => mock.fetchData(any())).thenAnswer((_) async => 'mock-data');
    when(() => mock.statusStream).thenAnswer((_) => Stream.value(true));

    return mock;
  }

  /// Mock with specific return values
  static MockExampleService createMockServiceWithData(String data) {
    final mock = MockExampleService();

    when(() => mock.fetchData(any())).thenAnswer((_) async => data);

    return mock;
  }

  /// Mock that throws errors
  static MockExampleService createMockServiceWithError() {
    final mock = MockExampleService();

    when(() => mock.fetchData(any())).thenThrow(Exception('Mock error'));

    return mock;
  }

  /// Verify mock interactions using mocktail
  static void verifyMockInteractions(
      MockExampleService mock, String expectedId) {
    verify(() => mock.fetchData(expectedId)).called(1);
    verifyNoMoreInteractions(mock);
  }
}

/// Example test using mocks
void exampleMockTest() {
  // This is an example - actual tests should be in test files
  /*
  group('Service Tests with Mocks', () {
    late MockExampleService mockService;
    
    setUp(() {
      mockService = MockPatterns.createMockService();
    });
    
    test('should use mock service correctly', () async {
      // Arrange
      const testId = 'test-123';
      
      // Act
      final result = await mockService.fetchData(testId);
      
      // Assert
      expect(result, equals('mock-data'));
      MockPatterns.verifyMockInteractions(mockService, testId);
    });
  });
  */
}
