import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';

/// What the login and sign-up screens share: validating, sending, and showing
/// what came back.
///
/// Flow of [submitForm]:
///  1. validation errors appear under the fields (and keep updating as the
///     person types, once they have tried to submit);
///  2. the request runs; the button is disabled by AuthState.isSubmitting;
///  3. on success nothing happens here: the router sees the new session and
///     moves the person to their home screen;
///  4. on failure, a server message for one field appears under that field,
///     and anything else appears as a banner.
mixin AuthFormMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;

  /// The last failed request, until the person changes the field it points at.
  ApiFailure? failure;

  /// The server's message for the first of [fields] it complained about.
  String? serverError(List<String> fields) {
    final errors = failure?.fieldErrors;
    if (errors == null) return null;

    for (final field in fields) {
      final message = errors[field];
      if (message != null) return message;
    }

    return null;
  }

  /// Call from a field's onChanged: editing a field withdraws the server's
  /// complaint about it.
  void clearServerError(List<String> fields) {
    final current = failure;
    if (current == null || !fields.any(current.fieldErrors.containsKey)) return;

    setState(() => failure = current.withoutFields(fields));
  }

  /// The message for the banner: only failures that do not belong to a field.
  String? get bannerMessage {
    final current = failure;
    if (current == null || current.hasFieldErrors) return null;

    return current.message;
  }

  /// [extraValidation] checks anything that is not a text field (the terms
  /// checkbox); it runs even when the fields are invalid, so every problem is
  /// shown at once.
  Future<void> submitForm(
    Future<ApiFailure?> Function() request, {
    bool Function()? extraValidation,
  }) async {
    FocusScope.of(context).unfocus();

    setState(() => autovalidateMode = AutovalidateMode.onUserInteraction);

    final fieldsValid = formKey.currentState!.validate();
    final extraValid = extraValidation?.call() ?? true;

    if (!fieldsValid || !extraValid) return;

    setState(() => failure = null);

    final result = await request();

    // A successful sign-in replaces this screen, so it may already be gone.
    if (!mounted) return;

    if (result != null) setState(() => failure = result);
  }
}
