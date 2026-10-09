import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/format.dart';
import 'package:mobile/features/statuses/data/status_models.dart';
import 'package:mobile/features/vendor/data/vendor_models.dart';

StatusPost _status({required Duration age, int id = 1, bool active = true}) {
  final created = DateTime(2026, 10, 2, 12).subtract(age);

  return StatusPost(
    id: id,
    author: const StatusAuthor(id: 1, name: 'A Stall'),
    createdAt: created,
    expiresAt: created.add(const Duration(hours: 24)),
    isActive: active,
  );
}

void main() {
  final now = DateTime(2026, 10, 2, 12);

  group('shiftTime', () {
    test('moves by minutes', () {
      expect(shiftTime(const TimeOfDay(hour: 17, minute: 0), 30), const TimeOfDay(hour: 17, minute: 30));
      expect(shiftTime(const TimeOfDay(hour: 17, minute: 30), -60), const TimeOfDay(hour: 16, minute: 30));
    });

    test('wraps around midnight in both directions', () {
      expect(shiftTime(const TimeOfDay(hour: 23, minute: 45), 30), const TimeOfDay(hour: 0, minute: 15));
      expect(shiftTime(const TimeOfDay(hour: 0, minute: 15), -30), const TimeOfDay(hour: 23, minute: 45));
      expect(shiftTime(const TimeOfDay(hour: 1, minute: 0), -1500), const TimeOfDay(hour: 0, minute: 0));
    });
  });

  group('parseClock', () {
    test('reads 12-hour times', () {
      expect(parseClock('2 AM'), const TimeOfDay(hour: 2, minute: 0));
      expect(parseClock('11 PM'), const TimeOfDay(hour: 23, minute: 0));
      expect(parseClock('12 AM'), const TimeOfDay(hour: 0, minute: 0));
      expect(parseClock('12 PM'), const TimeOfDay(hour: 12, minute: 0));
      expect(parseClock('5:30 pm'), const TimeOfDay(hour: 17, minute: 30));
    });

    test('is null for anything else', () {
      expect(parseClock('late'), isNull);
      expect(parseClock('13 PM'), isNull);
      expect(parseClock('5:75 PM'), isNull);
    });
  });

  group('parseApiTime', () {
    test('reads the API\'s HH:mm', () {
      expect(parseApiTime('17:00'), const TimeOfDay(hour: 17, minute: 0));
      expect(parseApiTime('01:30'), const TimeOfDay(hour: 1, minute: 30));
      expect(parseApiTime('17:00:00'), const TimeOfDay(hour: 17, minute: 0));
    });

    test('is null for nothing or nonsense', () {
      expect(parseApiTime(null), isNull);
      expect(parseApiTime('soon'), isNull);
    });
  });

  group('status expiry', () {
    test('says how long is left', () {
      expect(_status(age: const Duration(hours: 20, minutes: 48)).timeLeftLabelAt(now), '3h 12m left');
      expect(_status(age: const Duration(hours: 23, minutes: 15)).timeLeftLabelAt(now), '45m left');
      expect(_status(age: const Duration(hours: 25)).timeLeftLabelAt(now), 'Expired');
    });

    test('the Homepage pill rounds down to whole hours, then minutes', () {
      expect(_status(age: const Duration(hours: 21)).expiresInLabelAt(now), 'Expires in 3h');
      expect(_status(age: const Duration(hours: 23, minutes: 15)).expiresInLabelAt(now), 'Expires in 45m');
    });

    test('ages are phrased naturally', () {
      expect(agoLabel(Duration.zero), 'Just now');
      expect(agoLabel(const Duration(minutes: 25)), '25 min ago');
      expect(agoLabel(const Duration(hours: 1)), '1 hour ago');
      expect(agoLabel(const Duration(hours: 5)), '5 hours ago');
      expect(agoLabel(const Duration(days: 2)), '2 days ago');
      expect(agoLabel(const Duration(days: 15)), '2 weeks ago');
      expect(agoFrom(null), '');
    });
  });

  group('story circles', () {
    test('one circle per author, newest status first, skipping expired and hidden ones', () {
      final older = _status(age: const Duration(hours: 5), id: 1);
      final newer = _status(age: const Duration(hours: 1), id: 2);
      final expired = _status(age: const Duration(hours: 30), id: 3);

      final stories = storiesFrom([older, newer, expired], now: now);

      expect(stories.length, 1);
      expect(stories.single.statusId, 2);
      expect(stories.single.hoursLeftAt(now), 23);
    });

    test('a status in its last hour is a caution', () {
      final late = _status(age: const Duration(hours: 23, minutes: 30), id: 4);
      final story = storiesFrom([late], now: now).single;

      expect(story.timeLeftLabelAt(now), '1h left');
      expect(story.cautionAt(now), isTrue);
    });
  });

  group('analytics', () {
    test('reads the API\'s three blocks and leaves views null', () {
      final analytics = VendorAnalytics.fromJson({
        'rating': {'average': 4.6, 'count': 12},
        'hygiene_trend': [
          {'inspected_at': '2026-09-01T10:00:00.000000Z', 'score': 4.0, 'grade': 'A'},
          {'inspected_at': '2026-09-20T10:00:00.000000Z', 'score': 4.8, 'grade': 'A+'},
        ],
        'engagement': {'views': null, 'likes': 5, 'comments': 2, 'statuses': 1},
      });

      expect(analytics.ratingAverage, 4.6);
      expect(analytics.ratingCount, 12);
      expect(analytics.trend.map((point) => point.score), [4.0, 4.8]);
      expect(analytics.views, isNull);
      expect(analytics.likes, 5);
      expect(analytics.comments, 2);
      expect(analytics.statuses, 1);
    });

    test('a stall with no reviews or inspections has a null average and an empty trend', () {
      final analytics = VendorAnalytics.fromJson({
        'rating': {'average': null, 'count': 0},
        'hygiene_trend': <Object?>[],
        'engagement': {'views': null, 'likes': 0, 'comments': 0, 'statuses': 0},
      });

      expect(analytics.ratingAverage, isNull);
      expect(analytics.trend, isEmpty);
    });
  });
}
