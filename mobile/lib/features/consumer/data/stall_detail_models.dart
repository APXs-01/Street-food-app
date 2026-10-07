import '../../../core/api/json.dart';
import '../../../core/localization/l10n.dart';

/// One row of the municipal checklist: the criterion's API key and its result.
class CriterionResult {
  const CriterionResult({required this.key, required this.result});

  /// `water_source`, `utensil_glove_hygiene`, `waste_disposal`, `food_covering`
  /// or `overall_cleanliness`.
  final String key;

  /// `pass`, `partial` or `fail`.
  final String result;

  bool get passed => result == 'pass';
}

class InspectionRecord {
  const InspectionRecord({
    required this.criteria,
    this.inspectedAt,
    this.notes,
    this.organization,
    this.evidenceUrl,
  });

  final List<CriterionResult> criteria;
  final DateTime? inspectedAt;
  final String? notes;
  final String? organization;
  final String? evidenceUrl;
}

/// `GET /vendors/{id}/hygiene`: the badge and the latest inspection.
class HygieneBreakdown {
  const HygieneBreakdown({
    required this.status,
    this.score,
    this.grade,
    this.gradeLabel,
    this.waterSourceVerified = false,
    this.lastInspectedAt,
    this.reverificationDueAt,
    this.inspection,
  });

  /// `not_inspected`, `verified` or `reverification_pending`.
  final String status;
  final double? score;
  final String? grade;
  final String? gradeLabel;
  final bool waterSourceVerified;
  final DateTime? lastInspectedAt;
  final DateTime? reverificationDueAt;

  /// Null until the first inspection.
  final InspectionRecord? inspection;

  bool get inspected => status != 'not_inspected';

  /// Whole days until re-verification is due; zero or less means it is due now.
  int? daysUntilDue({DateTime? now}) {
    final due = reverificationDueAt;
    if (due == null) return null;

    return due.difference(now ?? DateTime.now()).inDays;
  }

  factory HygieneBreakdown.fromJson(Map<String, dynamic> json) {
    final inspection = json['inspection'];

    return HygieneBreakdown(
      status: json['status'] as String? ?? 'not_inspected',
      score: toDouble(json['score']),
      grade: json['grade'] as String?,
      gradeLabel: json['grade_label'] as String?,
      waterSourceVerified: json['water_source_verified'] as bool? ?? false,
      lastInspectedAt: toDate(json['last_inspected_at']),
      reverificationDueAt: toDate(json['reverification_due_at']),
      inspection: inspection == null
          ? null
          : () {
              final data = asJsonMap(inspection);
              final evidence = data['evidence'] is Map ? asJsonMap(data['evidence']) : const <String, dynamic>{};

              return InspectionRecord(
                criteria: [
                  for (final item in asJsonList(data['criteria']))
                    CriterionResult(key: item['key'] as String, result: item['result'] as String),
                ],
                inspectedAt: toDate(data['inspected_at']),
                notes: data['notes'] as String?,
                organization: data['organization'] as String?,
                evidenceUrl: evidence['url'] as String?,
              );
            }(),
    );
  }
}

class ReviewPhoto {
  const ReviewPhoto({required this.id, required this.url});

  final int id;
  final String url;
}

/// A customer review, as `ReviewResource` sends it.
class StallReview {
  const StallReview({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.authorName,
    this.anonymous = false,
    this.observations = const [],
    this.photos = const [],
  });

  final int id;
  final int rating;
  final String? comment;

  /// Null for an anonymous review.
  final String? authorName;
  final bool anonymous;
  final List<String> observations;
  final List<ReviewPhoto> photos;
  final DateTime? createdAt;

  bool get hasPhotos => photos.isNotEmpty;

  /// What to call the reviewer: their name, or "Anonymous customer".
  String get displayName => anonymous || authorName == null ? l10n.reviewAnonymous : authorName!;

  factory StallReview.fromJson(Map<String, dynamic> json) {
    final author = json['author'] is Map ? asJsonMap(json['author']) : const <String, dynamic>{};

    return StallReview(
      id: json['id'] as int,
      rating: toInt(json['rating']) ?? 0,
      comment: json['comment'] as String?,
      authorName: author['name'] as String?,
      anonymous: author['anonymous'] as bool? ?? false,
      observations: [for (final key in (json['observations'] as List? ?? const [])) key as String],
      photos: [
        for (final photo in asJsonList(json['photos'])) ReviewPhoto(id: photo['id'] as int, url: photo['url'] as String),
      ],
      createdAt: toDate(json['created_at']),
    );
  }
}

/// One page of `GET /vendors/{id}/reviews` with its star summary.
class ReviewsPage {
  const ReviewsPage({
    required this.reviews,
    required this.average,
    required this.count,
    required this.distribution,
    required this.currentPage,
    required this.lastPage,
  });

  final List<StallReview> reviews;
  final double? average;
  final int count;

  /// Reviews per star, 5 down to 1.
  final Map<int, int> distribution;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  factory ReviewsPage.fromJson(Map<String, dynamic> json) {
    final summary = asJsonMap(json['summary']);
    final meta = json['meta'] is Map ? asJsonMap(json['meta']) : const <String, dynamic>{};
    final distribution = summary['distribution'] is Map ? asJsonMap(summary['distribution']) : const <String, dynamic>{};

    return ReviewsPage(
      reviews: [for (final item in asJsonList(json['data'])) StallReview.fromJson(item)],
      average: toDouble(summary['average']),
      count: toInt(summary['count']) ?? 0,
      distribution: {for (var star = 5; star >= 1; star--) star: toInt(distribution['$star']) ?? 0},
      currentPage: toInt(meta['current_page']) ?? 1,
      lastPage: toInt(meta['last_page']) ?? 1,
    );
  }
}
