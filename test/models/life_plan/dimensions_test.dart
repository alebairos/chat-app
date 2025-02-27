import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/models/life_plan/dimensions.dart';
import 'package:flutter/material.dart';

void main() {
  group('Dimensions', () {
    test('contains all required dimensions', () {
      expect(Dimensions.all.length, equals(5));

      expect(Dimensions.physical.code, equals('SF'));
      expect(Dimensions.mental.code, equals('SM'));
      expect(Dimensions.relationships.code, equals('R'));
      expect(Dimensions.spirituality.code, equals('E'));
      expect(Dimensions.work.code, equals('TG'));
    });

    test('fromCode returns correct dimension', () {
      expect(Dimensions.fromCode('SF'), equals(Dimensions.physical));
      expect(Dimensions.fromCode('SM'), equals(Dimensions.mental));
      expect(Dimensions.fromCode('R'), equals(Dimensions.relationships));
      expect(Dimensions.fromCode('E'), equals(Dimensions.spirituality));
      expect(Dimensions.fromCode('TG'), equals(Dimensions.work));
    });

    test('fromCode handles case-insensitive codes', () {
      expect(Dimensions.fromCode('sf'), equals(Dimensions.physical));
      expect(Dimensions.fromCode('sm'), equals(Dimensions.mental));
      expect(Dimensions.fromCode('r'), equals(Dimensions.relationships));
      expect(Dimensions.fromCode('e'), equals(Dimensions.spirituality));
      expect(Dimensions.fromCode('tg'), equals(Dimensions.work));
    });

    test('fromCode returns null for invalid codes', () {
      expect(Dimensions.fromCode('INVALID'), isNull);
      expect(Dimensions.fromCode(''), isNull);
    });

    test('getDimension is an alias for fromCode', () {
      expect(Dimensions.getDimension('SF'), equals(Dimensions.physical));
      expect(Dimensions.getDimension('INVALID'), isNull);
    });

    test('codes returns all dimension codes', () {
      final codes = Dimensions.codes;
      expect(codes.length, equals(5));
      expect(codes, contains('SF'));
      expect(codes, contains('SM'));
      expect(codes, contains('R'));
      expect(codes, contains('E'));
      expect(codes, contains('TG'));
    });

    test('byCode provides quick lookup', () {
      expect(Dimensions.byCode['SF'], equals(Dimensions.physical));
      expect(Dimensions.byCode['SM'], equals(Dimensions.mental));
      expect(Dimensions.byCode['R'], equals(Dimensions.relationships));
      expect(Dimensions.byCode['E'], equals(Dimensions.spirituality));
      expect(Dimensions.byCode['TG'], equals(Dimensions.work));
    });

    test('dimensions have correct properties', () {
      // Physical
      expect(Dimensions.physical.code, equals('SF'));
      expect(Dimensions.physical.emoji, equals('💪'));
      expect(Dimensions.physical.title, equals('Physical Health'));
      expect(Dimensions.physical.englishTitle, equals('Physical Health'));
      expect(Dimensions.physical.portugueseTitle, equals('Saúde Física'));
      expect(Dimensions.physical.description,
          equals('The foundation of your vitality and strength'));
      expect(Dimensions.physical.color, equals(Colors.red));

      // Mental
      expect(Dimensions.mental.code, equals('SM'));
      expect(Dimensions.mental.emoji, equals('🧠'));
      expect(Dimensions.mental.title, equals('Mental Health'));
      expect(Dimensions.mental.englishTitle, equals('Mental Health'));
      expect(Dimensions.mental.portugueseTitle, equals('Saúde Mental'));
      expect(Dimensions.mental.description,
          equals('The fortress of your mind and wisdom'));
      expect(Dimensions.mental.color, equals(Colors.blue));

      // Relationships
      expect(Dimensions.relationships.code, equals('R'));
      expect(Dimensions.relationships.emoji, equals('❤️'));
      expect(Dimensions.relationships.title, equals('Relationships'));
      expect(Dimensions.relationships.englishTitle, equals('Relationships'));
      expect(
          Dimensions.relationships.portugueseTitle, equals('Relacionamentos'));
      expect(Dimensions.relationships.description,
          equals('The bonds that strengthen your journey'));
      expect(Dimensions.relationships.color, equals(Colors.pink));

      // Spirituality
      expect(Dimensions.spirituality.code, equals('E'));
      expect(Dimensions.spirituality.emoji, equals('✨'));
      expect(Dimensions.spirituality.title, equals('Spirituality'));
      expect(Dimensions.spirituality.englishTitle, equals('Spirituality'));
      expect(
          Dimensions.spirituality.portugueseTitle, equals('Espiritualidade'));
      expect(Dimensions.spirituality.description,
          equals('The connection to purpose and meaning'));
      expect(Dimensions.spirituality.color, equals(Colors.purple));

      // Work
      expect(Dimensions.work.code, equals('TG'));
      expect(Dimensions.work.emoji, equals('💼'));
      expect(Dimensions.work.title, equals('Rewarding Work'));
      expect(Dimensions.work.englishTitle, equals('Rewarding Work'));
      expect(Dimensions.work.portugueseTitle, equals('Trabalho Gratificante'));
      expect(Dimensions.work.description,
          equals('The pursuit of fulfilling and meaningful career'));
      expect(Dimensions.work.color, equals(Colors.amber));
    });
  });

  group('Dimension', () {
    test('fromCode static method works correctly', () {
      expect(Dimension.fromCode('SF'), equals(Dimensions.physical));
      expect(Dimension.fromCode('INVALID'), isNull);
    });
  });
}
