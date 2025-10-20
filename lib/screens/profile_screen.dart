import 'package:flutter/material.dart';
import '../config/config_loader.dart';
import '../screens/persona_selection_screen.dart';
import '../screens/settings/settings_hub_screen.dart';
import '../screens/onboarding/onboarding_flow.dart';
import '../services/profile_service.dart';

/// Profile screen with persona management and settings access
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onPersonaChanged; // FT-213: Add callback

  const ProfileScreen({
    super.key,
    this.onPersonaChanged, // FT-213: Add parameter
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ConfigLoader _configLoader = ConfigLoader();
  String _profileName = '';

  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final name = await ProfileService.getProfileName();
    if (mounted) {
      setState(() {
        _profileName = name;
      });
    }
  }

  Future<void> _showNameEditDialog() async {
    final controller = TextEditingController(text: _profileName);
    String? errorMessage;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Your Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'How should AI personas address you?',
                  hintText: 'Enter your name',
                  errorText: errorMessage,
                ),
                onChanged: (value) {
                  setDialogState(() {
                    errorMessage = ProfileService.validateProfileName(value);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: errorMessage == null
                  ? () => Navigator.of(context).pop(controller.text)
                  : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        await ProfileService.setProfileName(result);
        await _loadProfileName(); // Refresh the display
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save name: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 16),

          // Persona Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Your Guide',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Profile Name Section
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: Text(
                      _profileName.isEmpty ? 'Add your name' : _profileName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _profileName.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w500,
                        color: _profileName.isEmpty ? Colors.grey[600] : null,
                      ),
                    ),
                    subtitle: const Text('How AI personas address you'),
                    trailing: const Icon(Icons.edit),
                    onTap: _showNameEditDialog,
                  ),

                  const Divider(),

                  FutureBuilder<String>(
                    future: _configLoader.activePersonaDisplayName,
                    builder: (context, snapshot) {
                      final currentPersona = snapshot.data ?? 'Loading...';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            currentPersona.isNotEmpty ? currentPersona[0] : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          currentPersona,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text('AI Persona'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonaSelectionScreen(
                                onCharacterSelected: () {
                                  setState(
                                      () {}); // Keep existing ProfileScreen refresh
                                  widget.onPersonaChanged
                                      ?.call(); // FT-213: Notify parent
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Settings Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Personas da Lyfe'),
                    subtitle: const Text('Conheça suas IA'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingFlow(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Chat Management'),
                    subtitle:
                        const Text('Export, import, and clear conversations'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsHubScreen(
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
            ),
          ),

          const SizedBox(height: 32),

          // App Info
          Center(
            child: Column(
              children: [
                Text(
                  'AI Personas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
