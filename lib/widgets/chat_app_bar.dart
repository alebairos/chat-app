import 'package:flutter/material.dart';

class CustomChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomChatAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.military_tech, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text('Sergeant Oracle'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('About Sergeant Oracle'),
                content: const Text(
                  'Sergeant Oracle is an AI assistant powered by Claude. '
                  'It combines ancient Roman wisdom with futuristic insights.\n\n'
                  'You can:\n'
                  '• Send text messages\n'
                  '• Record audio messages\n'
                  '• Long press your messages to delete them\n'
                  '• Scroll up to load older messages',
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
