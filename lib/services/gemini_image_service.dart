import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import 'shared_claude_rate_limiter.dart';

class GeminiImageService {
  static GeminiImageService? _instance;
  static GeminiImageService get instance => _instance ??= GeminiImageService._();

  GeminiImageService._();

  String? _apiKey;
  String? _projectId;
  String? _location;
  String? _accessToken;
  bool _isInitialized = false;

  /// Initialize the service with API credentials
  Future<void> initialize() async {
    try {
      Logger().log('Initializing Vertex AI Imagen service...');

      // Check for Vertex AI credentials first (preferred for production)
      final projectId = dotenv.env['GOOGLE_CLOUD_PROJECT'];
      final location = dotenv.env['GOOGLE_CLOUD_LOCATION'] ?? 'us-central1';
      final accessToken = dotenv.env['GOOGLE_CLOUD_ACCESS_TOKEN'];

      // Fallback to Google AI Studio API key
      final apiKey = dotenv.env['GOOGLE_AI_API_KEY'];

      bool hasVertexAI = projectId != null && projectId.isNotEmpty &&
                        accessToken != null && accessToken.isNotEmpty;
      bool hasApiKey = apiKey != null && apiKey.isNotEmpty;

      if (hasVertexAI) {
        Logger().log('Using Vertex AI credentials for Imagen API');
        _projectId = projectId;
        _location = location;
        _accessToken = accessToken;
        _isInitialized = true;
        Logger().log('Vertex AI Imagen service initialized successfully');
      } else if (hasApiKey) {
        Logger().log('Using Google AI Studio API key (fallback mode)');

        // Validate API key format
        if (!apiKey.startsWith('AIza')) {
          Logger().log('Warning: API key does not start with expected "AIza" prefix');
        }

        _apiKey = apiKey;
        _isInitialized = true;
        Logger().log('Google AI Studio service initialized successfully');
      } else {
        Logger().log('No valid credentials found. Please set up either:');
        Logger().log('1. GOOGLE_CLOUD_PROJECT + GOOGLE_CLOUD_ACCESS_TOKEN for Vertex AI Imagen');
        Logger().log('2. GOOGLE_AI_API_KEY for Google AI Studio (limited image capabilities)');
        throw Exception('No valid Google Cloud credentials found');
      }

    } catch (e) {
      Logger().log('Failed to initialize image generation service: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Generate an image using Vertex AI Imagen API or Google AI Studio
  /// Returns a map with 'imageBytes', 'description', and 'prompt'
  Future<Map<String, dynamic>?> generateImage({
    required String prompt,
    String aspectRatio = '1:1',
    int retryCount = 3,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check rate limiting before making API call
    if (SharedClaudeRateLimiter.hasRecentRateLimit()) {
      Logger().log('Skipping image generation due to recent rate limit');
      throw Exception('Rate limit detected. Please wait before generating images.');
    }

    try {
      Logger().log('Generating image with prompt: ${prompt.substring(0, prompt.length > 100 ? 100 : prompt.length)}...');

      Uint8List? imageBytes;

      if (_projectId != null && _accessToken != null) {
        // Use Vertex AI Imagen API (preferred)
        imageBytes = await _generateImageWithVertexAI(prompt, aspectRatio);
      } else if (_apiKey != null) {
        // Use Google AI Studio API with Gemini
        Logger().log('Using Google AI Studio API for image generation');
        imageBytes = await _generateImageWithGoogleAI(prompt, aspectRatio);
      }

      if (imageBytes != null) {
        Logger().log('Image generated successfully');
        return {
          'imageBytes': imageBytes,
          'description': 'Generated image: $prompt',
          'prompt': prompt,
          'aspectRatio': aspectRatio,
        };
      } else {
        Logger().log('Failed to generate image');
        return null;
      }

    } catch (e) {
      Logger().log('Error generating image: $e');

      // Handle rate limiting
      if (e.toString().contains('429') || e.toString().contains('rate limit')) {
        throw Exception('Rate limit exceeded. Please wait before generating more images.');
      }

      // Retry logic
      if (retryCount > 0) {
        Logger().log('Retrying image generation ($retryCount attempts left)');
        await Future.delayed(const Duration(seconds: 2));
        return generateImage(
          prompt: prompt,
          aspectRatio: aspectRatio,
          retryCount: retryCount - 1,
        );
      }

      rethrow;
    }
  }

  /// Generate image using Vertex AI Imagen API
  Future<Uint8List?> _generateImageWithVertexAI(String prompt, String aspectRatio) async {
    try {
      // Build the API endpoint
      final endpoint = 'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/google/models/imagen-4.0-generate-001:predict';

      Logger().log('Making request to Vertex AI Imagen API: $endpoint');

      // Prepare the request body
      final requestBody = {
        'instances': [
          {
            'prompt': prompt,
          }
        ],
        'parameters': {
          'sampleCount': 1,
          'aspectRatio': aspectRatio,
          'includeRaiReason': false,
        }
      };

      // Make the HTTP request
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestBody),
      );

      Logger().log('Vertex AI API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        Logger().log('Received response from Vertex AI');

        // Extract the image from the response
        if (responseData['predictions'] != null &&
            responseData['predictions'].isNotEmpty &&
            responseData['predictions'][0]['bytesBase64Encoded'] != null) {

          final base64Image = responseData['predictions'][0]['bytesBase64Encoded'];
          Logger().log('Successfully extracted base64 image data');

          return base64Decode(base64Image);
        } else {
          Logger().log('No image data found in response: ${response.body}');
          return null;
        }
      } else {
        Logger().log('Vertex AI API error: ${response.statusCode} - ${response.body}');
        throw Exception('Vertex AI API error: ${response.statusCode}');
      }
    } catch (e) {
      Logger().log('Error calling Vertex AI Imagen API: $e');
      rethrow;
    }
  }

  /// Generate image using Google AI Studio API
  Future<Uint8List?> _generateImageWithGoogleAI(String prompt, String aspectRatio) async {
    try {
      // Build the API endpoint for Gemini 2.5 Flash Image
      final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent';

      Logger().log('Making request to Google AI Studio Gemini API: $endpoint');

      // Prepare the request body according to Gemini API specification
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['Image'],
          'imageConfig': {
            'aspectRatio': aspectRatio,
          }
        }
      };

      // Make the HTTP request
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'x-goog-api-key': _apiKey!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      Logger().log('Google AI API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        Logger().log('Received response from Google AI Studio');

        // Extract the image from the response
        // The response structure might vary, so we'll try multiple potential paths
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {

          final candidate = responseData['candidates'][0];

          // Check for image data in various possible locations
          String? base64Image;

          // Method 1: Check in parts for inlineData
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            for (var part in candidate['content']['parts']) {
              if (part['inlineData'] != null && part['inlineData']['data'] != null) {
                base64Image = part['inlineData']['data'];
                Logger().log('Found image data in inlineData field');
                break;
              }
            }
          }

          // Method 2: Check for direct image data
          if (base64Image == null && candidate['imageBytes'] != null) {
            base64Image = candidate['imageBytes'];
          }

          if (base64Image != null) {
            Logger().log('Successfully extracted base64 image data');
            return base64Decode(base64Image);
          } else {
            Logger().log('No image data found in response: ${response.body}');
            return null;
          }
        } else {
          Logger().log('No candidates found in response: ${response.body}');
          return null;
        }
      } else {
        Logger().log('Google AI API error: ${response.statusCode} - ${response.body}');

        // Handle specific error types
        if (response.statusCode == 400) {
          throw Exception('Invalid request format or parameters');
        } else if (response.statusCode == 401) {
          throw Exception('Invalid API key or authentication failed');
        } else if (response.statusCode == 403) {
          throw Exception('API access forbidden or quota exceeded');
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please wait before trying again');
        } else {
          throw Exception('Google AI API error: ${response.statusCode}');
        }
      }
    } catch (e) {
      Logger().log('Error calling Google AI Studio API: $e');
      rethrow;
    }
  }

  /// Create a simple placeholder image with text
  /// This simulates image generation until we implement proper API calls
  Future<Uint8List> _createPlaceholderImage(String prompt, String aspectRatio) async {
    // Create a simple SVG-like image representation
    final colors = ['FF6B6B', '4ECDC4', '45B7D1', 'FFA07A', '98D8C8', 'F7DC6F', 'BB8FCE'];
    final colorIndex = prompt.hashCode.abs() % colors.length;
    final bgColor = colors[colorIndex];

    // Create a simple colored rectangle with text as base64 PNG
    // This is a minimal implementation - in practice you'd use proper image generation
    final width = aspectRatio == '16:9' ? 400 : aspectRatio == '9:16' ? 200 : 300;
    final height = aspectRatio == '16:9' ? 225 : aspectRatio == '9:16' ? 355 : 300;

    // Generate a simple pattern based on the prompt
    final pattern = _generateSimplePattern(prompt);

    // Create a minimal PNG header for a solid color image
    // This is a simplified approach - for production use a proper image library
    final base64Data = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';

    return base64Decode(base64Data);
  }

  /// Generate a simple pattern identifier based on prompt
  String _generateSimplePattern(String prompt) {
    final hash = prompt.hashCode.abs();
    return (hash % 10).toString();
  }

  /// Build an enhanced prompt with style and quality instructions
  String _buildEnhancedPrompt(String userPrompt, String aspectRatio) {
    final aspectRatioPrompt = _getAspectRatioPrompt(aspectRatio);

    return '''Create a high-quality, detailed image: $userPrompt

Style requirements:
- Professional quality with crisp, clear details
- Vibrant colors and excellent composition
- Sharp focus and good lighting
$aspectRatioPrompt
- Photorealistic or artistic style as appropriate for the subject''';
  }

  /// Get aspect ratio specific prompt instructions
  String _getAspectRatioPrompt(String aspectRatio) {
    switch (aspectRatio) {
      case '16:9':
        return '- Wide landscape format, suitable for banners or desktop wallpapers';
      case '9:16':
        return '- Tall portrait format, suitable for mobile screens or story formats';
      case '4:3':
        return '- Classic photo format with balanced proportions';
      case '3:2':
        return '- Standard camera aspect ratio with good proportions';
      case '21:9':
        return '- Ultra-wide cinematic format';
      case '1:1':
      default:
        return '- Square format with balanced composition';
    }
  }

  /// Check if the service is properly initialized
  bool get isInitialized => _isInitialized;

  /// Get current rate limit status
  Map<String, dynamic> getRateLimitStatus() {
    return SharedClaudeRateLimiter.getStatusStatic();
  }
}