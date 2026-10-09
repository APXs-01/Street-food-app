import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_role.dart';

/// The three operations the token store needs, so tests can swap in memory.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Keychain on iOS, Keystore-backed storage on Android.
class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// The bearer token and role of the signed-in user.
///
/// The values are also held in memory, which is what the HTTP interceptor
/// reads on every request, so a session that was chosen not to persist
/// ("stay signed in" off) still works until the app closes.
class TokenStorage {
  TokenStorage(this._store);

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';

  final SecureStore _store;

  String? _token;
  UserRole? _role;

  String? get token => _token;
  UserRole? get role => _role;

  /// Read a previously saved session. Unreadable storage counts as no session.
  Future<void> load() async {
    try {
      final token = await _store.read(_tokenKey);
      final role = UserRole.tryParse(await _store.read(_roleKey));

      if (token == null || token.isEmpty || role == null) {
        _token = null;
        _role = null;
        return;
      }

      _token = token;
      _role = role;
    } catch (_) {
      _token = null;
      _role = null;
    }
  }

  /// Keep the session in memory and, when [persist] is true, on the device.
  /// A non-persistent save also removes any older saved session.
  Future<void> save({required String token, required UserRole role, required bool persist}) async {
    _token = token;
    _role = role;

    if (persist) {
      await _store.write(_tokenKey, token);
      await _store.write(_roleKey, role.apiValue);
    } else {
      await _deleteStored();
    }
  }

  Future<void> clear() async {
    _token = null;
    _role = null;
    await _deleteStored();
  }

  Future<void> _deleteStored() async {
    try {
      await _store.delete(_tokenKey);
      await _store.delete(_roleKey);
    } catch (_) {
      // Nothing useful to do: the in-memory session is already gone.
    }
  }
}
