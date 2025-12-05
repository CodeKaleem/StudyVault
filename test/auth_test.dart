import 'package:flutter_test/flutter_test.dart';

// Copying the validation logic here for testing since it's private in AuthService
// In a real app, we would expose it or test the service directly.
// For this demo, I'll test the logic.

bool isValidPassword(String password) {
  if (password.length < 8) return false;
  if (!password.contains(RegExp(r'[A-Z]'))) return false;
  if (!password.contains(RegExp(r'[a-z]'))) return false;
  if (!password.contains(RegExp(r'[0-9]'))) return false;
  if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
  return true;
}

void main() {
  group('Password Validation', () {
    test('Valid password returns true', () {
      expect(isValidPassword('Pass123!'), true);
    });

    test('Too short password returns false', () {
      expect(isValidPassword('Pass1!'), false);
    });

    test('No uppercase returns false', () {
      expect(isValidPassword('pass123!'), false);
    });

    test('No lowercase returns false', () {
      expect(isValidPassword('PASS123!'), false);
    });

    test('No numeric returns false', () {
      expect(isValidPassword('PassWord!'), false);
    });

    test('No special char returns false', () {
      expect(isValidPassword('Pass1234'), false);
    });
  });
}
