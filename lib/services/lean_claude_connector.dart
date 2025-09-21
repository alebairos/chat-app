import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// FT-149: Lean Claude Connector for Metadata Extraction
///
/// Provides lightweight, direct HTTP access to Claude API without the overhead
/// of full ClaudeService initialization (MCP, Oracle, Audio, Persona configs).
///
/// Use this ONLY for focused metadata extraction tasks.
class LeanClaudeConnector {
  static final Logger _logger = Logger();
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const Duration _timeout = Duration(seconds: 10);

  /// Make a lightweight call to Claude API for metadata extraction
  static Future<String?> extractMetadata({
    required String prompt,
    int maxTokens =
        1000, // FT-149.5: Increased from 500 to prevent JSON truncation
  }) async {
    try {
      // Get API key from environment
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        _logger
            .warning('FT-149: Anthropic API key not found for lean extraction');
        return null;
      }

      // Build minimal request payload
      final payload = {
        'model':
            'claude-3-5-sonnet-20241022', // Upgraded to Sonnet for better quality
        'max_tokens': maxTokens,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'system':
            'You are an intelligent metadata extraction specialist for activity tracking. Analyze user activities with sophisticated understanding of fitness, wellness, and human behavior. Extract meaningful, contextual metadata that reveals patterns and insights. Always return valid, complete JSON with rich detail.',
      };

      // Make direct HTTP request
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: json.encode(payload),
          )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content']?[0]?['text'] as String?;

        if (content != null && content.isNotEmpty) {
          _logger.debug(
              'FT-149: Lean extraction successful (${content.length} chars)');
          return content;
        } else {
          _logger.warning('FT-149: Lean extraction returned empty content');
          return null;
        }
      } else if (response.statusCode == 429) {
        // Rate limit - let the queue handle retry logic
        throw Exception('Rate limit exceeded');
      } else {
        _logger.warning(
            'FT-149: Lean extraction failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      if (e.toString().contains('429') || e.toString().contains('Rate limit')) {
        // Re-throw rate limit errors for queue handling
        rethrow;
      } else {
        _logger.warning('FT-149: Lean extraction error: $e');
        return null;
      }
    }
  }

  /// Check if the lean connector is properly configured
  static bool isConfigured() {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Get estimated cost per extraction (for monitoring)
  static double getEstimatedCostUSD(
      {int inputTokens = 200, int outputTokens = 100}) {
    // Claude 3 Haiku pricing: $0.25/1M input tokens, $1.25/1M output tokens
    const inputCostPer1M = 0.25;
    const outputCostPer1M = 1.25;

    final inputCost = (inputTokens / 1000000) * inputCostPer1M;
    final outputCost = (outputTokens / 1000000) * outputCostPer1M;

    return inputCost + outputCost;
  }
}
