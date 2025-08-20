// Template for service classes in this Flutter project
// Follow this pattern when creating new services

import 'dart:async';
import '../utils/logger.dart';

/// Template service class following project patterns
class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  // Service state
  bool _isInitialized = false;
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  // Public getters
  bool get isInitialized => _isInitialized;
  Stream<bool> get statusStream => _statusController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      Logger.info('TemplateService: Initializing...');

      // Initialization logic here

      _isInitialized = true;
      _statusController.add(true);
      Logger.info('TemplateService: Initialized successfully');
    } catch (e) {
      Logger.error('TemplateService: Initialization failed', e);
      _statusController.add(false);
      rethrow;
    }
  }

  /// Main service method
  Future<String> performOperation(String input) async {
    if (!_isInitialized) {
      throw Exception('TemplateService not initialized');
    }

    try {
      Logger.debug('TemplateService: Performing operation with input: $input');

      // Service logic here
      final result = 'Processed: $input';

      Logger.debug('TemplateService: Operation completed successfully');
      return result;
    } catch (e) {
      Logger.error('TemplateService: Operation failed', e);
      rethrow;
    }
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await _statusController.close();
    _isInitialized = false;
    Logger.info('TemplateService: Disposed');
  }
}
