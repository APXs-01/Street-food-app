import 'package:dio/dio.dart';

import '../brand.dart';
import '../localization/l10n.dart';

/// A failed API call, reduced to what the UI needs.
///
/// Backend error shapes (docs/API.md):
///   422 `{ message, errors: { field: [messages] } }`
///   403 `{ message }`, and `role` when the account belongs to another role
///   401 `{ message }`
///   429 `{ message }` (auth routes allow 5 attempts a minute)
class ApiFailure implements Exception {
  const ApiFailure({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.role,
    this.vendorId,
    this.code,
  });

  /// A vendor who has no stall yet (the screens offer stall setup).
  static const String codeNoStall = 'no_stall';

  /// Safe to show to the user as it is. Messages the app writes itself are in the
  /// language in use when the failure happened; the server's own messages are
  /// shown as the server sent them.
  final String message;

  /// Set for a few failures the app itself raises and a screen reacts to.
  final String? code;
  final int? statusCode;

  /// The first message for each field the server rejected, keyed by the
  /// request field name (`login`, `email`, `phone`, `password`, `terms`...).
  final Map<String, String> fieldErrors;

  /// Set on a wrong-role login: the role the account really has.
  final String? role;

  /// Set on the 409 for a vendor who already has a stall: that stall's id.
  final int? vendorId;

  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  /// The same failure without the errors for [keys], used once the user edits
  /// those fields.
  ApiFailure withoutFields(Iterable<String> keys) {
    final remaining = Map<String, String>.of(fieldErrors)..removeWhere((key, _) => keys.contains(key));

    return ApiFailure(
      message: message,
      statusCode: statusCode,
      fieldErrors: remaining,
      role: role,
      vendorId: vendorId,
      code: code,
    );
  }

  /// Nobody is signed in, or the session ended.
  factory ApiFailure.signInAgain() => ApiFailure(message: l10n.errorSignInAgain);

  /// The server answered with something the app could not make sense of.
  factory ApiFailure.unexpectedResponse() => ApiFailure(message: l10n.errorUnexpectedResponse);

  /// A vendor who has not set up a stall.
  factory ApiFailure.noStall() => ApiFailure(message: l10n.errorNoStall, code: codeNoStall);

  /// The account is of a kind this app does not serve.
  factory ApiFailure.accountNotSupported() => ApiFailure(message: l10n.errorAccountNotSupported(kBrandName));

  /// The session could not be written to the device's secure store.
  factory ApiFailure.sessionNotSaved() => ApiFailure(message: l10n.errorSessionNotSaved);

  factory ApiFailure.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiFailure(message: l10n.errorOffline(kBrandName));
      case DioExceptionType.badResponse:
        return ApiFailure.fromResponse(error.response);
      default:
        // A reply arrived but could not be decoded (for example PHP printed a
        // warning in front of the JSON): say so, rather than a blank "went wrong".
        if (error.response != null) return ApiFailure(message: l10n.errorUnreadable);

        return ApiFailure(message: l10n.errorGeneric);
    }
  }

  factory ApiFailure.fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final data = response?.data;

    final fieldErrors = <String, String>{};
    String? message;
    String? role;
    int? vendorId;

    if (data is Map) {
      final rawMessage = data['message'];
      if (rawMessage is String && rawMessage.isNotEmpty) message = rawMessage;

      final rawRole = data['role'];
      if (rawRole is String) role = rawRole;

      final rawVendorId = data['vendor_id'];
      if (rawVendorId is int) vendorId = rawVendorId;

      final errors = data['errors'];
      if (errors is Map) {
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty && value.first is String) {
            fieldErrors[key.toString()] = value.first as String;
          }
        });
      }
    }

    if (status == 429) {
      message = l10n.errorTooManyAttempts;
    } else if (status != null && status >= 500) {
      message = l10n.errorServer;
    } else if (status == 422 && fieldErrors.isNotEmpty) {
      // Laravel's own 422 message is a generic "The given data was invalid."
      message = fieldErrors.values.first;
    }

    return ApiFailure(
      message: message ?? l10n.errorGeneric,
      statusCode: status,
      fieldErrors: fieldErrors,
      role: role,
      vendorId: vendorId,
    );
  }

  @override
  String toString() => 'ApiFailure($statusCode): $message';
}
