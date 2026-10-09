import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/friend_repository.dart';
import '../data/social_models.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) => FriendRepository(ref.watch(dioProvider)));

/// Accepted friends.
final friendsProvider = FutureProvider<List<Friendship>>((ref) async {
  if (ref.watch(signedInUserIdProvider) == null) return const [];

  return ref.watch(friendRepositoryProvider).friends();
});

/// Requests waiting for the signed-in customer.
final friendRequestsProvider = FutureProvider<List<Friendship>>((ref) async {
  if (ref.watch(signedInUserIdProvider) == null) return const [];

  return ref.watch(friendRepositoryProvider).requests();
});

/// After accepting, declining, adding or removing: reload both lists.
void refreshFriends(WidgetRef ref) {
  ref.invalidate(friendsProvider);
  ref.invalidate(friendRequestsProvider);
}

/// Which stalls this customer follows, as far as this run knows. The API only
/// reports it per stall (`followed_by_me` on `GET /vendors/{id}`), so this holds
/// the answers the app has seen or changed.
class FollowedStallsNotifier extends Notifier<Map<int, bool>> {
  @override
  Map<int, bool> build() {
    // Starts empty again for whoever signs in next.
    ref.watch(signedInUserIdProvider);

    return const {};
  }

  void remember(int stallId, bool following) => state = {...state, stallId: following};

  /// Follows or unfollows on the server, and remembers the new answer.
  Future<void> setFollowing(int stallId, {required bool follow, required Future<void> Function() send}) async {
    final before = state[stallId];

    // Show the change at once; put it back if the server says no.
    remember(stallId, follow);

    try {
      await send();
    } catch (_) {
      if (before == null) {
        state = {...state}..remove(stallId);
      } else {
        remember(stallId, before);
      }

      rethrow;
    }
  }
}

final followedStallsProvider = NotifierProvider<FollowedStallsNotifier, Map<int, bool>>(FollowedStallsNotifier.new);
