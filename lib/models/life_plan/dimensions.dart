import 'package:flutter/material.dart';

/// Represents a life dimension with all its properties
class Dimension {
  final String code;
  final String emoji;
  final String title;
  final String englishTitle;
  final String portugueseTitle;
  final String description;
  final Color color;

  const Dimension({
    required this.code,
    required this.emoji,
    required this.title,
    required this.englishTitle,
    required this.portugueseTitle,
    required this.description,
    required this.color,
  });

  /// Returns a dimension by its code
  static Dimension? fromCode(String code) {
    try {
      return Dimensions.all.firstWhere(
        (d) => d.code == code.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Central repository of all life dimensions
class Dimensions {
  // Private constructor to prevent instantiation
  Dimensions._();

  // Physical Health
  static const Dimension physical = Dimension(
    code: 'SF',
    emoji: '💪',
    title: 'Physical Health',
    englishTitle: 'Physical Health',
    portugueseTitle: 'Saúde Física',
    description: 'The foundation of your vitality and strength',
    color: Colors.red,
  );

  // Mental Health
  static const Dimension mental = Dimension(
    code: 'SM',
    emoji: '🧠',
    title: 'Mental Health',
    englishTitle: 'Mental Health',
    portugueseTitle: 'Saúde Mental',
    description: 'The fortress of your mind and wisdom',
    color: Colors.blue,
  );

  // Relationships
  static const Dimension relationships = Dimension(
    code: 'R',
    emoji: '❤️',
    title: 'Relationships',
    englishTitle: 'Relationships',
    portugueseTitle: 'Relacionamentos',
    description: 'The bonds that strengthen your journey',
    color: Colors.pink,
  );

  // Spirituality
  static const Dimension spirituality = Dimension(
    code: 'E',
    emoji: '✨',
    title: 'Spirituality',
    englishTitle: 'Spirituality',
    portugueseTitle: 'Espiritualidade',
    description: 'The connection to purpose and meaning',
    color: Colors.purple,
  );

  // Rewarding Work
  static const Dimension work = Dimension(
    code: 'TG',
    emoji: '💼',
    title: 'Rewarding Work',
    englishTitle: 'Rewarding Work',
    portugueseTitle: 'Trabalho Gratificante',
    description: 'The pursuit of fulfilling and meaningful career',
    color: Colors.amber,
  );

  // List of all dimensions
  static const List<Dimension> all = [
    physical,
    mental,
    relationships,
    spirituality,
    work,
  ];

  // Map of dimensions by code for quick lookup
  static final Map<String, Dimension> byCode = {
    for (var dimension in all) dimension.code: dimension,
  };

  // Get all dimension codes
  static List<String> get codes => all.map((d) => d.code).toList();

  // Get a dimension by its code
  static Dimension? getDimension(String code) => fromCode(code);

  // Shorthand for fromCode
  static Dimension? fromCode(String code) {
    final upperCode = code.toUpperCase();
    return byCode[upperCode];
  }
}
