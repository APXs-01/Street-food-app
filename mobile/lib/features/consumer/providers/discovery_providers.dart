import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/l10n.dart';
import '../../auth/providers/auth_providers.dart';
import '../../vendor/onboarding/data/location_service.dart';
import '../../vendor/onboarding/providers/onboarding_providers.dart';
import '../data/discovery_stall.dart';
import '../data/stall_detail_models.dart';
import '../data/stall_repository.dart';

/// Where the discovery screens search from.
class SearchCenter {
  const SearchCenter({required this.latitude, required this.longitude, required this.isFallback});

  final double latitude;
  final double longitude;

  /// True when the phone's location could not be read and the default area is used.
  final bool isFallback;

  /// "Current location", or the fallback's name, in the language in use.
  String get label => isFallback ? l10n.searchCenterDefault : l10n.searchCenterCurrent;

  /// Central Colombo (Galle Face), used only when the phone cannot say where it is.
  static const SearchCenter fallback = SearchCenter(
    latitude: 6.9271,
    longitude: 79.8612,
    isFallback: true,
  );
}

/// The phone's location, or [SearchCenter.fallback] when permission is denied or
/// location is off. Read once per run; a screen can `ref.invalidate` it to retry.
final searchCenterProvider = FutureProvider<SearchCenter>((ref) async {
  try {
    final point = await ref.read(locationServiceProvider).currentPosition();

    return SearchCenter(latitude: point.latitude, longitude: point.longitude, isFallback: false);
  } on LocationException {
    return SearchCenter.fallback;
  }
});

final stallRepositoryProvider = Provider<StallRepository>((ref) => StallRepository(ref.watch(dioProvider)));

/// The stalls within 25 km of the search centre, nearest first (at most 50, the
/// API's page size). Every screen filters this list rather than asking again.
final allStallsProvider = FutureProvider<List<DiscoveryStall>>((ref) async {
  final center = await ref.watch(searchCenterProvider.future);

  return ref.watch(stallRepositoryProvider).nearby(lat: center.latitude, lng: center.longitude);
});

enum HygieneFilter { all, highOnly, verifiedClean }

/// The filters shared by the home screen, the map screens and search.
class DiscoveryFilter {
  const DiscoveryFilter({
    this.radiusKm = defaultRadiusKm,
    this.hygiene = HygieneFilter.all,
    this.categories = const {},
    this.openNow = false,
  });

  static const double minRadiusKm = 0.5;
  static const double maxRadiusKm = 5;
  static const double defaultRadiusKm = 1.5;

  final double radiusKm;
  final HygieneFilter hygiene;

  /// Category slugs; empty means every category.
  final Set<String> categories;
  final bool openNow;

  /// Whether anything differs from the defaults (shows the dot on filter buttons).
  bool get isActive =>
      radiusKm != defaultRadiusKm || hygiene != HygieneFilter.all || categories.isNotEmpty || openNow;

  DiscoveryFilter copyWith({
    double? radiusKm,
    HygieneFilter? hygiene,
    Set<String>? categories,
    bool? openNow,
  }) {
    return DiscoveryFilter(
      radiusKm: radiusKm ?? this.radiusKm,
      hygiene: hygiene ?? this.hygiene,
      categories: categories ?? this.categories,
      openNow: openNow ?? this.openNow,
    );
  }

  DiscoveryFilter toggleCategory(String slug) {
    final next = Set<String>.of(categories);

    if (!next.remove(slug)) next.add(slug);

    return copyWith(categories: next);
  }

  /// Just [slug], or every category when null (the "All" chip).
  DiscoveryFilter selectOnlyCategory(String? slug) => copyWith(categories: slug == null ? <String>{} : {slug});
}

/// The stalls that pass [filter], nearest first.
List<DiscoveryStall> applyDiscoveryFilter(List<DiscoveryStall> stalls, DiscoveryFilter filter) {
  final maxMetres = filter.radiusKm * 1000;

  final result = stalls.where((stall) {
    if (stall.hasDistance && stall.distanceM > maxMetres) return false;
    if (filter.openNow && !stall.isOpenNow) return false;

    if (filter.categories.isNotEmpty && !stall.categories.any((category) => filter.categories.contains(category.slug))) {
      return false;
    }

    return switch (filter.hygiene) {
      HygieneFilter.all => true,
      HygieneFilter.highOnly => stall.hygiene == HygieneLevel.verified || stall.hygiene == HygieneLevel.high,
      HygieneFilter.verifiedClean => stall.hygiene == HygieneLevel.verified,
    };
  }).toList();

  result.sort((a, b) {
    final byDistance = (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0);

    return byDistance != 0 ? byDistance : b.rating.compareTo(a.rating);
  });

  return result;
}

class DiscoveryFilterNotifier extends Notifier<DiscoveryFilter> {
  @override
  DiscoveryFilter build() => const DiscoveryFilter();

  void apply(DiscoveryFilter filter) => state = filter;

  void selectOnlyCategory(String? slug) => state = state.selectOnlyCategory(slug);

  void reset() => state = const DiscoveryFilter();
}

final discoveryFilterProvider = NotifierProvider<DiscoveryFilterNotifier, DiscoveryFilter>(DiscoveryFilterNotifier.new);

/// The stalls that pass the current filters, nearest first.
final filteredStallsProvider = Provider<AsyncValue<List<DiscoveryStall>>>((ref) {
  final filter = ref.watch(discoveryFilterProvider);

  return ref.watch(allStallsProvider).whenData((stalls) => applyDiscoveryFilter(stalls, filter));
});

/// One stall read by itself (`GET /vendors/{id}`), with the distance from this
/// search if the stall was in it.
final stallDetailProvider = FutureProvider.autoDispose.family<DiscoveryStall, int>((ref, id) async {
  final stall = await ref.watch(stallRepositoryProvider).vendor(id);
  final pool = ref.watch(allStallsProvider).asData?.value ?? const <DiscoveryStall>[];

  return stall.withDistanceFrom(pool.where((candidate) => candidate.id == id).firstOrNull);
});

/// A stall's hygiene breakdown and latest inspection (`GET /vendors/{id}/hygiene`).
final stallHygieneProvider = FutureProvider.autoDispose.family<HygieneBreakdown, int>(
  (ref, id) => ref.watch(stallRepositoryProvider).hygiene(id),
);

/// The first page of a stall's reviews and its star summary
/// (`GET /vendors/{id}/reviews`). Further pages are fetched by the Reviews tab.
final stallReviewsProvider = FutureProvider.autoDispose.family<ReviewsPage, ({int id, bool withPhotos})>(
  (ref, args) => ref.watch(stallRepositoryProvider).reviews(args.id, withPhotos: args.withPhotos),
);

/// Stalls matching [query] (`GET /vendors?q=`), with distances filled in from the
/// nearby list where the stall is in it, then narrowed by the current filters.
final searchResultsProvider = FutureProvider.autoDispose.family<List<DiscoveryStall>, String>((ref, query) async {
  final found = await ref.watch(stallRepositoryProvider).search(query);
  final pool = ref.watch(allStallsProvider).asData?.value ?? const <DiscoveryStall>[];
  final filter = ref.watch(discoveryFilterProvider);

  final withDistance = [
    for (final stall in found) stall.withDistanceFrom(pool.where((candidate) => candidate.id == stall.id).firstOrNull),
  ];

  return applyDiscoveryFilter(withDistance, filter);
});

/// Searches typed into the search screen, newest first. Kept on this device only.
class RecentSearchesNotifier extends Notifier<List<String>> {
  static const _maxEntries = 8;

  @override
  List<String> build() => const [];

  void add(String query) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return;

    state = [text, ...state.where((existing) => existing != text)].take(_maxEntries).toList();
  }

  void clear() => state = const [];
}

final recentSearchesProvider = NotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);
