import 'package:flutter/material.dart';

/// A chat bubble for displaying persona introductions in onboarding
class PersonaChatBubble extends StatelessWidget {
  final String personaName;
  final String quote;
  final Color? bubbleColor;

  const PersonaChatBubble({
    required this.personaName,
    required this.quote,
    this.bubbleColor,
    super.key,
  });

  Color _getPersonaColor(String personaName) {
    switch (personaName.toLowerCase()) {
      case 'ari':
      case 'ari 2.1':
        return Colors.teal;
      case 'sergeant oracle':
      case 'sergeant oracle 2.1':
        return Colors.deepPurple;
      case 'i-there':
      case 'i-there 2.1':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPersonaIcon(String personaName) {
    switch (personaName.toLowerCase()) {
      case 'ari':
      case 'ari 2.1':
        return Icons.psychology;
      case 'sergeant oracle':
      case 'sergeant oracle 2.1':
        return Icons.military_tech;
      case 'i-there':
      case 'i-there 2.1':
        return Icons.face;
      default:
        return Icons.smart_toy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = bubbleColor ?? _getPersonaColor(personaName);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 20,
            child: Icon(
              _getPersonaIcon(personaName),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '- $personaName',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
