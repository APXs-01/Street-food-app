import 'package:flutter/material.dart' show TimeOfDay;

import '../../../core/api/json.dart';

/// [time] moved by [minutes] (negative goes back), wrapping around midnight.
TimeOfDay shiftTime(TimeOfDay time, int minutes) {
  final total = ((time.hour * 60 + time.minute + minutes) % 1440 + 1440) % 1440;

  return TimeOfDay(hour: total ~/ 60, minute: total % 60);
}

/// Reads `2 AM`, `5:30 PM` or `11 PM` as a time of day; null if it is not one.
TimeOfDay? parseClock(String text) {
  final match = RegExp(r'^\s*(\d{1,2})(?::(\d{2}))?\s*(AM|PM)\s*$', caseSensitive: false).firstMatch(text);
  if (match == null) return null;

  final hour = int.parse(match.group(1)!);
  final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
  if (hour < 1 || hour > 12 || minute > 59) return null;

  final pm = match.group(3)!.toUpperCase() == 'PM';

  return TimeOfDay(hour: hour % 12 + (pm ? 12 : 0), minute: minute);
}

/// `17:00` as a time of day; null if it is not `HH:mm`.
TimeOfDay? parseApiTime(String? value) {
  if (value == null) return null;

  final parts = value.split(':');
  if (parts.length < 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;

  return TimeOfDay(hour: hour, minute: minute);
}

/// One inspection in the hygiene trend.
class TrendPoint {
  const TrendPoint({required this.inspectedAt, required this.score, this.grade});

  final DateTime? inspectedAt;
  final double score;
  final String? grade;
}

/// `GET /vendors/{id}/analytics` (owner only), exactly as the server sends it:
/// the stall's star rating, the scores of its latest inspections (oldest first,
/// at most 10) and engagement across its live statuses.
///
/// [views] is always null: the app does not track views, and the screens leave
/// the figure out rather than show zero.
class VendorAnalytics {
  const VendorAnalytics({
    required this.ratingAverage,
    required this.ratingCount,
    required this.trend,
    required this.views,
    required this.likes,
    required this.comments,
    required this.statuses,
  });

  final double? ratingAverage;
  final int ratingCount;
  final List<TrendPoint> trend;
  final int? views;
  final int likes;
  final int comments;
  final int statuses;

  factory VendorAnalytics.fromJson(Map<String, dynamic> json) {
    final rating = asJsonMap(json['rating']);
    final engagement = asJsonMap(json['engagement']);

    return VendorAnalytics(
      ratingAverage: toDouble(rating['average']),
      ratingCount: toInt(rating['count']) ?? 0,
      trend: [
        for (final point in asJsonList(json['hygiene_trend']))
          TrendPoint(
            inspectedAt: toDate(point['inspected_at']),
            score: toDouble(point['score']) ?? 0,
            grade: point['grade'] as String?,
          ),
      ],
      views: toInt(engagement['views']),
      likes: toInt(engagement['likes']) ?? 0,
      comments: toInt(engagement['comments']) ?? 0,
      statuses: toInt(engagement['statuses']) ?? 0,
    );
  }
}
