import 'package:flutter/material.dart';

class CustomChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(
              'https://via.placeholder.com/50',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sergeant Whitaker',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Get motivated and unleash your greatness',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const Text(
            'By @cai-official',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
      toolbarHeight: 120,
    );
  }
}
