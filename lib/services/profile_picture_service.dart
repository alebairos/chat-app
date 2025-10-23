import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/logger.dart';

/// Service for managing user profile pictures
class ProfilePictureService {
  static final Logger _logger = Logger();
  static const String _profilePictureFileName = 'profile_picture.jpg';

  /// Upload a new profile picture from image picker
  static Future<ProfilePictureResult> uploadProfilePicture() async {
    try {
      // Check if running on iOS simulator
      if (!kIsWeb && Platform.isIOS && !kDebugMode) {
        // On iOS simulator, image picker often fails
        _logger.warning('ProfilePicture: Running on iOS simulator, image picker may not work properly');
      }

      final ImagePicker picker = ImagePicker();

      // Show selection dialog
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        _logger.info('ProfilePicture: User cancelled image selection');
        return ProfilePictureResult(success: false, isCancelled: true);
      }

      _logger.info('ProfilePicture: Selected image from gallery: ${image.path}');

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Save to app directory
      final bool saved = await _saveProfilePictureBytes(imageBytes);

      if (saved) {
        _logger.info('ProfilePicture: Successfully uploaded and saved profile picture');
        return ProfilePictureResult(success: true);
      } else {
        _logger.error('ProfilePicture: Failed to save profile picture');
        return ProfilePictureResult(success: false, errorMessage: 'Failed to save image');
      }
    } on PlatformException catch (e) {
      String errorMessage;
      if (e.code == 'channel-error' && e.message?.contains('Unable to establish connection') == true) {
        errorMessage = 'Image picker not available on iOS Simulator. Please test on a physical device.';
        _logger.warning('ProfilePicture: iOS Simulator image picker error: $e');
      } else {
        errorMessage = 'Platform error: ${e.message ?? e.code}';
        _logger.error('ProfilePicture: Platform exception: $e');
      }
      return ProfilePictureResult(success: false, errorMessage: errorMessage, isSimulatorError: true);
    } catch (e) {
      _logger.error('ProfilePicture: Error uploading profile picture: $e');
      return ProfilePictureResult(success: false, errorMessage: 'Unexpected error: $e');
    }
  }

  /// Take a new profile picture using camera
  static Future<ProfilePictureResult> takeProfilePicture() async {
    try {
      // Check if running on iOS simulator
      if (!kIsWeb && Platform.isIOS && !kDebugMode) {
        // On iOS simulator, camera is not available
        _logger.warning('ProfilePicture: Running on iOS simulator, camera not available');
      }

      final ImagePicker picker = ImagePicker();

      // Take photo with camera
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        _logger.info('ProfilePicture: User cancelled camera capture');
        return ProfilePictureResult(success: false, isCancelled: true);
      }

      _logger.info('ProfilePicture: Captured image with camera: ${image.path}');

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Save to app directory
      final bool saved = await _saveProfilePictureBytes(imageBytes);

      if (saved) {
        _logger.info('ProfilePicture: Successfully captured and saved profile picture');
        return ProfilePictureResult(success: true);
      } else {
        _logger.error('ProfilePicture: Failed to save captured profile picture');
        return ProfilePictureResult(success: false, errorMessage: 'Failed to save image');
      }
    } on PlatformException catch (e) {
      String errorMessage;
      if (e.code == 'channel-error' && e.message?.contains('Unable to establish connection') == true) {
        errorMessage = 'Camera not available on iOS Simulator. Please test on a physical device.';
        _logger.warning('ProfilePicture: iOS Simulator camera error: $e');
      } else {
        errorMessage = 'Platform error: ${e.message ?? e.code}';
        _logger.error('ProfilePicture: Platform exception: $e');
      }
      return ProfilePictureResult(success: false, errorMessage: errorMessage, isSimulatorError: true);
    } catch (e) {
      _logger.error('ProfilePicture: Error taking profile picture: $e');
      return ProfilePictureResult(success: false, errorMessage: 'Unexpected error: $e');
    }
  }

  /// Save profile picture bytes to app directory
  static Future<bool> _saveProfilePictureBytes(Uint8List imageBytes) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final File profilePictureFile = File('${appDir.path}/$_profilePictureFileName');

      await profilePictureFile.writeAsBytes(imageBytes);
      _logger.info('ProfilePicture: Saved profile picture to ${profilePictureFile.path}');

      return true;
    } catch (e) {
      _logger.error('ProfilePicture: Error saving profile picture bytes: $e');
      return false;
    }
  }

  /// Get the current profile picture as bytes
  static Future<Uint8List?> getProfilePictureBytes() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final File profilePictureFile = File('${appDir.path}/$_profilePictureFileName');

      if (await profilePictureFile.exists()) {
        final Uint8List imageBytes = await profilePictureFile.readAsBytes();
        _logger.debug('ProfilePicture: Loaded profile picture (${imageBytes.length} bytes)');
        return imageBytes;
      } else {
        _logger.debug('ProfilePicture: No profile picture found');
        return null;
      }
    } catch (e) {
      _logger.error('ProfilePicture: Error loading profile picture: $e');
      return null;
    }
  }

  /// Check if a profile picture exists
  static Future<bool> hasProfilePicture() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final File profilePictureFile = File('${appDir.path}/$_profilePictureFileName');

      final bool exists = await profilePictureFile.exists();
      _logger.debug('ProfilePicture: Profile picture exists: $exists');
      return exists;
    } catch (e) {
      _logger.error('ProfilePicture: Error checking profile picture existence: $e');
      return false;
    }
  }

  /// Delete the current profile picture
  static Future<bool> deleteProfilePicture() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final File profilePictureFile = File('${appDir.path}/$_profilePictureFileName');

      if (await profilePictureFile.exists()) {
        await profilePictureFile.delete();
        _logger.info('ProfilePicture: Deleted profile picture');
        return true;
      } else {
        _logger.debug('ProfilePicture: No profile picture to delete');
        return true; // Consider it successful if there's nothing to delete
      }
    } catch (e) {
      _logger.error('ProfilePicture: Error deleting profile picture: $e');
      return false;
    }
  }

  /// Get profile picture file path for display purposes
  static Future<String?> getProfilePicturePath() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final File profilePictureFile = File('${appDir.path}/$_profilePictureFileName');

      if (await profilePictureFile.exists()) {
        return profilePictureFile.path;
      }
      return null;
    } catch (e) {
      _logger.error('ProfilePicture: Error getting profile picture path: $e');
      return null;
    }
  }
}

/// Result class for profile picture operations
class ProfilePictureResult {
  final bool success;
  final String? errorMessage;
  final bool isCancelled;
  final bool isSimulatorError;

  ProfilePictureResult({
    required this.success,
    this.errorMessage,
    this.isCancelled = false,
    this.isSimulatorError = false,
  });
}