class TestMessage {
  static const gesture = 'adjusts toga';
  static const emoji = '🤔';
  static const greeting = 'Salve, amice!';
  static const boldText = 'Important point';
  static const italicText = 'emphasized text';

  static String get formattedMessage => '''*$gesture* `$emoji`

$greeting **$boldText** and _${italicText}_''';
}
