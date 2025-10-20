import 'database_service.dart';

/// Service for restarting the entire app after major state changes like data reset
class AppRestartService {
  static AppRestartService? _instance;
  static AppRestartService get instance => _instance ??= AppRestartService._();
  AppRestartService._();

  /// Callback function to restart the app, set by the main app widget
  void Function()? _restartCallback;

  /// Register the restart callback from the main app
  void setRestartCallback(void Function() callback) {
    _restartCallback = callback;
  }

  /// Restart the entire app and ensure database is reinitialized
  Future<void> restartApp() async {
    print('RESET: 🔄 AppRestartService starting restart...');

    // Ensure database is properly reinitialized
    await DatabaseService.instance.reinitializeDatabase();
    print('RESET: 📱 Database reinitialized');

    // Restart the app UI
    _restartCallback?.call();
    print('RESET: ✅ App restart completed');
  }

  /// Check if restart functionality is available
  bool get canRestart => _restartCallback != null;
}