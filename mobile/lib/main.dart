import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/localization/locale_controller.dart';
import 'features/auth/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read the saved language and session before the first frame, so the first
  // screen is already in the right language and the router starts on the right
  // screen: role select when signed out, the role's home when signed in.
  final locale = await LocaleController.loadSaved();
  final container = ProviderContainer(overrides: [initialLocaleProvider.overrideWithValue(locale)]);
  await container.read(authControllerProvider.notifier).restoreSession();

  runApp(UncontrolledProviderScope(container: container, child: const StreetBiteApp()));
}
