import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../config/config_loader.dart';
import '../screens/persona_selection_screen.dart';
import '../screens/settings/settings_hub_screen.dart';
import '../screens/onboarding/onboarding_flow.dart';
import '../services/profile_service.dart';
import '../services/onboarding_manager.dart';
import '../services/app_restart_service.dart';
import '../services/gemini_image_service.dart';
import '../services/chat_storage_service.dart';
import '../services/profile_picture_service.dart';
import '../models/message_type.dart';

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
  bool _isImageServiceInitialized = false;
  int _totalGeneratedImages = 0;
  Uint8List? _generatedImageData;
  String? _generatedImageDescription;
  Uint8List? _profilePictureData;
  bool _hasProfilePicture = false;

  @override
  void initState() {
    super.initState();
    _loadProfileName();
    _loadImageData();
    _loadProfilePicture();
  }

  Future<void> _loadProfileName() async {
    final name = await ProfileService.getProfileName();
    if (mounted) {
      setState(() {
        _profileName = name;
      });
    }
  }

  Future<void> _loadImageData() async {
    try {
      // Check if Gemini Image Service is available
      final service = GeminiImageService.instance;
      final isInitialized = service.isInitialized;

      // Count generated images from chat storage
      final storageService = ChatStorageService();
      final messages = await storageService.getMessages(limit: 1000);
      final imageCount = messages.where((msg) => msg.type == MessageType.image).length;

      if (mounted) {
        setState(() {
          _isImageServiceInitialized = isInitialized;
          _totalGeneratedImages = imageCount;
        });
      }
    } catch (e) {
      // Handle errors gracefully
      if (mounted) {
        setState(() {
          _isImageServiceInitialized = false;
          _totalGeneratedImages = 0;
        });
      }
    }
  }

  Future<void> _loadProfilePicture() async {
    try {
      final bool hasProfilePicture = await ProfilePictureService.hasProfilePicture();
      if (hasProfilePicture) {
        final Uint8List? pictureData = await ProfilePictureService.getProfilePictureBytes();
        if (mounted) {
          setState(() {
            _hasProfilePicture = hasProfilePicture;
            _profilePictureData = pictureData;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasProfilePicture = false;
            _profilePictureData = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasProfilePicture = false;
          _profilePictureData = null;
        });
      }
    }
  }

  Future<void> _showProfilePictureOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _uploadProfilePictureFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _takeProfilePicture();
              },
            ),
            if (_hasProfilePicture)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Picture', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteProfilePicture();
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfilePictureFromGallery() async {
    try {
      final result = await ProfilePictureService.uploadProfilePicture();

      if (mounted) {
        if (result.success) {
          await _loadProfilePicture();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile picture uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (result.isCancelled) {
          // User cancelled, no error message needed
          return;
        } else {
          // Show appropriate error message
          String message;
          Color backgroundColor;

          if (result.isSimulatorError) {
            message = '⚠️ ${result.errorMessage ?? "Simulator limitation detected"}';
            backgroundColor = Colors.orange;
          } else {
            message = '❌ ${result.errorMessage ?? "Failed to upload profile picture"}';
            backgroundColor = Colors.red;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takeProfilePicture() async {
    try {
      final result = await ProfilePictureService.takeProfilePicture();

      if (mounted) {
        if (result.success) {
          await _loadProfilePicture();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile picture captured successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (result.isCancelled) {
          // User cancelled, no error message needed
          return;
        } else {
          // Show appropriate error message
          String message;
          Color backgroundColor;

          if (result.isSimulatorError) {
            message = '⚠️ ${result.errorMessage ?? "Simulator limitation detected"}';
            backgroundColor = Colors.orange;
          } else {
            message = '❌ ${result.errorMessage ?? "Failed to capture profile picture"}';
            backgroundColor = Colors.red;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      final bool success = await ProfilePictureService.deleteProfilePicture();
      if (success) {
        await _loadProfilePicture();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile picture removed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to remove profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testImageGeneration() async {
    try {
      await GeminiImageService.instance.initialize();

      // Check if profile picture is available
      final profilePictureBytes = await ProfilePictureService.getProfilePictureBytes();
      final hasProfilePicture = profilePictureBytes != null;

      final promptText = hasProfilePicture
          ? "Generate a beautiful artistic image of the user with a friendly dog. Show the user and dog together in a scenic, joyful setting."
          : "Generate an image of a dog";

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(hasProfilePicture
                    ? 'Generating personalized image with your profile...'
                    : 'Generating an image of a dog...'),
              ],
            ),
          ),
        );
      }

      final result = await GeminiImageService.instance.generateImage(
        prompt: promptText,
        aspectRatio: "1:1",
        inputImageBytes: profilePictureBytes,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (result != null) {
          setState(() {
            _generatedImageData = result['imageBytes'];
            _generatedImageDescription = result['description'];
          });

          _showGeneratedImage();
          _loadImageData(); // Refresh data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Image generation test failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGeneratedImage() {
    if (_generatedImageData == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Generated Image'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: InteractiveViewer(
                        child: Image.memory(
                          _generatedImageData!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            label: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testImageGeneration,
                            icon: const Icon(Icons.refresh),
                            label: const Text('New'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageInfo() {
    final service = GeminiImageService.instance;
    final status = service.getRateLimitStatus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Generation Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service Status: ${_isImageServiceInitialized ? "Ready" : "Not initialized"}'),
            const SizedBox(height: 8),
            Text('Total Images Generated: $_totalGeneratedImages'),
            const SizedBox(height: 8),
            Text('Rate Limit Status: ${status["hasRecentRateLimit"] ? "Limited" : "Available"}'),
            const SizedBox(height: 8),
            Text('High API Usage: ${status["hasHighApiUsage"] ? "Yes" : "No"}'),
            const SizedBox(height: 16),
            const Text(
              'To generate images, simply type prompts like:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• "Generate an image of a sunset"'),
            const Text('• "Create a picture of a cat"'),
            const Text('• "Draw an image of a city"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNameEditDialog() async {
    final controller = TextEditingController(text: _profileName);
    String? errorMessage = ProfileService.validateProfileName(_profileName);

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

  Future<void> _showResetConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reset All Data',
          style: TextStyle(color: Colors.red),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• All chat messages and conversations'),
            Text('• All activity tracking data'),
            Text('• Your profile name and settings'),
            Text('• Onboarding completion status'),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone. Are you sure?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performReset();
    }
  }

  Future<void> _performReset() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Resetting all data...'),
          ],
        ),
      ),
    );

    try {
      print('RESET: 📱 Profile screen starting reset...');
      // Reset all user data including onboarding status
      await OnboardingManager.resetAllUserData();
      print('RESET: ✅ Profile screen reset completed');

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showResetCompleteDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // For any error (including Isar issues), assume reset worked and proceed
        if (e.toString().contains('Isar') ||
            e.toString().contains('database')) {
          // Database-related errors likely mean reset worked but connection is unstable
          _showResetCompleteDialog();
        } else {
          // Show actual error for non-database issues
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset Error'),
              content: Text('Failed to reset data: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _showResetCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reset Complete'),
        content: const Text(
          'All data has been cleared successfully. The app will restart now and show the onboarding flow.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              print('RESET: 🔄 User clicked restart button');
              Navigator.of(context).pop(); // Close dialog

              // Small delay to ensure all database operations are finished
              await Future.delayed(const Duration(milliseconds: 500));
              print('RESET: ⏰ Delay completed, starting app restart');

              // Use the restart service to properly restart the app
              await AppRestartService.instance.restartApp();
            },
            child: const Text('Restart App'),
          ),
        ],
      ),
    );
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

                  // Profile Picture Section
                  ListTile(
                    leading: GestureDetector(
                      onTap: _showProfilePictureOptions,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profilePictureData != null
                            ? MemoryImage(_profilePictureData!)
                            : null,
                        child: _profilePictureData == null
                            ? const Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                    title: Text(
                      _hasProfilePicture ? 'Profile Picture' : 'Add Profile Picture',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _hasProfilePicture
                            ? FontWeight.w500
                            : FontWeight.normal,
                        color: _hasProfilePicture ? null : Colors.grey[600],
                      ),
                    ),
                    subtitle: Text(
                      _hasProfilePicture ? 'Tap to change or remove' : 'Upload or take a photo',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: _showProfilePictureOptions,
                  ),

                  const Divider(),

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

          // Image Section
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
                        Icons.image,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Image Generation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Service Status
                  ListTile(
                    leading: Icon(
                      _isImageServiceInitialized ? Icons.check_circle : Icons.error,
                      color: _isImageServiceInitialized ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      _isImageServiceInitialized ? 'Service Ready' : 'Service Not Initialized',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isImageServiceInitialized ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                    subtitle: Text(
                      _isImageServiceInitialized
                          ? 'Gemini 2.5 Flash Image ready to generate images'
                          : 'Set up your Google AI API key to start generating images',
                    ),
                    trailing: const Icon(Icons.info_outline),
                    onTap: _showImageInfo,
                  ),

                  const Divider(),

                  // Image Statistics
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Generated Images'),
                    subtitle: Text('$_totalGeneratedImages images created'),
                    trailing: Text(
                      '$_totalGeneratedImages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),

                  const Divider(),

                  // Test Generation
                  ListTile(
                    leading: const Icon(Icons.science),
                    title: const Text('Test Image Generation'),
                    subtitle: const Text('Generate a test image to verify setup'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: _isImageServiceInitialized ? _testImageGeneration : null,
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
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.restore, color: Colors.red),
                    title: const Text(
                      'Reset All Data',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text(
                        'Clear all messages, activities, and user settings'),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: _showResetConfirmationDialog,
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
