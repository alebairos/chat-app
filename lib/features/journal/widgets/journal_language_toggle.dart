import 'package:flutter/material.dart';

/// Widget for toggling between Portuguese and English languages
class JournalLanguageToggle extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;

  const JournalLanguageToggle({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'pt_BR',
          label: Text('PT'),
        ),
        ButtonSegment<String>(
          value: 'en_US',
          label: Text('EN'),
        ),
      ],
      selected: {selectedLanguage},
      onSelectionChanged: (Set<String> newSelection) {
        if (newSelection.isNotEmpty) {
          onLanguageChanged(newSelection.first);
        }
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
