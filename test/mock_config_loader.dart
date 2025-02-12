import 'dart:convert';
import 'package:character_ai_clone/config/config_loader.dart';

class MockConfigLoader extends ConfigLoader {
  static final String _defaultSystemPrompt = json.encode({
    "system_prompt": {
      "role": "system",
      "content":
          "You are Sergeant Oracle, a test assistant. You have access to life planning data through these commands:\n- get_goals_by_dimension\n- get_track_by_id\n- get_habits_for_challenge\n- get_recommended_habits"
    }
  });

  MockConfigLoader() {
    print('🔧 Initializing MockConfigLoader');
    setLoadSystemPromptImpl(() async {
      print('📜 Loading mock system prompt');
      print('📋 Mock prompt content: $_defaultSystemPrompt');
      return _defaultSystemPrompt;
    });
    print('✓ MockConfigLoader initialized');
  }
}
