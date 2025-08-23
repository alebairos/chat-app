import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:character_ai_clone/config/character_config_manager.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  print('🔍 Verifying Default Persona Configuration...\n');

  try {
    // Create a character manager instance
    final manager = CharacterConfigManager();

    print('📋 Initial state:');
    print('   Active Persona: ${manager.activePersonaKey}');
    print('   Is Initialized: ${manager.isInitialized}');
    print('');

    // Initialize the manager
    print('🚀 Initializing CharacterConfigManager...');
    await manager.initialize();
    print('');

    print('✅ After initialization:');
    print('   Active Persona: ${manager.activePersonaKey}');
    print('   Is Initialized: ${manager.isInitialized}');
    print('');

    // Verify the expected behavior
    const expectedPersona = 'ariWithOracle21';
    if (manager.activePersonaKey == expectedPersona) {
      print('🎉 SUCCESS: Default persona correctly set to "$expectedPersona"');
    } else {
      print(
          '❌ FAILURE: Expected "$expectedPersona" but got "${manager.activePersonaKey}"');
    }

    // Test persona switching
    print('\n🔄 Testing persona switching...');
    manager.setActivePersona('sergeantOracle');
    print('   Switched to: ${manager.activePersonaKey}');

    // Re-initialize to see if it respects the config
    print('\n🔄 Re-initializing...');
    await manager.initialize();
    print('   Active Persona after re-init: ${manager.activePersonaKey}');

    if (manager.activePersonaKey == expectedPersona) {
      print('🎉 SUCCESS: Re-initialization correctly restored default persona');
    } else {
      print('❌ FAILURE: Re-initialization did not restore default persona');
    }
  } catch (e) {
    print('❌ Error during verification: $e');
  }
}
