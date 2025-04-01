import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'screens/character_selection_screen.dart';
import 'utils/logger.dart';
import 'services/life_plan_service.dart';
import 'config/config_loader.dart';
import 'features/audio_assistant/services/tts_service_factory.dart';
import 'features/audio_assistant/services/audio_message_provider.dart';
import 'features/audio_assistant/services/audio_generation.dart';

Future<void> main() async {
  // Initialize logger with appropriate settings
  final logger = Logger();

  // Enable general logging but disable startup logging by default
  // This will prevent logging all past chat history when the app starts
  logger.setLogging(true);
  logger.setStartupLogging(false);

  // Disable debug prints during startup
  logger.setDebugPrintsOnStartup(false);

  // Set app in startup mode
  logger.setStartupMode(true);

  logger.info('Starting application');

  await dotenv.load(fileName: '.env');

  // Initialize services with logging settings
  final lifePlanService = LifePlanService();
  lifePlanService.setLogging(true);
  lifePlanService.setStartupLogging(false);

  // Set the default TTS service to Flutter TTS
  TTSServiceFactory.setActiveServiceType(TTSServiceType.flutterTTS);

  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AudioMessageProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Character.ai Clone',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const HomeScreen(),
        // Add error handling for the entire app
        builder: (context, child) {
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ConfigLoader _configLoader = ConfigLoader();

  @override
  void initState() {
    super.initState();
    // App has finished startup, enable debug prints for user interactions
    Logger().setStartupMode(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_configLoader.activePersonaDisplayName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterSelectionScreen(
                    onCharacterSelected: () {
                      setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: const ChatScreen(),
    );
  }
}
