import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/chat_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profile_screen.dart';
import 'features/journal/screens/journal_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'services/onboarding_manager.dart';
import 'services/oracle_static_cache.dart';
import 'services/dimension_display_service.dart';
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

  // Initialize Portuguese locale for date formatting
  try {
    await initializeDateFormatting('pt_BR', null);
    logger.info('✅ Portuguese locale initialized');
  } catch (e) {
    logger.warning('Failed to initialize Portuguese locale: $e');
  }

  // Initialize the config loader and character manager
  final configLoader = ConfigLoader();
  await configLoader.initialize();
  logger.info('✅ ConfigLoader and CharacterConfigManager initialized');

  // FT-140: Initialize Oracle static cache at app startup
  try {
    await OracleStaticCache.initializeAtStartup();
    logger.info('✅ Oracle static cache initialized successfully');
  } catch (e) {
    logger.warning('Failed to initialize Oracle static cache: $e');
  }

  // FT-146: Initialize dimension display service
  try {
    await DimensionDisplayService.initialize();
    logger.info('✅ DimensionDisplayService initialized successfully');
    // FT-147: Log service state for debugging
    DimensionDisplayService.logServiceState();
  } catch (e) {
    logger.warning('Failed to initialize DimensionDisplayService: $e');
  }

  // Note: LifePlan service initialization removed

  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Personas da Lyfe',
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
  bool _isCheckingOnboarding = true;
  String _currentPersonaDisplayName =
      'Loading...'; // FT-208: Track persona name

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
    _checkAndShowOnboarding();
    _loadCurrentPersonaName(); // FT-208: Load initial persona name
  }

  // FT-208: Load current persona name
  Future<void> _loadCurrentPersonaName() async {
    try {
      final name = await _configLoader.activePersonaDisplayName;
      if (mounted) {
        setState(() {
          _currentPersonaDisplayName = name;
        });
      }
    } catch (e) {
      print('FT-208: Error loading persona name: $e');
    }
  }

  // FT-208: Callback to refresh persona name when it changes
  void _refreshPersonaName() {
    print('FT-208: Refreshing persona name in title');
    _loadCurrentPersonaName();
  }

  Future<void> _checkAndShowOnboarding() async {
    final shouldShow = await OnboardingManager.shouldShowOnboarding();

    setState(() {
      _isCheckingOnboarding = false;
    });

    if (shouldShow && mounted) {
      // Show onboarding flow
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const OnboardingFlow(),
          fullscreenDialog: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingOnboarding) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
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
              _currentPersonaDisplayName, // FT-208: Use state variable
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatScreen(
              onPersonaChanged: _refreshPersonaName), // FT-208: Pass callback
          const StatsScreen(),
          const JournalScreen(),
          ProfileScreen(
              onPersonaChanged: _refreshPersonaName), // FT-213: Add callback
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
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Journal',
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
