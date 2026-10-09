import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/alert_models.dart';
import '../data/alert_repository.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) => AlertRepository(ref.watch(dioProvider)));

/// The signed-in person's notifications, from the server. Read once when first
/// needed and again when a screen invalidates it (pull to refresh, after
/// reading one).
final alertsProvider = FutureProvider<({List<AppAlert> items, int unread})>((ref) async {
  // Nobody signed in (or just signed out): nothing to ask the server for.
  if (ref.watch(signedInUserIdProvider) == null) return (items: const <AppAlert>[], unread: 0);

  return ref.watch(alertRepositoryProvider).list();
});

/// The bell's badge: how many are unread, or 0 while loading or on error (the
/// bell then just shows no badge).
final unreadAlertsProvider = Provider<int>((ref) => ref.watch(alertsProvider).asData?.value.unread ?? 0);
