import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';

/// The answer for everything that is designed but not built yet (Google sign-in,
/// forgot password, SMS codes, legal pages). It says so instead of pretending.
/// [feature] is the name of the thing, already in the language in use.
void showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.l10n.commonComingSoon(feature))));
}
