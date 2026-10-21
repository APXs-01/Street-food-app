import '../../../core/api/json.dart';
import '../../../core/format.dart';
import '../../../core/localization/l10n.dart';

/// Who wrote a status or a comment.
class StatusAuthor {
  const StatusAuthor({required this.id, required this.name, this.username, this.avatarUrl, this.role});

  final int id;
  final String name;
  final String? username;
  final String? avatarUrl;

  /// `consumer` or `vendor`.
  final String? role;

  factory StatusAuthor.fromJson(Map<String, dynamic> json) {
    return StatusAuthor(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
    );
  }
}

class StatusComment {
  const StatusComment({required this.id, required this.body, required this.author, required this.createdAt});

  final int id;
  final String body;
  final StatusAuthor? author;
  final DateTime? createdAt;

  String get authorName => author?.name ?? l10n.commonSomeone;

  factory StatusComment.fromJson(Map<String, dynamic> json) {
    return StatusComment(
      id: json['id'] as int,
      body: json['body'] as String,
      author: json['author'] is Map ? StatusAuthor.fromJson(asJsonMap(json['author'])) : null,
      createdAt: toDate(json['created_at']),
    );
  }
}

/// A daily status (`StatusResource`): a photo and a caption that stay on the
/// radar for 24 hours.
class StatusPost {
  const StatusPost({
    required this.id,
    required this.author,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    this.caption,
    this.mediaUrl,
    this.audience = 'public',
    this.locationLabel,
    this.vendorId,
    this.vendorName,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedByMe = false,
    this.isHidden = false,
    this.comments = const [],
  });

  final int id;
  final StatusAuthor author;
  final String? caption;
  final String? mediaUrl;

  /// `public` or `friends`.
  final String audience;
  final String? locationLabel;

  /// The stall this status is about: a vendor's own stall, or one a customer tagged.
  final int? vendorId;
  final String? vendorName;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final bool isActive;

  /// Set only on the author's own view of a status a moderator has hidden.
  final bool isHidden;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  /// Only on a status read by itself.
  final List<StatusComment> comments;

  /// A vendor's name for a stall status, otherwise the person's name.
  String get displayName => vendorName ?? author.name;

  /// The photo, empty when the status has none.
  String get photoUrl => mediaUrl ?? '';

  Duration remainingAt(DateTime now) => (expiresAt ?? now).difference(now);

  /// `3h 12m left`, `45m left`, or `Expired`.
  String timeLeftLabelAt(DateTime now) {
    final left = remainingAt(now);
    if (left <= Duration.zero) return l10n.statusExpired;

    final hours = left.inHours;
    final minutes = left.inMinutes % 60;

    return hours == 0 ? l10n.statusTimeLeftM(minutes) : l10n.statusTimeLeftHM(hours, minutes);
  }

  /// `Expires in 3h`, or in minutes under an hour.
  String expiresInLabelAt(DateTime now) {
    final left = remainingAt(now);
    if (left <= Duration.zero) return l10n.statusExpired;

    return left.inHours == 0 ? l10n.statusExpiresInM(left.inMinutes) : l10n.statusExpiresInH(left.inHours);
  }

  String postedAgoLabelAt(DateTime now) => createdAt == null ? '' : agoLabel(now.difference(createdAt!));

  StatusPost copyWith({int? likesCount, bool? likedByMe, List<StatusComment>? comments, int? commentsCount}) {
    return StatusPost(
      id: id,
      author: author,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isActive: isActive,
      caption: caption,
      mediaUrl: mediaUrl,
      audience: audience,
      locationLabel: locationLabel,
      vendorId: vendorId,
      vendorName: vendorName,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedByMe: likedByMe ?? this.likedByMe,
      isHidden: isHidden,
      comments: comments ?? this.comments,
    );
  }

  factory StatusPost.fromJson(Map<String, dynamic> json) {
    final media = json['media'] is Map ? asJsonMap(json['media']) : null;
    final vendor = json['vendor'] is Map ? asJsonMap(json['vendor']) : null;

    return StatusPost(
      id: json['id'] as int,
      author: StatusAuthor.fromJson(asJsonMap(json['author'])),
      caption: json['caption'] as String?,
      mediaUrl: media?['url'] as String?,
      audience: json['audience'] as String? ?? 'public',
      locationLabel: json['location_label'] as String?,
      vendorId: vendor?['id'] as int?,
      vendorName: vendor?['name'] as String?,
      likesCount: toInt(json['likes_count']) ?? 0,
      commentsCount: toInt(json['comments_count']) ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isHidden: json['is_hidden'] as bool? ?? false,
      createdAt: toDate(json['created_at']),
      expiresAt: toDate(json['expires_at']),
    );
  }
}

/// A circle in the "Daily Fresh Stories" row: the newest live status of one
/// person or stall in the feed.
class StoryCircle {
  const StoryCircle({required this.statusId, required this.name, required this.photoUrl, required this.expiresAt});

  final int statusId;
  final String name;
  final String photoUrl;
  final DateTime? expiresAt;

  /// Whole hours left, rounded up, never below 1 while it is live.
  int hoursLeftAt(DateTime now) {
    final left = (expiresAt ?? now).difference(now);

    return left.inMinutes <= 0 ? 0 : (left.inMinutes / 60).ceil();
  }

  String timeLeftLabelAt(DateTime now) => l10n.homeStoryTimeLeft(hoursLeftAt(now));

  /// Under two hours left reads as a warning.
  bool cautionAt(DateTime now) => hoursLeftAt(now) <= 1;
}

/// One story circle per author, newest status first. Hidden and expired statuses
/// are skipped.
List<StoryCircle> storiesFrom(List<StatusPost> feed, {DateTime? now}) {
  final at = now ?? DateTime.now();
  final seen = <int>{};
  final stories = <StoryCircle>[];

  final live = feed.where((post) => post.isActive && (post.expiresAt?.isAfter(at) ?? true)).toList()
    ..sort((a, b) => (b.createdAt ?? at).compareTo(a.createdAt ?? at));

  for (final post in live) {
    if (!seen.add(post.author.id)) continue;

    stories.add(StoryCircle(statusId: post.id, name: post.displayName, photoUrl: post.photoUrl, expiresAt: post.expiresAt));
  }

  return stories;
}
