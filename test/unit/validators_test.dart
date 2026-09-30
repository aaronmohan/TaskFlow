import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_provider_starter/utils/validators.dart';

void main() {
  group('Email Validation', () {
    test('Empty email returns error', () {
      expect(Validators.validateEmail(''), 'Email address is required');
      expect(Validators.validateEmail(null), 'Email address is required');
    });

    test('Invalid email returns error', () {
      expect(Validators.validateEmail('invalid-email'), 'Enter a valid email address');
      expect(Validators.validateEmail('user@'), 'Enter a valid email address');
      expect(Validators.validateEmail('@example.com'), 'Enter a valid email address');
    });

    test('Valid email returns null', () {
      expect(Validators.validateEmail('aaron@taskflow.dev'), isNull);
      expect(Validators.validateEmail('user.name+tag@example.co.uk'), isNull);
    });
  });

  group('Password Validation', () {
    test('Empty password returns error', () {
      expect(Validators.validatePassword(''), 'Password is required');
      expect(Validators.validatePassword(null), 'Password is required');
    });

    test('Short password returns error', () {
      expect(Validators.validatePassword('12345'), 'Password must be at least 6 characters');
    });

    test('Valid password returns null', () {
      expect(Validators.validatePassword('secure123'), isNull);
    });
  });
}
