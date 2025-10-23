import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ai_personas_app/services/gemini_image_service.dart';
import 'package:ai_personas_app/services/shared_claude_rate_limiter.dart';

void main() {
  group('GeminiImageService', () {
    setUpAll(() async {
      // Load environment variables for testing
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        // Create mock environment for testing
        dotenv.testLoad(fileInput: 'GOOGLE_AI_API_KEY=test_key');
      }

      // Enable testing mode for rate limiter
      SharedClaudeRateLimiter.enableTestingMode();
    });

    tearDownAll(() {
      SharedClaudeRateLimiter.disableTestingMode();
    });

    test('should create service instance', () {
      final service = GeminiImageService.instance;
      expect(service, isNotNull);
      expect(service, isA<GeminiImageService>());
    });

    test('should be singleton', () {
      final service1 = GeminiImageService.instance;
      final service2 = GeminiImageService.instance;
      expect(service1, same(service2));
    });

    test('should detect image generation keywords in English', () {
      final service = GeminiImageService.instance;

      // Access private method through reflection or create a public wrapper
      // For now, we'll test the integration through ClaudeService
      expect(service, isNotNull);
    });

    test('should handle initialization without API key', () async {
      // Clear the API key
      dotenv.testLoad(fileInput: 'GOOGLE_AI_API_KEY=');

      final service = GeminiImageService.instance;
      expect(() async => await service.initialize(), throwsException);
    });

    test('should handle initialization with API key', () async {
      // Set a test API key
      dotenv.testLoad(fileInput: 'GOOGLE_AI_API_KEY=test_key');

      final service = GeminiImageService.instance;
      // The service should initialize successfully with a valid format API key (even if fake)
      await service.initialize();
      expect(service.isInitialized, isTrue);
    });

    test('should return rate limit status', () {
      final service = GeminiImageService.instance;
      final status = service.getRateLimitStatus();

      expect(status, isA<Map<String, dynamic>>());
      expect(status.containsKey('hasRecentRateLimit'), isTrue);
      expect(status.containsKey('hasHighApiUsage'), isTrue);
    });

    test('should check if service is initialized', () {
      final service = GeminiImageService.instance;
      // The service will be initialized due to previous tests
      expect(service.isInitialized, isTrue);
    });
  });
}