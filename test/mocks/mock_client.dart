import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockClient extends Mock implements http.Client {
  final Map<String, ResponseData> _responses = {};

  void addResponse(String message, String response, {int statusCode = 200}) {
    _responses[message] = ResponseData(response, statusCode);
  }

  @override
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    // Extract the message from the body if it's a JSON string
    String? message;

    if (body is String && body.contains('"messages"')) {
      try {
        // Simple extraction of the user message - this is a simplification
        // In a real scenario, you'd want to parse the JSON properly
        final regex = RegExp(r'"content"\s*:\s*"([^"]*)"');
        final match = regex.firstMatch(body.toString());
        if (match != null && match.groupCount >= 1) {
          message = match.group(1);
        }
      } catch (e) {
        print('Error extracting message: $e');
      }
    }

    // Use the message as the key if found, otherwise use the body string
    final key = message ?? body.toString();

    // Return the mocked response if we have one for this key
    if (_responses.containsKey(key)) {
      final responseData = _responses[key]!;

      // Format successful responses like Claude's API
      if (responseData.statusCode == 200) {
        final responseJson = {
          'content': [
            {'text': responseData.body, 'type': 'text'}
          ],
        };
        return http.Response(
            json.encode(responseJson), responseData.statusCode);
      }

      // For error responses, return as is
      return http.Response(responseData.body, responseData.statusCode);
    }

    // Default response if no match found
    return http.Response('{"content":[{"text":"Default mock response"}]}', 200);
  }
}

class ResponseData {
  final String body;
  final int statusCode;

  ResponseData(this.body, this.statusCode);
}
