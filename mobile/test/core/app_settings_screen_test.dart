import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/localization/locale_controller.dart';
import 'package:mobile/features/settings/presentation/app_settings_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The settings screen inside a [MaterialApp] wired like `StreetBiteApp`: the
/// locale comes from [localeControllerProvider], so a change redraws it.
class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(localeControllerProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppSettingsScreen(),
    );
  }
}

Future<void> _pumpHost(WidgetTester tester, {Locale? initial}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [if (initial != null) initialLocaleProvider.overrideWithValue(initial)],
      child: const _Host(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    LocaleController.active = kDefaultLocale;
  });

  tearDown(() => LocaleController.active = kDefaultLocale);

  testWidgets('renders in English by default', (tester) async {
    await _pumpHost(tester);

    expect(find.text('App Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('සිංහල'), findsOneWidget);
    expect(find.text('Notification Settings'), findsOneWidget);
    expect(find.text('Privacy Settings'), findsOneWidget);
    // Notification and privacy settings are not built, and say so.
    expect(find.text('Coming soon'), findsNWidgets(2));
  });

  testWidgets('renders in Sinhala when that is the saved language', (tester) async {
    await _pumpHost(tester, initial: const Locale('si'));

    expect(find.text('යෙදුම් සැකසුම්'), findsOneWidget);
    expect(find.text('භාෂාව'), findsOneWidget);
    expect(find.text('දැනුම්දීම් සැකසුම්'), findsOneWidget);
    expect(find.text('රහස්‍යතා සැකසුම්'), findsOneWidget);
    expect(find.text('ඉක්මනින් එනවා'), findsNWidgets(2));
    expect(find.text('App Settings'), findsNothing);
    // Each language keeps its own name whichever one is showing.
    expect(find.text('English'), findsOneWidget);
    expect(find.text('සිංහල'), findsOneWidget);
  });

  testWidgets('tapping සිංහල redraws the screen at once and saves the choice', (tester) async {
    await _pumpHost(tester);

    expect(find.text('App Settings'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    await tester.tap(find.text('සිංහල'));
    await tester.pumpAndSettle();

    expect(find.text('යෙදුම් සැකසුම්'), findsOneWidget);
    expect(find.text('App Settings'), findsNothing);
    expect(LocaleController.active, const Locale('si'));
    expect((await SharedPreferences.getInstance()).getString('app_locale'), 'si');

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('App Settings'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('app_locale'), 'en');
  });

  testWidgets('exactly one language shows as selected', (tester) async {
    await _pumpHost(tester, initial: const Locale('si'));

    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });
}
