import 'user_settings_service.dart';

/// Service for managing user profile data using Isar database
class ProfileService {
  static final UserSettingsService _settingsService = UserSettingsService();

  /// Get the user's profile name
  /// Returns empty string if no name is set
  static Future<String> getProfileName() async {
    try {
      return await _settingsService.getUserName() ?? '';
    } catch (e) {
      // Return empty string on error to maintain graceful fallback
      return '';
    }
  }

  /// Set the user's profile name
  /// Trims whitespace and validates length
  static Future<void> setProfileName(String name) async {
    try {
      final trimmedName = name.trim();

      if (trimmedName.isEmpty) {
        // For empty names, we could set null, but UserSettingsService handles this
        // Let's keep the same behavior as before
        return;
      } else {
        await _settingsService.setUserName(trimmedName);
      }
    } catch (e) {
      // Rethrow to allow UI to handle the error
      rethrow;
    }
  }

  /// Validate profile name
  /// Returns null if valid, error message if invalid
  static String? validateProfileName(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return 'Name cannot be empty';
    }

    if (trimmedName.length > 50) {
      return 'Name must be 50 characters or less';
    }

    // Check for potentially dangerous characters and patterns
    if (trimmedName.contains(RegExp(r'[<>"\\/]')) ||
        trimmedName.toLowerCase().contains('script') ||
        trimmedName.toLowerCase().contains('javascript:') ||
        trimmedName.toLowerCase().contains('jndi:') ||
        trimmedName.contains('..') ||
        trimmedName.contains('\${') ||
        trimmedName.contains('DROP TABLE') ||
        trimmedName.toLowerCase().contains('alert(')) {
      return 'Name contains invalid characters';
    }

    return null; // Valid
  }
}
