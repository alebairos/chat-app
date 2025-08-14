import 'package:flutter/material.dart';
import '../config/config_loader.dart';

class CustomChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomChatAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final configLoader = ConfigLoader();
    final activePersonaKey = configLoader.activePersonaKey;

    // Get dynamic icon and color based on persona key
    final IconData personaIcon = _getPersonaIcon(activePersonaKey);
    final Color personaColor = _getPersonaColor(activePersonaKey);

    return AppBar(
      title: FutureBuilder<String>(
        future: configLoader.activePersonaDisplayName,
        builder: (context, snapshot) {
          final personaDisplayName = snapshot.data ?? 'Loading...';
          return Text(
            personaDisplayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Information',
          onPressed: () async {
            final personaDisplayName =
                await configLoader.activePersonaDisplayName;
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About $personaDisplayName'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '$personaDisplayName is an AI assistant powered by Claude.'),
                        const SizedBox(height: 16),
                        const Text('You can:'),
                        const SizedBox(height: 8),
                        const Text('• Send text messages'),
                        const Text('• Record audio messages'),
                        const Text('• Long press your messages to delete them'),
                        const Text('• Scroll up to load older messages'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  IconData _getPersonaIcon(String personaKey) {
    // Generate consistent icons based on persona key
    final Map<String, IconData> iconMap = {
      'ariLifeCoach': Icons.psychology,
      'sergeantOracle': Icons.military_tech,
      'iThereClone': Icons.face,
    };

    return iconMap[personaKey] ?? Icons.smart_toy;
  }

  Color _getPersonaColor(String personaKey) {
    // Generate consistent colors based on persona key hash
    final int hash = personaKey.hashCode;
    final List<Color> colors = [
      Colors.teal,
      Colors.deepPurple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.indigo,
    ];
    return colors[hash.abs() % colors.length];
  }
}
