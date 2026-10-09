import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../auth/providers/auth_providers.dart';
import '../../consumer/data/discovery_stall.dart';
import '../../consumer/data/stall_detail_models.dart';
import '../../consumer/providers/discovery_providers.dart';
import '../../statuses/data/status_models.dart';
import '../../statuses/providers/status_providers.dart';
import '../data/vendor_models.dart';
import '../data/vendor_repository.dart';

final vendorRepositoryProvider = Provider<VendorRepository>(
  (ref) => VendorRepository(ref.watch(dioProvider), ref.watch(stallRepositoryProvider)),
);

/// The signed-in vendor's own stall id (`user.vendor_id`), or null before they
/// have onboarded.
final vendorIdProvider = Provider<int?>((ref) => ref.watch(authControllerProvider.select((state) => state.session?.user?.vendorId)));

/// The vendor's stall id. For a saved session the server has not confirmed yet
/// (no user loaded) this waits on the auth controller's single shared
/// `GET /user` ([AuthController.ensureConfirmed]), never a request of its own,
/// so the two cannot race. An unreachable server surfaces as a real error with
/// Try again; a confirmed vendor with no stall gets [ApiFailure.noStall].
Future<int> _vendorIdOrWait(Ref ref) async {
  final id = ref.watch(vendorIdProvider);
  if (id != null) return id;

  if (ref.watch(signedInUserIdProvider) == null) throw ApiFailure.signInAgain();

  final user = await ref.read(authControllerProvider.notifier).ensureConfirmed();
  if (user.vendorId != null) return user.vendorId!;

  throw ApiFailure.noStall();
}

/// The signed-in vendor's own stall, from `GET /vendors/{vendor_id}`: the single
/// place the vendor side learns its stall's name, photo, hygiene, hours and
/// open/closed state. It also does the writes that change those (the live
/// switch and the hours), taking the server's answer as the new state.
class VendorStallNotifier extends AsyncNotifier<DiscoveryStall> {
  @override
  Future<DiscoveryStall> build() async {
    final id = await _vendorIdOrWait(ref);

    return ref.watch(vendorRepositoryProvider).stall(id);
  }

  int get _id => state.requireValue.id;

  /// Opens or closes the stall. Throws the server's [ApiFailure] if it refuses.
  Future<void> setOpen(bool open) async {
    final stall = await ref.read(vendorRepositoryProvider).setOpen(_id, open: open);

    state = AsyncData(stall);
  }

  /// Sets the daily hours, keeping the open days.
  Future<void> setHours({required TimeOfDay opens, required TimeOfDay closes}) async {
    final current = state.requireValue;
    final stall = await ref.read(vendorRepositoryProvider).setHours(current.id, opens: opens, closes: closes, openDays: current.openDays);

    state = AsyncData(stall);
  }

  /// Puts the menu the menu provider just loaded or changed on the stall.
  void useMenu(List<StallMenuItem> menu) {
    final current = state.asData?.value;
    if (current != null) state = AsyncData(current.copyWith(menu: menu));
  }
}

final vendorStallProvider = AsyncNotifierProvider<VendorStallNotifier, DiscoveryStall>(VendorStallNotifier.new);

/// The vendor's menu, from `GET /menu-items`, with the writes: add, edit, sold
/// out, fresh today, delete. Each takes the server's answer.
class VendorMenuNotifier extends AsyncNotifier<List<StallMenuItem>> {
  @override
  Future<List<StallMenuItem>> build() async {
    // The menu belongs to this vendor's stall. `/menu-items` is scoped to the
    // signed-in owner on the server, so it would answer without the id, but
    // asking before the stall is known only repeats requests (and fails for a
    // vendor with no stall). Waiting on the same id as the stall keeps all the
    // vendor providers reloading together when the account changes.
    await _vendorIdOrWait(ref);

    return ref.watch(vendorRepositoryProvider).menu();
  }

  VendorRepository get _repo => ref.read(vendorRepositoryProvider);

  List<StallMenuItem> get _items => state.value ?? const [];

  Future<void> add(String name, double price, {bool soldOut = false}) async {
    final item = await _repo.addMenuItem(name: name, price: price, available: !soldOut);

    state = AsyncData([..._items, item]);
  }

  Future<void> edit(int id, {required String name, required double price, required bool soldOut}) async {
    final item = await _repo.updateMenuItem(id, name: name, price: price, isAvailable: !soldOut);

    state = AsyncData([for (final existing in _items) if (existing.id == id) item else existing]);
  }

  /// "Fresh today". A sold-out dish cannot be switched on.
  Future<void> toggleFresh(int id) async {
    final existing = _items.where((item) => item.id == id).firstOrNull;
    if (existing == null || !existing.isAvailable) return;

    final item = await _repo.updateMenuItem(id, freshToday: !existing.isFreshToday);

    state = AsyncData([for (final candidate in _items) if (candidate.id == id) item else candidate]);
  }

  Future<void> remove(int id) async {
    await _repo.deleteMenuItem(id);

    state = AsyncData(_items.where((item) => item.id != id).toList());
  }
}

final vendorMenuProvider = AsyncNotifierProvider<VendorMenuNotifier, List<StallMenuItem>>(VendorMenuNotifier.new);

/// The Analytics screen's figures, from `GET /vendors/{id}/analytics`. A 403
/// "feature unavailable" (the `vendor.analytics` kill-switch) arrives as the error.
final vendorAnalyticsProvider = FutureProvider.autoDispose<VendorAnalytics>((ref) async {
  final id = await _vendorIdOrWait(ref);

  return ref.watch(vendorRepositoryProvider).analytics(id);
});

/// The first page of reviews of the vendor's own stall.
final vendorReviewsProvider = FutureProvider.autoDispose<ReviewsPage>((ref) async {
  final id = await _vendorIdOrWait(ref);

  return ref.watch(stallRepositoryProvider).reviews(id);
});

/// The vendor's own statuses that are still live, newest first.
final vendorLiveStatusesProvider = Provider<AsyncValue<List<StatusPost>>>((ref) {
  return ref.watch(myStatusesProvider).whenData((posts) {
    final now = DateTime.now();
    final live = posts.where((post) => post.isActive && (post.expiresAt?.isAfter(now) ?? true)).toList()
      ..sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));

    return live;
  });
});
