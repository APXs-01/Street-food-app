import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/validators.dart';

void main() {
  group('looksLikeMobile (drives the "SMS Ready" badge)', () {
    test('is true for a valid mobile number in the usual formats', () {
      for (final value in ['+94771234567', '0771234567', '077 123 4567', '(077) 123-4567']) {
        expect(Validators.looksLikeMobile(value), isTrue, reason: value);
      }
    });

    test('is false for an email, an empty field or something too short', () {
      for (final value in ['name@example.com', '', '   ', '12345', 'abc']) {
        expect(Validators.looksLikeMobile(value), isFalse, reason: value);
      }

      expect(Validators.looksLikeMobile(null), isFalse);
    });
  });
}
