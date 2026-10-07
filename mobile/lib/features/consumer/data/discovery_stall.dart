import '../../../core/api/json.dart';
import '../../../core/localization/l10n.dart';
import '../../vendor/onboarding/data/stall_category.dart';

/// Hygiene as the screens show it. [unrated] is a stall nobody has inspected yet.
enum HygieneLevel { verified, high, pending, unrated }

/// A dish on a stall's menu, as the API sends it (`MenuItemResource`).
class StallMenuItem {
  const StallMenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.photoUrl,
    this.isAvailable = true,
    this.isFreshToday = false,
  });

  final int id;
  final String name;
  final String? description;
  final double price;
  final String? photoUrl;

  /// False is "sold out".
  final bool isAvailable;
  final bool isFreshToday;

  String get priceLabel => '\$${price.toStringAsFixed(2)}';

  factory StallMenuItem.fromJson(Map<String, dynamic> json) {
    return StallMenuItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: toDouble(json['price']) ?? 0,
      photoUrl: json['photo_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      isFreshToday: json['is_fresh_today'] as bool? ?? false,
    );
  }
}

/// A stall as the customer screens show it. Built from two real payloads, merged
/// by id: `GET /map/nearby` gives the position, distance, live open status and
/// grade; `GET /vendors` (or `GET /vendors/{id}`) gives the description,
/// categories, photo, hours, menu and hygiene detail. A field the API did not
/// send stays null, and the screens leave it out instead of inventing one.
class DiscoveryStall {
  const DiscoveryStall({
    required this.id,
    required this.name,
    this.description,
    this.categories = const [],
    this.distanceKm,
    this.walkingMinutes,
    this.starRating,
    this.ratingCount = 0,
    this.hygieneScore,
    this.hygieneGrade,
    this.hygieneStatus = 'not_inspected',
    this.waterSourceVerified = false,
    this.lastInspectedAt,
    this.reverificationDueAt,
    this.isOpenNow = false,
    this.opensAt,
    this.closesAt,
    this.openDays,
    this.stallCode,
    this.address,
    this.landmark,
    this.latitude,
    this.longitude,
    this.coverPhotoUrl,
    this.followedByMe,
    this.menu = const [],
  });

  final int id;
  final String name;
  final String? description;
  final List<StallCategory> categories;

  /// From the map payload; null for a stall that did not come from a search around a point.
  final double? distanceKm;
  final int? walkingMinutes;

  /// The customers' star average; null until the first review.
  final double? starRating;
  final int ratingCount;

  /// The inspector's score, 0 to 5; null until the first inspection.
  final double? hygieneScore;

  /// `A+`, `A`, `B` or `needs_improvement`.
  final String? hygieneGrade;

  /// `not_inspected`, `verified` or `reverification_pending`.
  final String hygieneStatus;
  final bool waterSourceVerified;
  final DateTime? lastInspectedAt;
  final DateTime? reverificationDueAt;

  /// Live: a stall left switched on past its closing time reads closed.
  final bool isOpenNow;

  /// `HH:mm`.
  final String? opensAt;
  final String? closesAt;

  /// ISO weekdays 1 to 7; null means every day.
  final List<int>? openDays;
  final String? stallCode;
  final String? address;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final String? coverPhotoUrl;

  /// Only on `GET /vendors/{id}`.
  final bool? followedByMe;
  final List<StallMenuItem> menu;

  // ---- parsing ---------------------------------------------------------

  /// One pin from `GET /map/nearby`: `{ id, name, lat, lng, distance_km,
  /// walking_minutes, is_open, hygiene_grade, hygiene_status, star_rating }`.
  factory DiscoveryStall.fromMapPin(Map<String, dynamic> json) {
    return DiscoveryStall(
      id: json['id'] as int,
      name: json['name'] as String,
      latitude: toDouble(json['lat']),
      longitude: toDouble(json['lng']),
      distanceKm: toDouble(json['distance_km']),
      walkingMinutes: toInt(json['walking_minutes']),
      isOpenNow: json['is_open'] as bool? ?? false,
      hygieneGrade: json['hygiene_grade'] as String?,
      hygieneStatus: json['hygiene_status'] as String? ?? 'not_inspected',
      starRating: toDouble(json['star_rating']),
    );
  }

  /// A full stall from `VendorResource`.
  factory DiscoveryStall.fromVendorJson(Map<String, dynamic> json) {
    final hygiene = json['hygiene'] is Map ? asJsonMap(json['hygiene']) : const <String, dynamic>{};
    final rating = json['rating'] is Map ? asJsonMap(json['rating']) : const <String, dynamic>{};
    final schedule = json['schedule'] is Map ? asJsonMap(json['schedule']) : const <String, dynamic>{};
    final status = json['status'] is Map ? asJsonMap(json['status']) : const <String, dynamic>{};

    return DiscoveryStall(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      categories: [for (final item in asJsonList(json['categories'])) StallCategory.fromJson(item)],
      starRating: toDouble(rating['average']),
      ratingCount: toInt(rating['count']) ?? 0,
      hygieneScore: toDouble(hygiene['score']),
      hygieneGrade: hygiene['grade'] as String?,
      hygieneStatus: hygiene['status'] as String? ?? 'not_inspected',
      waterSourceVerified: hygiene['water_source_verified'] as bool? ?? false,
      lastInspectedAt: toDate(hygiene['last_inspected_at']),
      reverificationDueAt: toDate(hygiene['reverification_due_at']),
      isOpenNow: status['is_open_now'] as bool? ?? false,
      opensAt: toClock(schedule['opens_at']),
      closesAt: toClock(schedule['closes_at']),
      openDays: schedule['open_days'] == null ? null : [for (final day in schedule['open_days'] as List) toInt(day)!],
      stallCode: json['stall_code'] as String?,
      address: json['address'] as String?,
      landmark: json['landmark'] as String?,
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      coverPhotoUrl: json['cover_photo_url'] as String?,
      followedByMe: json['followed_by_me'] as bool?,
      menu: [for (final item in asJsonList(json['menu'])) StallMenuItem.fromJson(item)],
    );
  }

  /// This pin's position and distance, filled in with [detail]'s description,
  /// photo, hours and the rest. The pin's live open status wins.
  DiscoveryStall withDetail(DiscoveryStall detail) {
    return DiscoveryStall(
      id: id,
      name: name,
      description: detail.description,
      categories: detail.categories,
      distanceKm: distanceKm,
      walkingMinutes: walkingMinutes,
      starRating: starRating ?? detail.starRating,
      ratingCount: detail.ratingCount,
      hygieneScore: detail.hygieneScore,
      hygieneGrade: hygieneGrade ?? detail.hygieneGrade,
      hygieneStatus: hygieneStatus,
      waterSourceVerified: detail.waterSourceVerified,
      lastInspectedAt: detail.lastInspectedAt,
      reverificationDueAt: detail.reverificationDueAt,
      isOpenNow: isOpenNow,
      opensAt: detail.opensAt,
      closesAt: detail.closesAt,
      openDays: detail.openDays,
      stallCode: detail.stallCode,
      address: detail.address,
      landmark: detail.landmark,
      latitude: latitude,
      longitude: longitude,
      coverPhotoUrl: detail.coverPhotoUrl,
      followedByMe: detail.followedByMe,
      menu: detail.menu,
    );
  }

  /// [detail] (a stall read by itself) with the distance this search found.
  DiscoveryStall withDistanceFrom(DiscoveryStall? pin) {
    if (pin == null) return this;

    return DiscoveryStall(
      id: id,
      name: name,
      description: description,
      categories: categories,
      distanceKm: pin.distanceKm,
      walkingMinutes: pin.walkingMinutes,
      starRating: starRating,
      ratingCount: ratingCount,
      hygieneScore: hygieneScore,
      hygieneGrade: hygieneGrade,
      hygieneStatus: hygieneStatus,
      waterSourceVerified: waterSourceVerified,
      lastInspectedAt: lastInspectedAt,
      reverificationDueAt: reverificationDueAt,
      isOpenNow: isOpenNow,
      opensAt: opensAt,
      closesAt: closesAt,
      openDays: openDays,
      stallCode: stallCode,
      address: address,
      landmark: landmark,
      latitude: latitude,
      longitude: longitude,
      coverPhotoUrl: coverPhotoUrl,
      followedByMe: followedByMe,
      menu: menu,
    );
  }

  DiscoveryStall copyWith({bool? isOpenNow, bool? followedByMe, String? opensAt, String? closesAt, List<StallMenuItem>? menu}) {
    return DiscoveryStall(
      id: id,
      name: name,
      description: description,
      categories: categories,
      distanceKm: distanceKm,
      walkingMinutes: walkingMinutes,
      starRating: starRating,
      ratingCount: ratingCount,
      hygieneScore: hygieneScore,
      hygieneGrade: hygieneGrade,
      hygieneStatus: hygieneStatus,
      waterSourceVerified: waterSourceVerified,
      lastInspectedAt: lastInspectedAt,
      reverificationDueAt: reverificationDueAt,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      openDays: openDays,
      stallCode: stallCode,
      address: address,
      landmark: landmark,
      latitude: latitude,
      longitude: longitude,
      coverPhotoUrl: coverPhotoUrl,
      followedByMe: followedByMe ?? this.followedByMe,
      menu: menu ?? this.menu,
    );
  }

  // ---- what the screens read ----------------------------------------------

  String get dish => description ?? '';

  bool get hasDistance => distanceKm != null;

  /// `250m` or `1.2 km`; empty when the distance is not known.
  String get distanceShort {
    final km = distanceKm;
    if (km == null) return '';

    return km < 1 ? '${(km * 1000).round()}m' : '${km.toStringAsFixed(1)} km';
  }

  /// `250m away`, or empty.
  String get distanceLabel => hasDistance ? l10n.stallDistanceAway(distanceShort) : '';

  int get distanceM => ((distanceKm ?? 0) * 1000).round();

  /// Minutes on foot, from the server.
  int get walkMinutes => walkingMinutes ?? 0;

  bool get hasRating => starRating != null;

  /// The star rating, or 0 when nobody has reviewed the stall yet.
  double get rating => starRating ?? 0;

  /// `4.9`, or `New` for a stall with no reviews.
  String get ratingLabel => hasRating ? rating.toStringAsFixed(1) : l10n.stallRatingNew;

  HygieneLevel get hygiene {
    if (hygieneStatus == 'not_inspected') return HygieneLevel.unrated;
    if (hygieneStatus == 'reverification_pending') return HygieneLevel.pending;

    return switch (hygieneGrade) {
      'A+' => HygieneLevel.verified,
      'A' || 'B' => HygieneLevel.high,
      _ => HygieneLevel.pending,
    };
  }

  /// The inspector's score as a percentage ("98% Clean"); null if not inspected.
  int? get cleanPercent => hygieneScore == null ? null : (hygieneScore! / 5 * 100).round();

  /// Amber on the map and in lists: a re-verification is due, or the stars are low.
  bool get isCaution => hygiene == HygieneLevel.pending || (hasRating && rating < 4.0);

  /// The number in the stall code (`VEND-0012` is 12); the id if there is no code.
  int get stallNumber => int.tryParse((stallCode ?? '').replaceAll(RegExp(r'\D'), '')) ?? id;

  /// `Stall #12`, in the language in use.
  String get stallNumberLabel => l10n.stallNumber(stallNumber);

  String get locationLabel => (landmark?.isNotEmpty ?? false) ? landmark! : (address ?? '');

  /// `2 AM`, or null when the closing time is not known.
  String? get opensUntil => closesAt == null ? null : clockLabel(closesAt!);

  /// `Open until 2 AM`, `Open now`, or `Closed now`.
  String get openLabel =>
      isOpenNow ? (opensUntil == null ? l10n.stallOpenNow : l10n.stallOpenUntil(opensUntil!)) : l10n.stallClosedNow;

  /// `Open Now until 1 AM`, `Open Now`, or `Closed now`.
  String get openNowLabel =>
      isOpenNow ? (opensUntil == null ? l10n.stallOpenNowCap : l10n.stallOpenNowUntil(opensUntil!)) : l10n.stallClosedNow;

  String get photoUrl => coverPhotoUrl ?? '';

  /// Whether [query] matches the name, the description or a category.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;

    if (name.toLowerCase().contains(needle) || dish.toLowerCase().contains(needle)) return true;

    return categories.any((c) => c.slug.contains(needle) || c.name.toLowerCase().contains(needle));
  }
}

/// `17:00` as `5 PM`, `01:30` as `1:30 AM`.
String clockLabel(String hhmm) {
  final parts = hhmm.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? parts[1] : '00';
  final twelve = hour % 12 == 0 ? 12 : hour % 12;
  final period = hour < 12 ? l10n.timeAm : l10n.timePm;

  return minute == '00' ? '$twelve $period' : '$twelve:$minute $period';
}
