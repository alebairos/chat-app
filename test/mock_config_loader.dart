import '../lib/config/config_loader.dart';

class MockConfigLoader extends ConfigLoader {
  static String _systemPrompt = 'Test system prompt';

  static Future<String> loadSystemPrompt() async {
    return _systemPrompt;
  }

  static void setSystemPrompt(String prompt) {
    _systemPrompt = prompt;
  }
}
