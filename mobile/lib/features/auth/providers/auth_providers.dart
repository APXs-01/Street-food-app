import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/models/user_role.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../data/auth_user.dart';
import 'auth_state.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage(FlutterSecureStore()));

/// The API client. A 401 on an authenticated request signs the user out.
final dioProvider = Provider<Dio>((ref) {
  return createDio(
    storage: ref.watch(tokenStorageProvider),
    onUnauthorized: () => ref.read(authControllerProvider.notifier).sessionExpired(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(dioProvider)));

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// The id of whoever is signed in, or null when nobody is. Providers that hold
/// one person's data (their feed, notifications, friends) watch this, so signing
/// out and in as someone else reloads them instead of showing the last
/// account's data. A saved session the server has not confirmed yet counts as
/// signed in, with id 0: the token is real, so requests already work, and the
/// providers reload once the real id arrives.
final signedInUserIdProvider = Provider<int?>((ref) {
  return ref.watch(authControllerProvider.select((state) => state.session == null ? null : (state.session!.user?.id ?? 0)));
});

/// Holds who is signed in and runs login, register and logout.
///
/// The screens never navigate after a successful login. The router listens to
/// this state and redirects, so there is one place that decides where a signed
/// in user belongs.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  /// Called once before the app starts. Reads a saved session; the server
  /// confirms it in the background, so a saved token never delays start-up.
  Future<void> restoreSession() async {
    final storage = ref.read(tokenStorageProvider);
    await storage.load();

    final role = storage.role;
    if (storage.token == null || role == null) return;

    state = AuthState(session: AuthSession(role: role));

    // In the background: start-up never waits on the server. A failure here
    // (offline, server down) keeps the saved session; a 401 has already signed
    // the user out through the interceptor.
    unawaited(ensureConfirmed().then<void>((_) {}, onError: (Object _) {}));
  }

  /// The one in-flight `GET /user` for a saved session, shared by everyone who
  /// asks for the confirmed user while it runs.
  Future<AuthUser>? _confirming;

  /// The signed-in user as the server confirms them. If the session was
  /// restored from a saved token the user is not known yet; this fetches it
  /// once, however many callers ask at the same time, and puts it in the state.
  /// Throws an [ApiFailure] if nobody is signed in or the server cannot confirm.
  Future<AuthUser> ensureConfirmed() {
    final session = state.session;

    if (session == null) return Future.error(ApiFailure.signInAgain());

    final known = session.user;
    if (known != null) return Future.value(known);

    return _confirming ??= _confirmSession().whenComplete(() => _confirming = null);
  }

  Future<AuthUser> _confirmSession() async {
    final user = await ref.read(authRepositoryProvider).fetchCurrentUser();
    final role = UserRole.tryParse(user.role);

    // Signed out, or signed in again with a user already, while this was running.
    final session = state.session;
    if (session == null) throw ApiFailure.signInAgain();
    if (session.user != null) return session.user!;

    if (role == null) {
      await _endSession();
      throw ApiFailure.accountNotSupported();
    }

    state = state.copyWith(session: AuthSession(role: role, user: user));

    return user;
  }

  /// Returns null on success, or what went wrong. [staySignedIn] false keeps the
  /// session in memory only, so it ends when the app closes.
  Future<ApiFailure?> login({
    required UserRole role,
    required String identifier,
    required String password,
    bool staySignedIn = true,
  }) {
    return _authenticate(
      role,
      staySignedIn,
      () => ref.read(authRepositoryProvider).login(role: role, identifier: identifier, password: password),
    );
  }

  Future<ApiFailure?> register({
    required UserRole role,
    required String name,
    required String identifier,
    required String password,
    required String passwordConfirmation,
    required bool acceptedTerms,
  }) {
    return _authenticate(
      role,
      true,
      () => ref.read(authRepositoryProvider).register(
            role: role,
            name: name,
            identifier: identifier,
            password: password,
            passwordConfirmation: passwordConfirmation,
            acceptedTerms: acceptedTerms,
          ),
    );
  }

  Future<ApiFailure?> _authenticate(
    UserRole expected,
    bool persist,
    Future<AuthResult> Function() request,
  ) async {
    state = state.copyWith(isSubmitting: true);

    ApiFailure? failure;

    try {
      final result = await request();
      final role = UserRole.tryParse(result.user.role);

      if (role == null || role != expected) {
        failure = ApiFailure.accountNotSupported();
      } else {
        await ref.read(tokenStorageProvider).save(token: result.token, role: role, persist: persist);
        state = AuthState(session: AuthSession(role: role, user: result.user));

        return null;
      }
    } on ApiFailure catch (error) {
      failure = error;
    } catch (_) {
      failure = ApiFailure.sessionNotSaved();
    }

    state = state.copyWith(isSubmitting: false);

    return failure;
  }

  /// The vendor has a stall now (just created, or already existed). Records its
  /// id on the signed-in user, which is what moves the router from stall
  /// onboarding to the vendor home.
  Future<void> stallRegistered(int vendorId) async {
    final session = state.session;
    if (session == null) return;

    final user = session.user;

    if (user != null) {
      state = state.copyWith(session: AuthSession(role: session.role, user: user.copyWith(vendorId: vendorId)));
    } else {
      // Not confirmed with the server yet; GET /user now carries the vendor_id.
      try {
        await ensureConfirmed();
      } on ApiFailure {
        // Offline: the router will pick the stall up when the user is confirmed.
      }
    }
  }

  /// Best effort on the server (the token may already be dead), certain on the device.
  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } on ApiFailure {
      // Signing out locally is what matters.
    }

    await _endSession();
  }

  Future<void> _endSession() async {
    _confirming = null;
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState();
  }

  /// The API rejected our token. The interceptor has already cleared storage.
  void sessionExpired() {
    state = const AuthState();
  }
}
