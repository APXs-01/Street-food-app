import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';

/// Set in a request's `extra` for the public endpoints (login, register): no
/// bearer token is attached, and a 401 does not end a session.
const String skipAuthKey = 'skipAuth';

abstract final class ApiConfig {
  /// Override for a real device or a deployed server:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api`
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    // The Android emulator reaches the host machine at 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }

    return 'http://localhost:8000/api';
  }

  static const _loopbackHosts = {'localhost', '127.0.0.1', '0.0.0.0', '::1'};

  /// A photo URL the phone can actually open. The server builds media URLs from
  /// its own `APP_URL` (`http://localhost:8000/...`), and "localhost" on an
  /// emulator or phone is the phone itself, so such a URL points at the same
  /// host as the API instead. Any other host is left alone.
  static String resolveMedia(String url, {String? apiBaseUrl}) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || !_loopbackHosts.contains(uri.host)) return url;

    final base = Uri.parse(apiBaseUrl ?? baseUrl);

    return uri.replace(scheme: base.scheme, host: base.host, port: base.hasPort ? base.port : null).toString();
  }
}

/// A Dio configured for the StreetBite API.
///
/// - Sends `Authorization: Bearer <token>` when a session exists.
/// - On a 401 for a request that carried a token, clears the stored session and
///   calls [onUnauthorized], which signs the user out so the router sends them
///   back to role select.
Dio createDio({
  required TokenStorage storage,
  required void Function() onUnauthorized,
  String? baseUrl,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      headers: {Headers.acceptHeader: Headers.jsonContentType},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = storage.token;
        if (options.extra[skipAuthKey] != true && token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final carriedToken = error.requestOptions.headers.containsKey('Authorization');

        if (error.response?.statusCode == 401 && carriedToken) {
          await storage.clear();
          onUnauthorized();
        }

        handler.next(error);
      },
    ),
  );

  return dio;
}
