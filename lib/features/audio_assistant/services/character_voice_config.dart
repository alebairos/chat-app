import 'package:flutter_dotenv/flutter_dotenv.dart';
// ignore_for_file: unused_import
import '../../../utils/logger.dart';

/// Service for managing character-specific voice configurations
class CharacterVoiceConfig {
  /// Voice configurations for different characters
  static final Map<String, Map<String, dynamic>> _characterVoices = {
    'Ari - Life Coach': {
      // Voice ID is overridden at runtime from .env if available
      'voiceId': 'pNInz6obpgDQGcFmaJgB',
      'modelId': 'eleven_multilingual_v1',
      'stability': 0.7,
      'similarityBoost': 0.8,
      'style': 0.1,
      'speakerBoost': true,
      'apply_text_normalization': 'auto', // FT-120: Enhanced number/date reading
      'description':
          'Masculine coach voice tuned for Portuguese (Brazil) and English',
    },
    'Guide Sergeant Oracle': {
      'voiceId':
          'pNInz6obpgDQGcFmaJgB', // Can be updated to more military voice
      'modelId': 'eleven_multilingual_v1',
      'stability': 0.75, // Higher for authoritative consistency
      'similarityBoost': 0.85, // Strong character presence
      'style': 0.3, // Add assertive character
      'speakerBoost': true,
      'apply_text_normalization': 'auto', // FT-120: Enhanced number/date reading
      'description':
          'Authoritative military sergeant voice - disciplined, motivational, commanding',
    },
    'The Zen Master': {
      'voiceId': 'pNInz6obpgDQGcFmaJgB', // Calm, contemplative voice
      'modelId': 'eleven_multilingual_v1',
      'stability': 0.85, // Very stable for serene presence
      'similarityBoost': 0.75, // Gentle but present
      'style': 0.0, // Neutral, peaceful tone
      'speakerBoost': true,
      'apply_text_normalization': 'auto', // FT-120: Enhanced number/date reading
      'description':
          'Serene zen master voice - calm, wise, contemplative, peaceful',
    },
    'default': {
      'voiceId': 'pNInz6obpgDQGcFmaJgB',
      'modelId': 'eleven_multilingual_v1',
      'stability': 0.6,
      'similarityBoost': 0.8,
      'style': 0.0,
      'speakerBoost': true,
      'apply_text_normalization': 'auto', // FT-120: Enhanced number/date reading
      'description': 'Standard assistant voice',
    },
  };

  /// Get voice configuration for a specific character
  static Map<String, dynamic> getVoiceConfig(String characterName) {
    final baseConfig =
        _characterVoices[characterName] ?? _characterVoices['default']!;
    final resolved = Map<String, dynamic>.from(baseConfig);

    // If Ari is the active character, prefer voiceId from .env to keep a
    // single masculine multilingual voice across languages.
    if (characterName == 'Ari - Life Coach') {
      final envVoiceId = dotenv.env['ELEVEN_LABS_VOICE_ID'] ??
          dotenv.env['ELEVENLABS_VOICE_ID'];
      if (envVoiceId != null && envVoiceId.isNotEmpty) {
        resolved['voiceId'] = envVoiceId;
      }

      // Ensure multilingual model is used for cross-language support
      // Prefer existing value if already multilingual; otherwise set it.
      final modelId = (resolved['modelId'] as String?) ?? '';
      if (!modelId.startsWith('eleven_multilingual_')) {
        resolved['modelId'] = 'eleven_multilingual_v1';
      }
    }

    return resolved;
  }

  /// Get all available character voices
  static List<String> getAvailableCharacters() {
    return _characterVoices.keys.where((key) => key != 'default').toList();
  }

  /// Update voice configuration for a character
  static void updateCharacterVoice(
      String characterName, Map<String, dynamic> newConfig) {
    // This would typically update a persistent configuration
    // For now, we'll log the intended update
    Logger().debug(
        'Character voice update requested for $characterName: $newConfig');
  }

  /// Military-specific voice optimization settings
  static Map<String, dynamic> getMilitaryVoiceOptimization() {
    return {
      'stability': 0.8, // Very stable for authority
      'similarityBoost': 0.9, // Strong presence
      'style': 0.4, // More assertive
      'speakerBoost': true,
      'additionalInstructions': {
        'tone': 'authoritative but encouraging',
        'pace': 'measured and deliberate',
        'emphasis': 'clear enunciation',
        'character': 'military drill sergeant - firm but supportive'
      }
    };
  }
}
