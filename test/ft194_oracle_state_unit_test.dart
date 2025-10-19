import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/services/system_mcp_service.dart';

/// FT-194 Unit Test: Oracle State Consistency for Philosopher Persona
///
/// Fast unit tests that validate the singleton pattern fixes the Oracle state
/// consistency issue without complex widget testing.
void main() {
  group('FT-194: Oracle State Consistency (Unit Tests)', () {
    setUp(() {
      SystemMCPService.resetSingleton();
    });

    tearDown(() {
      SystemMCPService.resetSingleton();
    });

    test('should create only one singleton instance', () {
      // Arrange & Act
      final instance1 = SystemMCPService.instance;
      final instance2 = SystemMCPService();
      final instance3 = SystemMCPService.instance;

      // Assert
      expect(instance1, same(instance2));
      expect(instance2, same(instance3));
      expect(instance1.hashCode, equals(instance2.hashCode));
    });

    test('should maintain Oracle state across all references', () {
      // Arrange
      final configInstance = SystemMCPService.instance;

      // Act: Configure Oracle for Philosopher persona (disabled)
      configInstance.setOracleEnabled(false);

      // Simulate other services getting references
      final claudeInstance = SystemMCPService.instance;
      final timeInstance = SystemMCPService();

      // Assert: All should see the same Oracle state
      expect(configInstance, same(claudeInstance));
      expect(claudeInstance, same(timeInstance));
      expect(configInstance.isOracleEnabled, isFalse);
      expect(claudeInstance.isOracleEnabled, isFalse);
      expect(timeInstance.isOracleEnabled, isFalse);
    });

    test('should prevent activity detection for Philosopher persona', () {
      // Arrange: Simulate CharacterConfigManager setting Oracle for Philosopher
      final configMCP = SystemMCPService.instance;
      configMCP.setOracleEnabled(false);

      // Act: Simulate ClaudeService checking Oracle state
      final claudeMCP = SystemMCPService.instance;
      final shouldAnalyzeActivities = claudeMCP.isOracleEnabled;

      // Assert: Activity detection should be disabled
      expect(configMCP, same(claudeMCP));
      expect(shouldAnalyzeActivities, isFalse);
    });

    test('should allow activity detection for Oracle Coach persona', () {
      // Arrange: Simulate CharacterConfigManager setting Oracle for Oracle Coach
      final configMCP = SystemMCPService.instance;
      configMCP.setOracleEnabled(true);

      // Act: Simulate ClaudeService checking Oracle state
      final claudeMCP = SystemMCPService.instance;
      final shouldAnalyzeActivities = claudeMCP.isOracleEnabled;

      // Assert: Activity detection should be enabled
      expect(configMCP, same(claudeMCP));
      expect(shouldAnalyzeActivities, isTrue);
    });

    test('should solve multiple instance problem from diagnostic logs', () {
      // Arrange: Simulate the 5 different service references from the logs
      final instances = <SystemMCPService>[];

      // Act: Create multiple references (previously created separate instances)
      instances.add(SystemMCPService.instance); // CharacterConfigManager
      instances.add(SystemMCPService()); // ClaudeService constructor
      instances.add(SystemMCPService.instance); // TimeContextService
      instances.add(SystemMCPService()); // Additional ClaudeService
      instances.add(SystemMCPService.instance); // MCP command processing

      // Configure Oracle on first instance
      instances.first.setOracleEnabled(false);

      // Assert: All instances should be the same object with same state
      final firstInstance = instances.first;
      for (int i = 0; i < instances.length; i++) {
        expect(instances[i], same(firstInstance),
            reason: 'Instance $i should be the same singleton');
        expect(instances[i].isOracleEnabled, isFalse,
            reason: 'Instance $i should have Oracle disabled');
      }
    });

    test('should handle persona switching correctly', () {
      // Arrange
      final mcpService = SystemMCPService.instance;

      // Act & Assert: Switch to Philosopher persona
      mcpService.setOracleEnabled(false);
      expect(mcpService.isOracleEnabled, isFalse);

      // Verify other references see the change
      final otherRef1 = SystemMCPService.instance;
      final otherRef2 = SystemMCPService();
      expect(otherRef1.isOracleEnabled, isFalse);
      expect(otherRef2.isOracleEnabled, isFalse);

      // Act & Assert: Switch to Oracle Coach persona
      mcpService.setOracleEnabled(true);
      expect(mcpService.isOracleEnabled, isTrue);
      expect(otherRef1.isOracleEnabled, isTrue);
      expect(otherRef2.isOracleEnabled, isTrue);
    });

    test('should reset singleton properly for test isolation', () {
      // Arrange: Create instance and set state
      final instance1 = SystemMCPService.instance;
      instance1.setOracleEnabled(false);
      expect(instance1.isOracleEnabled, isFalse);

      // Act: Reset singleton
      SystemMCPService.resetSingleton();

      // Assert: New instance should have default state
      final instance2 = SystemMCPService.instance;
      expect(instance2.isOracleEnabled, isTrue); // Default is enabled
      expect(
          instance1, isNot(same(instance2))); // Different objects after reset
    });

    test('should handle concurrent access safely', () {
      // Arrange: Create multiple references concurrently
      final instances = <SystemMCPService>[];

      // Act: Simulate concurrent singleton access
      for (int i = 0; i < 10; i++) {
        instances.add(SystemMCPService.instance);
      }

      // Assert: All should be the same instance
      final firstInstance = instances.first;
      for (final instance in instances) {
        expect(instance, same(firstInstance));
      }

      // Verify Oracle state consistency
      firstInstance.setOracleEnabled(false);
      for (final instance in instances) {
        expect(instance.isOracleEnabled, isFalse);
      }
    });
  });
}
