import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'locale_controller.dart';

export '../../l10n/app_localizations.dart';

/// The strings in the language the app is showing now, for code that has no
/// [BuildContext]: error messages, validators, labels built inside models. The
/// app redraws completely when the language changes (see `StreetBiteApp`), so a
/// string read this way is never left in the old language on screen.
AppLocalizations get l10n => lookupAppLocalizations(LocaleController.active);

extension L10nBuildContext on BuildContext {
  /// The strings for this part of the widget tree's locale.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
