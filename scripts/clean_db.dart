import 'package:flutter/material.dart';
import '../lib/services/chat_storage_service.dart';

void main() async {
  // Initialize Flutter binding so we can use Flutter plugins like path_provider
  WidgetsFlutterBinding.ensureInitialized();

  print('Creating ChatStorageService instance...');
  final storageService = ChatStorageService();

  try {
    print('Waiting for Isar database connection...');
    await storageService.db;
    print('Database connection established.');

    print('Deleting all messages...');
    await storageService.deleteAllMessages();
    print('All messages deleted successfully.');

    print('Closing database connection...');
    await storageService.close();
    print('Database closed successfully.');

    print('\nDatabase cleanup complete!');
  } catch (e, s) {
    print('Error cleaning database: $e');
    print('Stack trace: $s');
  }
}
