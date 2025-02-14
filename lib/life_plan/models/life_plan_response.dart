import 'package:flutter/foundation.dart';
import 'life_plan_command.dart';

/// Represents a formatted response from the life plan system
@immutable
class LifePlanResponse {
  final String message;
  final bool isError;

  const LifePlanResponse({
    required this.message,
    this.isError = false,
  });

  /// Creates an error response
  factory LifePlanResponse.error(String message) {
    return LifePlanResponse(
      message: '*adjusts spectacles* `🧐`\n$message',
      isError: true,
    );
  }

  /// Creates the initial planning response
  factory LifePlanResponse.plan() {
    final buffer = StringBuffer()
      ..writeln('*adjusts chronometer* `⚔️`')
      ..writeln(
          'Salve, time wanderer! Let\'s focus on your life journey. Which dimension would you like to explore?')
      ..writeln()
      ..writeln('**Choose a dimension:**')
      ..writeln('- SF: Physical Health (Saúde Física)')
      ..writeln('- SM: Mental Health (Saúde Mental)')
      ..writeln('- R: Relationships (Relacionamentos)');

    return LifePlanResponse(message: buffer.toString());
  }

  /// Creates a dimension exploration prompt
  factory LifePlanResponse.explore(LifePlanDimension? dimension) {
    if (dimension == null) {
      return LifePlanResponse.error(
        'Which dimension would you like to explore? Use SF for Physical, SM for Mental, or R for Relationships.',
      );
    }

    return LifePlanResponse(
      message: '*consults ancient map* `${dimension.emoji}`\n'
          'Ah, the ${dimension.title.toLowerCase()}! A noble choice. '
          'Let me illuminate the paths before you...',
    );
  }

  /// Creates the help response
  factory LifePlanResponse.help() {
    final buffer = StringBuffer()
      ..writeln('*unfurls ancient scroll* `📜`')
      ..writeln('Greetings, seeker! Here are the commands for your journey:')
      ..writeln()
      ..writeln('- /plan - Begin your life\'s quest');

    for (final dimension in LifePlanDimension.values) {
      buffer
        ..writeln(
            '- /explore ${dimension.code} - Venture into ${dimension.title}');
    }

    buffer
      ..writeln()
      ..writeln('_Per aspera ad astra_ - Through hardships to the stars!');

    return LifePlanResponse(message: buffer.toString());
  }

  /// Creates an unknown command response
  factory LifePlanResponse.unknown() {
    return LifePlanResponse.error(
      'I do not recognize that command, brave soul. Type /help to see the available pathways.',
    );
  }
}
