import 'dart:io';

// Adjust the import path based on your project structure.
// This assumes 'scripts' is at the root of your Flutter project.
import '../lib/services/chat_storage_service.dart';
// If running as a pure Dart script (not via Flutter tools) and Isar native libraries are not found,
// you might need to uncomment and use the following:
import 'package:isar/isar.dart'; // For Isar.initializeIsarCore

void main(List<String> args) async {
  if (args.isEmpty || args[0].toLowerCase() != 'clean') {
    print('Usage: dart run scripts/isardb.dart clean');
    print(
        'Alternatively, and more reliably, try: flutter pub run scripts/isardb.dart clean');
    exit(1);
  }

  print('Attempting to clean the Isar database...');

  try {
    // Initialize Isar Core - this might be needed for pure Dart execution
    try {
      print(
          'Attempting to initialize IsarCore, this might download binaries if needed.');
      await Isar.initializeIsarCore(download: true);
      print('Isar core initialized successfully.');
    } catch (e) {
      print(
          'Note: Isar core initialization failed or was already initialized: $e');
      // Continue anyway as it might already be initialized
    }

    print('Creating ChatStorageService instance...');
    // Create a storage service instance - the constructor calls openDB()
    final storageService = ChatStorageService();

    // Wait for DB to be ready
    print('Waiting for Isar database connection...');
    await storageService.db;
    print('Database connection established.');

    // Delete all messages
    print('Deleting all messages...');
    await storageService.deleteAllMessages();
    print('All messages deleted successfully.');

    // Close the database
    print('Closing database connection...');
    await storageService.close();
    print('Database closed successfully.');

    print('\nDatabase cleanup complete!');
    exit(0);
  } catch (e, s) {
    print('Error cleaning database: $e');
    print('Stack trace: $s');
    print('\n---');
    print('This script might fail if:');
    print(
        '1. Isar native binaries cannot be found or downloaded (check network and permissions).');
    print('2. The path to the database is incorrect or inaccessible.');
    print(
        '3. `ChatStorageService` has Flutter-specific dependencies that cannot be resolved in a pure Dart environment.');
    print(
        '   (e.g., plugins that require Flutter bindings to be initialized).');
    print(
        'Consider running this script with `flutter run scripts/isardb.dart clean` instead.');
    print('---');
    exit(1);
  }
}
