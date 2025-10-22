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

  /// Restart the entire app
  Future<void> restartApp() async {
    print('RESET: 🔄 AppRestartService starting restart...');

    // Small delay to ensure all operations are complete
    await Future.delayed(const Duration(milliseconds: 500));

    // Restart the app UI
    _restartCallback?.call();
    print('RESET: ✅ App restart completed');
  }

  /// Check if restart functionality is available
  bool get canRestart => _restartCallback != null;
}