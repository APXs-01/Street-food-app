import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/status_models.dart';
import '../data/status_repository.dart';

final statusRepositoryProvider = Provider<StatusRepository>((ref) => StatusRepository(ref.watch(dioProvider)));

/// The feed: your own posts, your friends' and followed stalls'. Newest first.
final feedProvider = FutureProvider<List<StatusPost>>((ref) async {
  // Nobody signed in (or just signed out): nothing to ask the server for.
  if (ref.watch(signedInUserIdProvider) == null) return const [];

  return ref.watch(statusRepositoryProvider).feed();
});

/// Your own statuses, live and expired (until the daily purge removes them).
final myStatusesProvider = FutureProvider<List<StatusPost>>((ref) async {
  if (ref.watch(signedInUserIdProvider) == null) return const [];

  return ref.watch(statusRepositoryProvider).feed(mine: true);
});

/// One status with its comments.
final statusDetailProvider = FutureProvider.autoDispose.family<StatusPost, int>(
  (ref, id) => ref.watch(statusRepositoryProvider).show(id),
);

/// After posting or deleting a status: reload everything that lists statuses.
void refreshStatuses(WidgetRef ref) {
  ref.invalidate(feedProvider);
  ref.invalidate(myStatusesProvider);
}
