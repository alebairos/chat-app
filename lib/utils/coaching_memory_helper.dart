/// FT-156: Coaching Memory Helper
/// 
/// Utility functions to help personas construct coaching-style responses
/// using activity message linking data.

class CoachingMemoryHelper {
  /// Generate coaching context from activity data
  /// 
  /// Transforms raw activity data into natural coaching language:
  /// - "Lembro que você disse 'Acabei de beber água' às 20:57 💧"
  /// - "I remember you said 'Just finished my workout' at 3:45 PM 💪"
  static String generateCoachingContext({
    required String activityName,
    required String sourceMessageText,
    required String time,
    String? emoji,
    String language = 'pt_BR',
  }) {
    final emojiSuffix = emoji != null ? ' $emoji' : '';
    
    switch (language) {
      case 'en_US':
        return "I remember you said '$sourceMessageText' at $time$emojiSuffix";
      case 'pt_BR':
      default:
        return "Lembro que você disse '$sourceMessageText' às $time$emojiSuffix";
    }
  }
  
  /// Generate coaching context from multiple activities
  /// 
  /// Creates a summary of recent activities with message context:
  /// - "Hoje você já me contou sobre beber água (20:57) e fazer exercício (15:30)"
  static String generateActivitySummary({
    required List<Map<String, dynamic>> activities,
    String language = 'pt_BR',
  }) {
    if (activities.isEmpty) {
      return language == 'en_US' 
        ? "I don't have any recent activity memories to reference."
        : "Não tenho memórias recentes de atividades para referenciar.";
    }
    
    final activityDescriptions = activities
        .where((activity) => activity['source_message_text'] != null)
        .map((activity) {
          final name = activity['name'] as String;
          final time = activity['time'] as String;
          final messageText = activity['source_message_text'] as String;
          
          return language == 'en_US'
            ? "$name ($time)"
            : "$name ($time)";
        })
        .take(3) // Limit to 3 most recent
        .toList();
    
    if (activityDescriptions.isEmpty) {
      return language == 'en_US'
        ? "I have activity records but no message context available."
        : "Tenho registros de atividades mas sem contexto de mensagem disponível.";
    }
    
    final joinedActivities = activityDescriptions.join(', ');
    
    return language == 'en_US'
      ? "Today you've told me about: $joinedActivities"
      : "Hoje você já me contou sobre: $joinedActivities";
  }
  
  /// Get activity emoji based on activity code or name
  /// 
  /// Maps common activities to appropriate emojis for coaching context
  static String? getActivityEmoji(String? activityCode, String activityName) {
    // Map by Oracle code first
    if (activityCode != null) {
      switch (activityCode.toUpperCase()) {
        case 'SF1': return '💧'; // Beber água
        case 'SF2': return '🚶'; // Caminhada
        case 'SF3': return '🏃'; // Corrida
        case 'SF4': return '💪'; // Exercício
        case 'SF5': return '🧘'; // Meditação
        case 'SF6': return '😴'; // Dormir
        case 'SF7': return '🍎'; // Alimentação saudável
        default: break;
      }
    }
    
    // Fallback to name-based mapping
    final lowerName = activityName.toLowerCase();
    if (lowerName.contains('água') || lowerName.contains('water')) return '💧';
    if (lowerName.contains('exerc') || lowerName.contains('workout')) return '💪';
    if (lowerName.contains('caminh') || lowerName.contains('walk')) return '🚶';
    if (lowerName.contains('corr') || lowerName.contains('run')) return '🏃';
    if (lowerName.contains('medita') || lowerName.contains('meditat')) return '🧘';
    if (lowerName.contains('dorm') || lowerName.contains('sleep')) return '😴';
    if (lowerName.contains('comer') || lowerName.contains('eat') || lowerName.contains('food')) return '🍎';
    
    return null; // No emoji found
  }
  
  /// Format time for coaching context
  /// 
  /// Converts 24h format to more natural language
  static String formatTimeForCoaching(String time24h, {String language = 'pt_BR'}) {
    try {
      final parts = time24h.split(':');
      if (parts.length != 2) return time24h;
      
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      
      // Return original if parsing fails or values are invalid
      if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return time24h;
      }
      
      if (language == 'en_US') {
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
      } else {
        // Portuguese - keep 24h format but make it more natural
        return '${hour}h${minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return time24h; // Return original if parsing fails
    }
  }
  
  /// Create full coaching response from activity data
  /// 
  /// Combines all helper functions to create a complete coaching response
  static String createCoachingResponse({
    required Map<String, dynamic> activity,
    String language = 'pt_BR',
    String? customMessage,
  }) {
    final activityName = activity['name'] as String;
    final sourceMessageText = activity['source_message_text'] as String?;
    final time = activity['time'] as String;
    final activityCode = activity['code'] as String?;
    
    if (sourceMessageText == null || sourceMessageText.isEmpty) {
      // Fallback for activities without message context
      return language == 'en_US'
        ? "I see you completed $activityName at $time."
        : "Vejo que você completou $activityName às $time.";
    }
    
    final emoji = getActivityEmoji(activityCode, activityName);
    final formattedTime = formatTimeForCoaching(time, language: language);
    
    final coachingContext = generateCoachingContext(
      activityName: activityName,
      sourceMessageText: sourceMessageText,
      time: formattedTime,
      emoji: emoji,
      language: language,
    );
    
    if (customMessage != null) {
      return '$coachingContext. $customMessage';
    }
    
    return coachingContext;
  }
}
