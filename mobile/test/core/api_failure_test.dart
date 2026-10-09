import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_failure.dart';

DioException _badResponse(int status, Object? data) {
  final options = RequestOptions(path: '/x');

  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('a 422 keeps the first message per field and uses the first one as the message', () {
    final failure = ApiFailure.fromDio(_badResponse(422, {
      'message': 'The given data was invalid.',
      'errors': {
        'email': ['The email has already been taken.', 'Another'],
        'password': ['The password field confirmation does not match.'],
      },
    }));

    expect(failure.statusCode, 422);
    expect(failure.fieldErrors, {
      'email': 'The email has already been taken.',
      'password': 'The password field confirmation does not match.',
    });
    expect(failure.message, 'The email has already been taken.');
    expect(failure.hasFieldErrors, isTrue);
  });

  test('a failed login is a 422 on the login field', () {
    final failure = ApiFailure.fromDio(_badResponse(422, {
      'message': 'These credentials do not match our records.',
      'errors': {
        'login': ['These credentials do not match our records.'],
      },
    }));

    expect(failure.fieldErrors['login'], 'These credentials do not match our records.');
  });

  test('a wrong-role 403 carries the message and the real role', () {
    final failure = ApiFailure.fromDio(_badResponse(403, {
      'message': 'This account is a Vendor account. Please use the Vendor login.',
      'role': 'vendor',
    }));

    expect(failure.message, contains('Vendor login'));
    expect(failure.role, 'vendor');
    expect(failure.hasFieldErrors, isFalse);
  });

  test('a 409 for a vendor who already has a stall carries that stall\'s id', () {
    final failure = ApiFailure.fromDio(_badResponse(409, {
      'message': 'You already have a stall registered. Each vendor account can manage one stall.',
      'vendor_id': 7,
    }));

    expect(failure.vendorId, 7);
    expect(failure.message, contains('already have a stall'));
    expect(failure.withoutFields(['x']).vendorId, 7);
  });

  test('a suspended account message is passed through', () {
    final failure = ApiFailure.fromDio(_badResponse(403, {'message': 'This account has been suspended.'}));

    expect(failure.message, 'This account has been suspended.');
  });

  test('throttling gets a friendly message', () {
    final failure = ApiFailure.fromDio(_badResponse(429, {'message': 'Too Many Attempts.'}));

    expect(failure.message, contains('Too many attempts'));
  });

  test('a server error hides the details', () {
    final failure = ApiFailure.fromDio(_badResponse(500, {'message': 'Server Error', 'exception': 'secret'}));

    expect(failure.message, contains('our side'));
  });

  test('no connection reads as an offline problem', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      final failure = ApiFailure.fromDio(DioException(requestOptions: RequestOptions(path: '/x'), type: type));

      expect(failure.message, contains('Check your connection'));
    }
  });

  test('a body that is not JSON falls back to a generic message', () {
    final failure = ApiFailure.fromDio(_badResponse(400, '<html>oops</html>'));

    expect(failure.message, 'Something went wrong. Please try again.');
  });

  test('withoutFields drops only the named fields', () {
    const failure = ApiFailure(message: 'x', fieldErrors: {'email': 'a', 'password': 'b'});

    final after = failure.withoutFields(['email']);

    expect(after.fieldErrors, {'password': 'b'});
  });
}
