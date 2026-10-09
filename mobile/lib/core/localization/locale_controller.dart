import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The languages the app is translated into, by language code.
const List<Locale> kSupportedLocales = [Locale('en'), Locale('si')];

/// The language shown when nothing has been chosen yet.
const Locale kDefaultLocale = Locale('en');

/// The language the person picked, kept on this device. A display preference,
/// not a secret, so it lives in plain shared preferences rather than the secure
/// store the sign-in token uses.
const String kLocalePrefsKey = 'app_locale';

/// The locale the app was started with. `main()` reads the saved choice before
/// the first frame and overrides this; tests leave it at English.
final initialLocaleProvider = Provider<Locale>((ref) => kDefaultLocale);

/// Holds the app's language and saves it when it changes. [MaterialApp] watches
/// it, so changing the language redraws every screen at once, with no restart.
class LocaleController extends Notifier<Locale> {
  /// The language in use right now, for code that has no [BuildContext] (error
  /// messages, validators, labels built in models). Kept in step with [state].
  static Locale active = kDefaultLocale;

  /// The saved language, or [kDefaultLocale] if none was saved or it is one the
  /// app no longer ships.
  static Future<Locale> loadSaved() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final code = preferences.getString(kLocalePrefsKey);

      return kSupportedLocales.firstWhere((locale) => locale.languageCode == code, orElse: () => kDefaultLocale);
    } catch (_) {
      // Preferences can be unavailable (a locked or cleared store): English is fine.
      return kDefaultLocale;
    }
  }

  @override
  Locale build() {
    final initial = ref.watch(initialLocaleProvider);
    active = initial;

    return initial;
  }

  /// Switches the language now and saves the choice. A language the app does not
  /// ship is ignored. The switch does not wait for the save, and a failed save
  /// only means the choice is forgotten at the next start.
  Future<void> setLocale(Locale locale) async {
    if (!kSupportedLocales.any((supported) => supported.languageCode == locale.languageCode)) return;

    final next = Locale(locale.languageCode);

    active = next;
    state = next;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(kLocalePrefsKey, next.languageCode);
    } catch (_) {
      // Not saved; see above.
    }
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
