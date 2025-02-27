import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/chat_screen.dart';
import 'utils/logger.dart';
import 'services/life_plan_service.dart';
import 'services/claude_service.dart';
import 'services/life_plan_mcp_service.dart';

Future<void> main() async {
  // Initialize logger with appropriate settings
  final logger = Logger();

  // Enable general logging but disable startup logging by default
  // This will prevent logging all past chat history when the app starts
  logger.setLogging(true);
  logger.setStartupLogging(false);

  logger.info('Starting application');

  await dotenv.load(fileName: '.env');

  // Initialize services with logging settings
  final lifePlanService = LifePlanService();
  lifePlanService.setLogging(true);
  lifePlanService.setStartupLogging(false);

  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Character.ai Clone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ChatScreen(),
      // Add error handling for the entire app
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
