import 'package:flutter/material.dart';
import '../../config/config_loader.dart';
import '../../services/context_logger_service.dart';
import '../persona_selection_screen.dart';
import 'chat_management_screen.dart';
import 'context_logging_settings_screen.dart';
import 'widgets/settings_section_header.dart';
import 'widgets/settings_card.dart';

class SettingsHubScreen extends StatelessWidget {
  final Function() onCharacterSelected;

  const SettingsHubScreen({
    Key? key,
    required this.onCharacterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Choose Your Guide Section
          const SettingsSectionHeader(title: 'Choose Your Guide'),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: ConfigLoader().activePersonaDisplayName,
            builder: (context, snapshot) {
              final currentPersona = snapshot.data ?? 'Loading...';
              return SettingsCard(
                icon: Icons.person_outline,
                title: 'Choose Your Guide',
                subtitle: 'Select and customize your AI persona',
                trailing: currentPersona,
                onTap: () => _navigateToPersonas(context),
              );
            },
          ),

          const SizedBox(height: 32), // Generous section spacing

          // Chat Management Section
          const SettingsSectionHeader(title: 'Chat Management'),
          const SizedBox(height: 16),
          SettingsCard(
            icon: Icons.folder_outlined,
            title: 'Chat Management',
            subtitle: 'Export, import, and clear conversations',
            onTap: () => _navigateToChatManagement(context),
          ),

          const SizedBox(height: 32),

          // Developer Tools Section (FT-220: Only show if feature is available in config)
          FutureBuilder<bool>(
            future: _isContextLoggingAvailable(),
            builder: (context, snapshot) {
              final isAvailable = snapshot.data ?? false;
              if (!isAvailable) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsSectionHeader(title: 'Developer Tools'),
                  const SizedBox(height: 16),
                  SettingsCard(
                    icon: Icons.bug_report_outlined,
                    title: 'Context Logging',
                    subtitle: 'Debug mode: Log complete AI context',
                    onTap: () => _navigateToContextLogging(context),
                  ),
                  const SizedBox(height: 32), // Bottom padding
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Check if context logging feature is available
  Future<bool> _isContextLoggingAvailable() async {
    final contextLogger = ContextLoggerService();
    await contextLogger.initialize();
    return contextLogger.isFeatureAvailable;
  }

  void _navigateToPersonas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonaSelectionScreen(
          onCharacterSelected: onCharacterSelected,
        ),
      ),
    );
  }

  void _navigateToChatManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatManagementScreen(
          onCharacterSelected: onCharacterSelected,
        ),
      ),
    );
  }

  void _navigateToContextLogging(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContextLoggingSettingsScreen(),
      ),
    );
  }
}
