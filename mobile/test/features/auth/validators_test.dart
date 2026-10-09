import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/validators.dart';

void main() {
  group('emailOrMobile', () {
    test('requires a value', () {
      expect(Validators.emailOrMobile(null), isNotNull);
      expect(Validators.emailOrMobile('   '), isNotNull);
    });

    test('accepts an email address', () {
      expect(Validators.emailOrMobile('name@email.com'), isNull);
      expect(Validators.emailOrMobile('  maya.chen+food@example.co.lk '), isNull);
    });

    test('rejects a malformed email address', () {
      for (final value in ['name@', '@email.com', 'name@email', 'na me@email.com']) {
        expect(Validators.emailOrMobile(value), 'Enter a valid email address.', reason: value);
      }
    });

    test('accepts a mobile number in the usual formats', () {
      for (final value in ['+94771234567', '0771234567', '077 123 4567', '+94 77 123 4567', '(077) 123-4567']) {
        expect(Validators.emailOrMobile(value), isNull, reason: value);
      }
    });

    test('rejects text that is neither', () {
      for (final value in ['maya', '12345', 'abc123456789', '+1 (555) 000']) {
        expect(Validators.emailOrMobile(value), isNotNull, reason: value);
      }
    });
  });

  group('passwords', () {
    test('sign-in only needs a password to be present', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('a'), isNull);
    });

    test('a new password needs 8 characters', () {
      expect(Validators.newPassword('1234567'), 'Use at least 8 characters.');
      expect(Validators.newPassword('12345678'), isNull);
      expect(Validators.newPassword(''), isNotNull);
    });

    test('the confirmation must match', () {
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
      expect(Validators.confirmPassword('secret124', 'secret123'), 'Passwords do not match.');
      expect(Validators.confirmPassword('', 'secret123'), isNotNull);
    });
  });

  test('the name is required', () {
    expect(Validators.fullName(' '), 'Full name is required.');
    expect(Validators.fullName('Maya Chen'), isNull);
  });
}
