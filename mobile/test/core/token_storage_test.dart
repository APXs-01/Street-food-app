import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/core/storage/token_storage.dart';

import '../support/fakes.dart';

void main() {
  test('a persisted session survives a restart', () async {
    final store = MemoryStore();
    await TokenStorage(store).save(token: 'abc', role: UserRole.vendor, persist: true);

    final restarted = TokenStorage(store);
    await restarted.load();

    expect(restarted.token, 'abc');
    expect(restarted.role, UserRole.vendor);
  });

  test('a session that is not persisted works now but is gone after a restart', () async {
    final store = MemoryStore();
    final storage = TokenStorage(store);
    await storage.save(token: 'abc', role: UserRole.consumer, persist: false);

    expect(storage.token, 'abc');
    expect(store.values, isEmpty);

    final restarted = TokenStorage(store);
    await restarted.load();

    expect(restarted.token, isNull);
  });

  test('saving without persisting also removes an older saved session', () async {
    final store = MemoryStore();
    final storage = TokenStorage(store);
    await storage.save(token: 'old', role: UserRole.consumer, persist: true);

    await storage.save(token: 'new', role: UserRole.consumer, persist: false);

    expect(store.values, isEmpty);
  });

  test('clear removes the session from memory and the device', () async {
    final store = MemoryStore();
    final storage = TokenStorage(store);
    await storage.save(token: 'abc', role: UserRole.consumer, persist: true);

    await storage.clear();

    expect(storage.token, isNull);
    expect(storage.role, isNull);
    expect(store.values, isEmpty);
  });

  test('a token with an unknown role is not a session', () async {
    final store = MemoryStore()
      ..values['auth_token'] = 'abc'
      ..values['auth_role'] = 'inspector';
    final storage = TokenStorage(store);

    await storage.load();

    expect(storage.token, isNull);
  });
}
