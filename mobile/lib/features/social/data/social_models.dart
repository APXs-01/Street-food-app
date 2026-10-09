import '../../../core/api/json.dart';

/// A person as the friends API shows them (`FriendshipResource.user`,
/// `GET /users/lookup`).
class Foodie {
  const Foodie({required this.id, required this.name, this.username, this.avatarUrl});

  final int id;
  final String name;
  final String? username;
  final String? avatarUrl;

  String get atHandle => username == null ? '' : '@$username';

  factory Foodie.fromJson(Map<String, dynamic> json) {
    return Foodie(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// A friendship row from the signed-in customer's side: [person] is always the
/// other one. [id] is the friendship's id (what accept, decline and unfriend use),
/// not the person's.
class Friendship {
  const Friendship({
    required this.id,
    required this.status,
    required this.incoming,
    required this.person,
    required this.createdAt,
    this.respondedAt,
  });

  final int id;

  /// `pending`, `accepted` or `declined`.
  final String status;

  /// True when they sent it to you.
  final bool incoming;
  final Foodie person;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as int,
      status: json['status'] as String,
      incoming: json['direction'] == 'incoming',
      person: Foodie.fromJson(asJsonMap(json['user'])),
      createdAt: toDate(json['created_at']),
      respondedAt: toDate(json['responded_at']),
    );
  }
}
