import '../../../core/api/json.dart';
import '../../../core/localization/l10n.dart';

/// The server's notification types (docs/API.md "Notifications").
enum AlertType {
  statusComment('status_comment'),
  statusLike('status_like'),
  friendRequest('friend_request'),
  friendAccepted('friend_accepted'),
  vendorStatus('vendor_status'),
  newReview('new_review'),
  hygieneUpdated('hygiene_updated'),
  hygieneOverdue('hygiene_overdue'),
  unknown('');

  const AlertType(this.apiValue);

  final String apiValue;

  static AlertType parse(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }

    return AlertType.unknown;
  }
}

/// One notification as `NotificationResource` sends it. [title] and [body] are
/// English fallbacks written by the server; the screens build their own wording
/// from [type] and [data] where they can.
class AppAlert {
  const AppAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.body,
    this.data = const {},
    this.isRead = false,
  });

  final String id;
  final AlertType type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  int? get statusId => toInt(data['status_id']);
  int? get vendorId => toInt(data['vendor_id']);
  String? get actorName => data['actor_name'] as String?;

  /// New review: the star rating.
  int? get rating => toInt(data['rating']);

  /// Hygiene update: the new and previous score.
  double? get score => toDouble(data['score']);
  double? get previousScore => toDouble(data['previous_score']);

  AppAlert markRead() => AppAlert(
        id: id,
        type: type,
        title: title,
        createdAt: createdAt,
        body: body,
        data: data,
        isRead: true,
      );

  factory AppAlert.fromJson(Map<String, dynamic> json) {
    return AppAlert(
      id: '${json['id']}',
      type: AlertType.parse(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      data: json['data'] is Map ? asJsonMap(json['data']) : const {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: toDate(json['created_at']),
    );
  }
}

/// The filter pills on the customer's notifications screen.
enum ConsumerAlertFilter {
  all,
  stalls,
  community;

  /// The pill's text, in the language in use.
  String get label => switch (this) {
        ConsumerAlertFilter.all => l10n.alertsFilterAll,
        ConsumerAlertFilter.stalls => l10n.alertsFilterStalls,
        ConsumerAlertFilter.community => l10n.alertsFilterCommunity,
      };

  bool matches(AppAlert alert) => switch (this) {
        ConsumerAlertFilter.all => true,
        ConsumerAlertFilter.stalls => alert.type == AlertType.vendorStatus,
        ConsumerAlertFilter.community => alert.type != AlertType.vendorStatus,
      };
}

/// The filter pills on the vendor's notifications screen.
enum VendorAlertFilter {
  all,
  reviews,
  hygiene,
  buzz;

  /// The pill's text, in the language in use.
  String get label => switch (this) {
        VendorAlertFilter.all => l10n.vaFilterAll,
        VendorAlertFilter.reviews => l10n.vaFilterReviews,
        VendorAlertFilter.hygiene => l10n.vaFilterHygiene,
        VendorAlertFilter.buzz => l10n.vaFilterBuzz,
      };

  bool matches(AppAlert alert) => switch (this) {
        VendorAlertFilter.all => true,
        VendorAlertFilter.reviews => alert.type == AlertType.newReview,
        VendorAlertFilter.hygiene => alert.type == AlertType.hygieneUpdated,
        VendorAlertFilter.buzz => alert.type == AlertType.statusComment || alert.type == AlertType.statusLike,
      };
}
