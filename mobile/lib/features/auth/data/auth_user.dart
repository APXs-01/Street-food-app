/// The `user` object from login, register and `GET /user` (UserResource).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.role,
    this.username,
    this.email,
    this.phone,
    this.avatarUrl,
    this.vendorId,
    this.bio,
  });

  final int id;
  final String name;

  /// The raw `role` value; see UserRole.tryParse.
  final String role;
  final String? username;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  /// Set once a vendor has finished stall onboarding; null before that.
  final int? vendorId;
  final String? bio;

  AuthUser copyWith({int? vendorId}) {
    return AuthUser(
      id: id,
      name: name,
      role: role,
      username: username,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      vendorId: vendorId ?? this.vendorId,
      bio: bio,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['role'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      vendorId: json['vendor_id'] as int?,
      bio: json['bio'] as String?,
    );
  }
}
