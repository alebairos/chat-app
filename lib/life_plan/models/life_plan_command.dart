import 'package:flutter/foundation.dart';

/// Represents the different types of life plan commands available
enum LifePlanCommandType {
  plan,
  explore,
  help,
  unknown;

  String get command => '/${name.toLowerCase()}';

  static final Set<String> validCommands = {'/plan', '/explore', '/help'};
}

/// Represents a life plan dimension
enum LifePlanDimension {
  physical('SF', '💪', 'Physical Realm',
      'The foundation of your vitality and strength'),
  mental('SM', '🧠', 'Mental Domain', 'The fortress of your mind and wisdom'),
  relationships('R', '❤️', 'Relationships Kingdom',
      'The bonds that strengthen your journey');

  final String code;
  final String emoji;
  final String title;
  final String description;

  const LifePlanDimension(this.code, this.emoji, this.title, this.description);

  static LifePlanDimension? fromCode(String code) {
    return LifePlanDimension.values.firstWhere(
      (d) => d.code == code.toUpperCase(),
      orElse: () => throw ArgumentError('Invalid dimension code: $code'),
    );
  }
}

/// Represents a parsed life plan command
@immutable
class LifePlanCommand {
  final LifePlanCommandType type;
  final LifePlanDimension? dimension;

  const LifePlanCommand({
    required this.type,
    this.dimension,
  });

  /// Creates a command from raw text input
  factory LifePlanCommand.fromText(String text) {
    final parts = text.trim().split(' ');
    final command = parts[0].toLowerCase();

    switch (command) {
      case '/plan':
        return const LifePlanCommand(type: LifePlanCommandType.plan);
      case '/explore':
        if (parts.length < 2) {
          return const LifePlanCommand(type: LifePlanCommandType.explore);
        }
        try {
          final dimension = LifePlanDimension.fromCode(parts[1]);
          return LifePlanCommand(
              type: LifePlanCommandType.explore, dimension: dimension);
        } catch (_) {
          return const LifePlanCommand(type: LifePlanCommandType.explore);
        }
      case '/help':
        return const LifePlanCommand(type: LifePlanCommandType.help);
      default:
        return const LifePlanCommand(type: LifePlanCommandType.help);
    }
  }

  /// Checks if the given text is a life plan command
  static bool isCommand(String text) {
    final command = text.trim().split(' ')[0].toLowerCase();
    return LifePlanCommandType.validCommands.contains(command);
  }
}
