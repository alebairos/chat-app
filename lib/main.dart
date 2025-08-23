import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/chat_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profile_screen.dart';
import 'utils/logger.dart';

import 'config/config_loader.dart';

Future<void> main() async {
  // Initialize logger with appropriate settings
  final logger = Logger();

  // Enable general logging but disable startup logging by default
  // This will prevent logging all past chat history when the app starts
  logger.setLogging(true);
  logger.setStartupLogging(false);

  logger.info('Starting application');

  await dotenv.load(fileName: '.env');

  // Initialize the config loader and character manager
  final configLoader = ConfigLoader();
  await configLoader.initialize();
  logger.info('✅ ConfigLoader and CharacterConfigManager initialized');

  // Note: LifePlan service initialization removed

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
      home: const HomeScreen(),
      // Add error handling for the entire app
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ConfigLoader _configLoader = ConfigLoader();
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _configLoader.activePersonaDisplayName,
          builder: (context, snapshot) {
            final personaDisplayName = snapshot.data ?? 'Loading...';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI Personas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  personaDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: true,
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ChatScreen(),
          StatsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _tabController.animateTo(index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
