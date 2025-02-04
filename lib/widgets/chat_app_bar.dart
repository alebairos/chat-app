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
      title: const Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(
              'https://via.placeholder.com/50',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Sergeant Whitaker',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Get motivated and unleash your greatness',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
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
