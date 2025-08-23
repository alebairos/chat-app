import 'package:mocktail/mocktail.dart';
import 'package:ai_personas_app/config/config_loader.dart';

class MockConfigLoader extends Mock implements ConfigLoader {
  String _systemPrompt = 'This is a test system prompt.';

  @override
  Future<String> loadSystemPrompt() async {
    return _systemPrompt;
  }

  void setSystemPrompt(String prompt) {
    _systemPrompt = prompt;
  }
}
