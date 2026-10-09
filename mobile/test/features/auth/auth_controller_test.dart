import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_failure.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_user.dart';
import 'package:mobile/features/auth/providers/auth_providers.dart';
import 'package:mobile/features/auth/providers/auth_state.dart';

import '../../support/fakes.dart';

/// Answers `GET /user` only when the test lets it, so a test can hold the
/// request open and ask for the confirmed user from several places meanwhile.
class _SlowRepository extends FakeAuthRepository {
  _SlowRepository(this.gate);

  final Completer<AuthUser> gate;

  @override
  Future<AuthUser> fetchCurrentUser() {
    fetchCalls++;

    return gate.future;
  }
}

void main() {
  late MemoryStore store;
  late FakeAuthRepository repository;
  late ProviderContainer container;

  AuthController controller() => container.read(authControllerProvider.notifier);
  AuthState state() => container.read(authControllerProvider);

  setUp(() {
    store = MemoryStore();
    repository = FakeAuthRepository();
    container = ProviderContainer(overrides: [
      tokenStorageProvider.overrideWithValue(TokenStorage(store)),
      authRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
  });

  group('login', () {
    test('a successful login stores the token and role and signs the user in', () async {
      final failure = await controller().login(role: UserRole.consumer, identifier: 'a@b.co', password: 'x');

      expect(failure, isNull);
      expect(state().role, UserRole.consumer);
      expect(state().userName, 'Maya Chen');
      expect(state().isSubmitting, isFalse);
      expect(store.values['auth_token'], 'token-1');
      expect(store.values['auth_role'], 'consumer');
    });

    test('without "stay signed in" the session lives in memory only', () async {
      repository.loggedInUser = sampleUser(role: 'vendor');

      await controller().login(role: UserRole.vendor, identifier: 'a@b.co', password: 'x', staySignedIn: false);

      expect(state().role, UserRole.vendor);
      expect(store.values, isEmpty);
    });

    test('a failed login returns the failure and stays signed out', () async {
      repository.loginFailure = const ApiFailure(message: 'nope', statusCode: 422, fieldErrors: {'login': 'nope'});

      final failure = await controller().login(role: UserRole.consumer, identifier: 'a@b.co', password: 'x');

      expect(failure?.fieldErrors['login'], 'nope');
      expect(state().role, isNull);
      expect(state().isSubmitting, isFalse);
      expect(store.values, isEmpty);
    });

    test('an account of a different role is refused even if the server accepted it', () async {
      repository.loggedInUser = sampleUser(role: 'vendor');

      final failure = await controller().login(role: UserRole.consumer, identifier: 'a@b.co', password: 'x');

      expect(failure, isNotNull);
      expect(state().role, isNull);
      expect(store.values, isEmpty);
    });

    test('a role the app does not support is refused', () async {
      repository.loggedInUser = sampleUser(role: 'super_admin');

      final failure = await controller().login(role: UserRole.consumer, identifier: 'a@b.co', password: 'x');

      expect(failure, isNotNull);
      expect(state().role, isNull);
    });
  });

  test('register signs the new user in', () async {
    repository.loggedInUser = sampleUser(role: 'vendor');

    final failure = await controller().register(
      role: UserRole.vendor,
      name: 'Raju',
      identifier: 'raju@example.com',
      password: 'secret123',
      passwordConfirmation: 'secret123',
      acceptedTerms: true,
    );

    expect(failure, isNull);
    expect(state().role, UserRole.vendor);
    expect(store.values['auth_token'], 'token-2');
  });

  group('restoreSession', () {
    test('a saved session is restored and then confirmed with the server', () async {
      store.values
        ..['auth_token'] = 'saved'
        ..['auth_role'] = 'consumer';

      await controller().restoreSession();

      expect(state().role, UserRole.consumer);
      expect(state().userName, isNull);

      await pumpEventQueue();

      expect(repository.fetchCalls, 1);
      expect(state().userName, 'Maya Chen');
    });

    test('with nothing saved the user is signed out', () async {
      await controller().restoreSession();

      expect(state().role, isNull);
      expect(repository.fetchCalls, 0);
    });

    test('being offline keeps the saved session', () async {
      store.values
        ..['auth_token'] = 'saved'
        ..['auth_role'] = 'vendor';
      repository.fetchFailure = const ApiFailure(message: 'offline');

      await controller().restoreSession();
      await pumpEventQueue();

      expect(state().role, UserRole.vendor);
    });
  });

  group('ensureConfirmed', () {
    test('callers who ask while the saved session is being confirmed share one GET /user', () async {
      final gate = Completer<AuthUser>();
      final slow = _SlowRepository(gate);

      container.dispose();
      container = ProviderContainer(overrides: [
        tokenStorageProvider.overrideWithValue(TokenStorage(store)),
        authRepositoryProvider.overrideWithValue(slow),
      ]);
      addTearDown(container.dispose);

      store.values
        ..['auth_token'] = 'saved'
        ..['auth_role'] = 'vendor';

      await controller().restoreSession();
      await pumpEventQueue();

      // restoreSession started the request in the background.
      expect(slow.fetchCalls, 1);

      final first = controller().ensureConfirmed();
      final second = controller().ensureConfirmed();

      expect(identical(first, second), isTrue);
      expect(slow.fetchCalls, 1);

      gate.complete(sampleUser(role: 'vendor', vendorId: 5));

      expect((await first).vendorId, 5);
      expect(slow.fetchCalls, 1);
      expect(state().session?.user?.vendorId, 5);

      // Once confirmed, nobody asks the server again.
      expect((await controller().ensureConfirmed()).vendorId, 5);
      expect(slow.fetchCalls, 1);
    });

    test('an unreachable server is an error, and the next call tries again', () async {
      store.values
        ..['auth_token'] = 'saved'
        ..['auth_role'] = 'vendor';
      repository.fetchFailure = const ApiFailure(message: 'offline');

      await controller().restoreSession();
      await pumpEventQueue();

      await expectLater(controller().ensureConfirmed(), throwsA(isA<ApiFailure>()));
      expect(state().session?.user, isNull);

      repository.fetchFailure = null;
      repository.currentUser = sampleUser(role: 'vendor', vendorId: 9);

      expect((await controller().ensureConfirmed()).vendorId, 9);
    });

    test('nobody signed in is an error, not a request', () async {
      await expectLater(controller().ensureConfirmed(), throwsA(isA<ApiFailure>()));
      expect(repository.fetchCalls, 0);
    });
  });

  group('stallRegistered', () {
    test('records the new stall on the signed-in vendor', () async {
      repository.loggedInUser = sampleUser(role: 'vendor');
      await controller().login(role: UserRole.vendor, identifier: 'a@b.co', password: 'x');
      expect(state().session?.user?.vendorId, isNull);

      await controller().stallRegistered(12);

      expect(state().session?.user?.vendorId, 12);
      expect(state().session?.user?.name, 'Maya Chen');
      expect(state().role, UserRole.vendor);
    });

    test('does nothing when nobody is signed in', () async {
      await controller().stallRegistered(12);

      expect(state().role, isNull);
    });

    test('with a saved session the server has not confirmed yet, asks the server instead', () async {
      store.values
        ..['auth_token'] = 'saved'
        ..['auth_role'] = 'vendor';
      repository.currentUser = sampleUser(role: 'vendor', vendorId: 9);
      repository.fetchFailure = const ApiFailure(message: 'offline');

      await controller().restoreSession();
      await pumpEventQueue();
      expect(state().session?.user, isNull);

      repository.fetchFailure = null;
      await controller().stallRegistered(9);

      expect(state().session?.user?.vendorId, 9);
    });
  });

  test('sessionExpired signs the user out', () async {
    await controller().login(role: UserRole.consumer, identifier: 'a@b.co', password: 'x');

    controller().sessionExpired();

    expect(state().role, isNull);
  });

  group('logout', () {
    test('tells the server and clears the device', () async {
      await controller().login(role: UserRole.consumer, identifier: 'a@b.co', password: 'x');

      await controller().logout();

      expect(repository.logoutCalls, 1);
      expect(state().role, isNull);
      expect(store.values, isEmpty);
    });

    test('still signs out on the device when the server cannot be reached', () async {
      await controller().login(role: UserRole.consumer, identifier: 'a@b.co', password: 'x');
      repository.logoutFailure = const ApiFailure(message: 'offline');

      await controller().logout();

      expect(state().role, isNull);
      expect(store.values, isEmpty);
    });
  });
}

/// The two fields these tests look at, so assertions read plainly.
extension on AuthState {
  UserRole? get role => session?.role;
  String? get userName => session?.user?.name;
}
