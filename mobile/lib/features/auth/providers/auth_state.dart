import '../../../core/models/user_role.dart';
import '../data/auth_user.dart';

/// A signed-in user. [user] is null right after the app starts with a saved
/// token, until GET /user has confirmed it.
class AuthSession {
  const AuthSession({required this.role, this.user});

  final UserRole role;
  final AuthUser? user;
}

class AuthState {
  const AuthState({this.session, this.isSubmitting = false});

  /// Null means signed out.
  final AuthSession? session;

  /// A login or register request is in flight.
  final bool isSubmitting;

  bool get isAuthenticated => session != null;

  AuthState copyWith({AuthSession? session, bool? isSubmitting}) {
    return AuthState(
      session: session ?? this.session,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
