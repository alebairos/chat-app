import 'package:flutter/foundation.dart';
import 'life_plan_command.dart';
import '../../models/life_plan/dimensions.dart';

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
      ..writeln('**Choose a dimension:**');

    // Use the centralized dimensions model
    for (final dimension in Dimensions.all) {
      buffer.writeln(
          '- ${dimension.code}: ${dimension.title} (${dimension.portugueseTitle})');
    }

    return LifePlanResponse(message: buffer.toString());
  }

  /// Creates a dimension exploration prompt
  factory LifePlanResponse.explore(LifePlanDimension? dimension) {
    if (dimension == null) {
      final dimensionCodes =
          Dimensions.all.map((d) => '${d.code} for ${d.title}').join(', ');
      return LifePlanResponse.error(
        'Which dimension would you like to explore? Use $dimensionCodes.',
      );
    }

    String realmName;
    switch (dimension) {
      case LifePlanDimension.physical:
        realmName = 'physical realm';
        break;
      case LifePlanDimension.mental:
        realmName = 'mental domain';
        break;
      case LifePlanDimension.relationships:
        realmName = 'relationships kingdom';
        break;
      case LifePlanDimension.spirituality:
        realmName = 'spiritual dimension';
        break;
      case LifePlanDimension.work:
        realmName = 'work territory';
        break;
    }

    return LifePlanResponse(
      message: '*consults ancient map* `${dimension.emoji}`\n'
          'Ah, the $realmName! A noble choice. '
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

    // Use the centralized dimensions model
    for (final dimension in Dimensions.all) {
      buffer.writeln(
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
