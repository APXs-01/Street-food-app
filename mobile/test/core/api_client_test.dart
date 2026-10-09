import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/core/storage/token_storage.dart';

import '../support/fakes.dart';

void main() {
  late TokenStorage storage;
  late int expiredCalls;
  late RecordingAdapter adapter;
  late Dio dio;

  setUp(() {
    storage = TokenStorage(MemoryStore());
    expiredCalls = 0;
    adapter = RecordingAdapter((_) => jsonResponse(200, {'ok': true}));
    dio = createDio(storage: storage, onUnauthorized: () => expiredCalls++, baseUrl: 'http://test/api')
      ..httpClientAdapter = adapter;
  });

  test('sends the bearer token when a session exists', () async {
    await storage.save(token: 'abc', role: UserRole.consumer, persist: true);

    await dio.get<void>('/user');

    expect(adapter.last.headers['Authorization'], 'Bearer abc');
    expect(adapter.last.uri.toString(), 'http://test/api/user');
  });

  test('sends no Authorization header when signed out', () async {
    await dio.get<void>('/user');

    expect(adapter.last.headers.containsKey('Authorization'), isFalse);
  });

  test('public endpoints never carry the token', () async {
    await storage.save(token: 'abc', role: UserRole.consumer, persist: true);

    await dio.post<void>('/consumer/login', options: Options(extra: {skipAuthKey: true}));

    expect(adapter.last.headers.containsKey('Authorization'), isFalse);
  });

  test('a 401 on an authenticated request clears the session and signs out', () async {
    await storage.save(token: 'abc', role: UserRole.vendor, persist: true);
    adapter = RecordingAdapter((_) => jsonResponse(401, {'message': 'Unauthenticated.'}));
    dio.httpClientAdapter = adapter;

    await expectLater(dio.get<void>('/user'), throwsA(isA<DioException>()));

    expect(storage.token, isNull);
    expect(expiredCalls, 1);
  });

  test('a 401 without a token (a wrong password never gives one) does not sign anyone out', () async {
    adapter = RecordingAdapter((_) => jsonResponse(401, {'message': 'Unauthenticated.'}));
    dio.httpClientAdapter = adapter;

    await expectLater(dio.get<void>('/user'), throwsA(isA<DioException>()));

    expect(expiredCalls, 0);
  });

  test('other errors leave the session alone', () async {
    await storage.save(token: 'abc', role: UserRole.consumer, persist: true);
    adapter = RecordingAdapter((_) => jsonResponse(422, {'message': 'Invalid'}));
    dio.httpClientAdapter = adapter;

    await expectLater(dio.post<void>('/x'), throwsA(isA<DioException>()));

    expect(storage.token, 'abc');
    expect(expiredCalls, 0);
  });
}
