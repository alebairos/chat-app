import 'package:flutter/material.dart';
import '../config/config_loader.dart';
import '../config/character_config_manager.dart';

class CustomChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomChatAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final configLoader = ConfigLoader();
    final activePersona = configLoader.activePersona;
    final personaDisplayName = configLoader.activePersonaDisplayName;

    // Get the appropriate icon and color based on persona
    IconData personaIcon;
    Color personaColor;

    switch (activePersona) {
      case CharacterPersona.ariLifeCoach:
        personaIcon = Icons.psychology;
        personaColor = Colors.teal;
        break;
      case CharacterPersona.sergeantOracle:
        personaIcon = Icons.military_tech;
        personaColor = Colors.deepPurple;
        break;
      case CharacterPersona.zenGuide:
        personaIcon = Icons.self_improvement;
        personaColor = Colors.green;
        break;
      case CharacterPersona.personalDevelopmentAssistant:
        personaIcon = Icons.person;
        personaColor = Colors.blue;
        break;
    }

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: personaColor,
            child: Icon(personaIcon, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(personaDisplayName),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Information',
          onPressed: () {
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
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
