import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_failure.dart';
import 'package:mobile/features/inspector/data/inspection_scoring.dart';
import 'package:mobile/features/notifications/data/alert_models.dart';
import 'package:mobile/features/social/data/social_models.dart';
import 'package:mobile/features/social/providers/social_providers.dart';

AppAlert _alert(String type, {bool read = false}) {
  return AppAlert.fromJson({
    'id': 'n-$type',
    'type': type,
    'title': 'Title',
    'body': 'Body',
    'data': {'status_id': 4, 'vendor_id': 9, 'rating': 5, 'score': 4.6, 'previous_score': 4.0},
    'is_read': read,
    'created_at': '2026-10-02T06:00:00.000000Z',
  });
}

void main() {
  group('inspection scoring', () {
    test('names the five criteria exactly as the backend does', () {
      expect(
        InspectionCriterion.values.map((c) => c.apiField),
        ['water_source', 'utensil_glove_hygiene', 'waste_disposal', 'food_covering', 'overall_cleanliness'],
      );
    });

    test('the three answers are sent as the backend spells them', () {
      expect(CheckResult.values.map((r) => r.apiValue), ['pass', 'partial', 'fail']);
    });

    test('a pass is one point of five, scaled to 5.0', () {
      expect(inspectionScore(5), 5.0);
      expect(inspectionScore(4), 4.0);
      expect(inspectionScore(3), 3.0);
      expect(inspectionScore(0), 0.0);
    });

    test('a partial is half a point', () {
      final results = [
        CheckResult.pass,
        CheckResult.pass,
        CheckResult.pass,
        CheckResult.partial,
        CheckResult.fail,
      ];

      // 3.5 of 5 points, scaled to 5.0.
      expect(inspectionScoreOf(results), 3.5);
      expect(inspectionScoreOf(List.filled(5, CheckResult.partial)), 2.5);
    });

    test('grades follow the backend thresholds', () {
      expect(inspectionGrade(5.0), 'A+');
      expect(inspectionGrade(4.5), 'A+');
      expect(inspectionGrade(4.0), 'A');
      expect(inspectionGrade(3.5), 'A');
      expect(inspectionGrade(3.0), 'B');
      expect(inspectionGrade(2.5), 'B');
      expect(inspectionGrade(2.0), 'Needs Improvement');
    });
  });

  group('friends', () {
    test('a friendship row is read from the side of the signed-in customer', () {
      final friendship = Friendship.fromJson({
        'id': 3,
        'status': 'pending',
        'direction': 'incoming',
        'user': {'id': 12, 'name': 'Sam', 'username': 'sam', 'avatar_url': null},
        'created_at': '2026-10-01T04:00:00.000000Z',
        'responded_at': null,
      });

      expect(friendship.id, 3);
      expect(friendship.incoming, isTrue);
      expect(friendship.person.id, 12);
      expect(friendship.person.atHandle, '@sam');
      expect(friendship.respondedAt, isNull);
    });

    test('a person without a username has no handle', () {
      expect(const Foodie(id: 1, name: 'A').atHandle, '');
    });
  });

  group('followed stalls', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('following is remembered as soon as it is asked, and kept when the server agrees', () async {
      final notifier = container.read(followedStallsProvider.notifier);

      await notifier.setFollowing(4, follow: true, send: () async {});

      expect(container.read(followedStallsProvider)[4], isTrue);
    });

    test('a refusal puts it back the way it was', () async {
      final notifier = container.read(followedStallsProvider.notifier);
      notifier.remember(4, false);

      await expectLater(
        notifier.setFollowing(4, follow: true, send: () async => throw const ApiFailure(message: 'No.')),
        throwsA(isA<ApiFailure>()),
      );

      expect(container.read(followedStallsProvider)[4], isFalse);
    });

    test('a refusal for a stall that was unknown leaves it unknown', () async {
      final notifier = container.read(followedStallsProvider.notifier);

      await expectLater(
        notifier.setFollowing(8, follow: true, send: () async => throw const ApiFailure(message: 'No.')),
        throwsA(isA<ApiFailure>()),
      );

      expect(container.read(followedStallsProvider).containsKey(8), isFalse);
    });
  });

  group('notifications', () {
    test('a notification is read as the server sends it', () {
      final alert = _alert('new_review');

      expect(alert.type, AlertType.newReview);
      expect(alert.isRead, isFalse);
      expect(alert.statusId, 4);
      expect(alert.vendorId, 9);
      expect(alert.rating, 5);
      expect(alert.score, 4.6);
      expect(alert.previousScore, 4.0);
      expect(alert.markRead().isRead, isTrue);
    });

    test('a type this app does not know is kept, not dropped', () {
      expect(_alert('something_new').type, AlertType.unknown);
    });

    test('the customer filters split stall updates from the community', () {
      final alerts = [_alert('vendor_status'), _alert('friend_request'), _alert('status_like')];

      expect(alerts.where(ConsumerAlertFilter.all.matches).length, 3);
      expect(alerts.where(ConsumerAlertFilter.stalls.matches).length, 1);
      expect(alerts.where(ConsumerAlertFilter.community.matches).length, 2);
    });

    test('the vendor filters group reviews, hygiene and buzz', () {
      final alerts = [
        _alert('new_review'),
        _alert('hygiene_updated'),
        _alert('status_comment'),
        _alert('status_like'),
      ];

      expect(alerts.where(VendorAlertFilter.reviews.matches).length, 1);
      expect(alerts.where(VendorAlertFilter.hygiene.matches).length, 1);
      expect(alerts.where(VendorAlertFilter.buzz.matches).length, 2);
    });
  });
}
