import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user profile data
class ProfileService {
  static const String _profileNameKey = 'user_profile_name';

  /// Get the user's profile name
  /// Returns empty string if no name is set
  static Future<String> getProfileName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_profileNameKey) ?? '';
    } catch (e) {
      // Return empty string on error to maintain graceful fallback
      return '';
    }
  }

  /// Set the user's profile name
  /// Trims whitespace and validates length
  static Future<void> setProfileName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmedName = name.trim();

      if (trimmedName.isEmpty) {
        // Remove the preference if name is empty
        await prefs.remove(_profileNameKey);
      } else {
        await prefs.setString(_profileNameKey, trimmedName);
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

    if (trimmedName.length > 50) {
      return 'Name must be 50 characters or less';
    }

    if (trimmedName.contains(RegExp(r'[<>"\\/]'))) {
      return 'Name contains invalid characters';
    }

    return null; // Valid
  }
}
