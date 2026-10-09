import '../../../core/localization/l10n.dart';

/// Client-side checks for the auth forms. They match what the backend will
/// accept, so a person sees the problem before a request is sent; the server
/// still has the final say and its messages are shown when it disagrees. The
/// messages are in the language the app is showing.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Separators people type inside phone numbers.
  static final RegExp _phoneSeparators = RegExp(r'[\s\-().]');

  /// 9 to 15 digits, optionally with a leading +. The server normalises local
  /// forms such as 077 123 4567 to +94771234567.
  static final RegExp _phone = RegExp(r'^\+?\d{9,15}$');

  static const int minPasswordLength = 8;

  /// "[label] is required." for an empty value. [label] is already in the
  /// language in use.
  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return l10n.validationRequired(label);
    return null;
  }

  static String? fullName(String? value) => required(value, l10n.validationLabelFullName);

  /// Whether [value] is a mobile number (not an email) that passes the same
  /// check as [emailOrMobile]. Drives the "SMS Ready" badge.
  static bool looksLikeMobile(String? value) {
    final text = (value ?? '').trim();

    return text.isNotEmpty && !text.contains('@') && _phone.hasMatch(text.replaceAll(_phoneSeparators, ''));
  }

  /// Accepts an email address or a mobile number, in one field.
  static String? emailOrMobile(String? value) {
    final missing = required(value, l10n.validationLabelEmailOrMobile);
    if (missing != null) return missing;

    final text = value!.trim();

    if (text.contains('@')) {
      return _email.hasMatch(text) ? null : l10n.validationInvalidEmail;
    }

    return _phone.hasMatch(text.replaceAll(_phoneSeparators, '')) ? null : l10n.validationInvalidEmailOrMobile;
  }

  /// For sign-in, where only presence is checked; use [newPassword] when
  /// creating one.
  static String? password(String? value) => required(value, l10n.validationLabelPassword);

  static String? newPassword(String? value) {
    final missing = required(value, l10n.validationLabelPassword);
    if (missing != null) return missing;

    if (value!.length < minPasswordLength) {
      return l10n.validationPasswordTooShort(minPasswordLength);
    }

    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final missing = required(value, l10n.validationLabelConfirmPassword);
    if (missing != null) return missing;

    return value == original ? null : l10n.validationPasswordsMismatch;
  }
}
