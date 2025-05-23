import '../../../utils/logger.dart';

/// Service for managing character-specific voice configurations
class CharacterVoiceConfig {
  final Logger _logger = Logger();

  /// Voice configurations for different characters
  static const Map<String, Map<String, dynamic>> _characterVoices = {
    'Guide Sergeant Oracle': {
      'voiceId':
          'pNInz6obpgDQGcFmaJgB', // Can be updated to more military voice
      'modelId': 'eleven_multilingual_v1',
      'stability': 0.75, // Higher for authoritative consistency
      'similarityBoost': 0.85, // Strong character presence
      'style': 0.3, // Add assertive character
      'speakerBoost': true,
      'description':
          'Authoritative military sergeant voice - disciplined, motivational, commanding',
    },
    'default': {
      'voiceId': 'pNInz6obpgDQGcFmaJgB',
      'modelId': 'eleven_multilingual_v1',
      'stability': 0.6,
      'similarityBoost': 0.8,
      'style': 0.0,
      'speakerBoost': true,
      'description': 'Standard assistant voice',
    },
  };

  /// Get voice configuration for a specific character
  static Map<String, dynamic> getVoiceConfig(String characterName) {
    final config =
        _characterVoices[characterName] ?? _characterVoices['default']!;
    return Map<String, dynamic>.from(config);
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
