import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/models/user_role.dart';
import 'auth_user.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

/// The auth endpoints, exactly as the backend defines them (docs/API.md):
///
///   POST /{role}/login     { login, password }              -> { token, user }
///   POST /{role}/register  { name, email | phone, password,
///                            password_confirmation, terms } -> { token, user }
///   GET  /user                                              -> { data: user }
///   POST /logout
///
/// `login` and the register identifier are one field in the UI ("email or
/// mobile"); the server wants login as `login` and register as `email` or
/// `phone`, so register splits it on the presence of an `@`.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  static Options get _public => Options(extra: {skipAuthKey: true});

  Future<AuthResult> login({
    required UserRole role,
    required String identifier,
    required String password,
  }) {
    return _authenticate('/${role.apiValue}/login', {
      'login': identifier.trim(),
      'password': password,
    });
  }

  Future<AuthResult> register({
    required UserRole role,
    required String name,
    required String identifier,
    required String password,
    required String passwordConfirmation,
    required bool acceptedTerms,
  }) {
    final contact = identifier.trim();

    return _authenticate('/${role.apiValue}/register', {
      'name': name.trim(),
      if (contact.contains('@')) 'email': contact else 'phone': contact,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'terms': acceptedTerms,
    });
  }

  Future<AuthUser> fetchCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/user');

      return AuthUser.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } catch (error) {
      if (error is TypeError || error is FormatException) throw _unexpected;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/logout');
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  Future<AuthResult> _authenticate(String path, Map<String, Object?> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body, options: _public);
      final data = response.data!;

      return AuthResult(
        token: data['token'] as String,
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } catch (error) {
      if (error is TypeError || error is FormatException) throw _unexpected;
      rethrow;
    }
  }

  static ApiFailure get _unexpected => ApiFailure.unexpectedResponse();
}
