import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/api_failure.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';

import '../../support/fakes.dart';

void main() {
  late RecordingAdapter adapter;
  late AuthRepository repository;

  AuthRepository build(ResponseBody Function(RequestOptions) respond) {
    adapter = RecordingAdapter(respond);
    final dio = createDio(
      storage: TokenStorage(MemoryStore()),
      onUnauthorized: () {},
      baseUrl: 'http://test/api',
    )..httpClientAdapter = adapter;

    return AuthRepository(dio);
  }

  setUp(() {
    repository = build((_) => jsonResponse(200, {'token': 'plain-token', 'user': userJson()}));
  });

  group('login', () {
    test('posts `login` and `password` to the role endpoint and reads { token, user }', () async {
      final result = await repository.login(role: UserRole.vendor, identifier: '  maya@example.com ', password: 'secret123');

      expect(adapter.last.method, 'POST');
      expect(adapter.last.uri.path, '/api/vendor/login');
      expect(adapter.last.data, {'login': 'maya@example.com', 'password': 'secret123'});
      expect(result.token, 'plain-token');
      expect(result.user.name, 'Maya Chen');
      expect(result.user.role, 'consumer');
      expect(result.user.vendorId, isNull);
    });

    test('a phone number goes in the same `login` field', () async {
      await repository.login(role: UserRole.consumer, identifier: '077 123 4567', password: 'x');

      expect(adapter.last.uri.path, '/api/consumer/login');
      expect(adapter.last.data['login'], '077 123 4567');
    });

    test('a wrong password is a 422 on `login`', () async {
      repository = build((_) => jsonResponse(422, {
            'message': 'These credentials do not match our records.',
            'errors': {
              'login': ['These credentials do not match our records.'],
            },
          }));

      await expectLater(
        repository.login(role: UserRole.consumer, identifier: 'a@b.co', password: 'nope'),
        throwsA(isA<ApiFailure>().having((f) => f.fieldErrors['login'], 'login error', isNotNull)),
      );
    });

    test('the wrong role is a 403 that names the right one', () async {
      repository = build((_) => jsonResponse(403, {'message': 'Please use the Vendor login.', 'role': 'vendor'}));

      await expectLater(
        repository.login(role: UserRole.consumer, identifier: 'a@b.co', password: 'x'),
        throwsA(isA<ApiFailure>().having((f) => f.role, 'role', 'vendor')),
      );
    });

    test('an unexpected response body is reported, not thrown as a type error', () async {
      repository = build((_) => jsonResponse(200, {'nope': true}));

      await expectLater(
        repository.login(role: UserRole.consumer, identifier: 'a@b.co', password: 'x'),
        throwsA(isA<ApiFailure>()),
      );
    });
  });

  group('register', () {
    test('an email goes in `email`, with terms and the confirmation', () async {
      await repository.register(
        role: UserRole.consumer,
        name: ' Maya Chen ',
        identifier: 'Maya@Example.com',
        password: 'secret123',
        passwordConfirmation: 'secret123',
        acceptedTerms: true,
      );

      expect(adapter.last.uri.path, '/api/consumer/register');
      expect(adapter.last.data, {
        'name': 'Maya Chen',
        'email': 'Maya@Example.com',
        'password': 'secret123',
        'password_confirmation': 'secret123',
        'terms': true,
      });
      expect(adapter.last.data.containsKey('phone'), isFalse);
    });

    test('a mobile number goes in `phone`, not `email`', () async {
      await repository.register(
        role: UserRole.vendor,
        name: 'Raju',
        identifier: '+94 77 123 4567',
        password: 'secret123',
        passwordConfirmation: 'secret123',
        acceptedTerms: true,
      );

      expect(adapter.last.uri.path, '/api/vendor/register');
      expect(adapter.last.data['phone'], '+94 77 123 4567');
      expect(adapter.last.data.containsKey('email'), isFalse);
    });

    test('a taken email is a 422 on `email`', () async {
      repository = build((_) => jsonResponse(422, {
            'message': 'The email has already been taken.',
            'errors': {
              'email': ['The email has already been taken.'],
            },
          }));

      await expectLater(
        repository.register(
          role: UserRole.consumer,
          name: 'Maya',
          identifier: 'maya@example.com',
          password: 'secret123',
          passwordConfirmation: 'secret123',
          acceptedTerms: true,
        ),
        throwsA(isA<ApiFailure>().having((f) => f.fieldErrors['email'], 'email error', isNotNull)),
      );
    });

    test('register and login do not send a bearer token', () async {
      await repository.login(role: UserRole.consumer, identifier: 'a@b.co', password: 'x');

      expect(adapter.last.headers.containsKey('Authorization'), isFalse);
    });
  });

  test('fetchCurrentUser reads the user from the `data` wrapper', () async {
    repository = build((_) => jsonResponse(200, {'data': userJson(role: 'vendor', vendorId: 3)}));

    final user = await repository.fetchCurrentUser();

    expect(adapter.last.uri.path, '/api/user');
    expect(user.role, 'vendor');
    expect(user.vendorId, 3);
  });
}
