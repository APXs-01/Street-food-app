/// The roles that can sign in through this app. Inspectors and administrators
/// exist on the backend but use other tools, so a token for one of them is not
/// accepted here.
enum UserRole {
  consumer('consumer'),
  vendor('vendor');

  const UserRole(this.apiValue);

  /// The value used in URLs (`/api/{apiValue}/login`) and in `user.role`.
  final String apiValue;

  static UserRole? tryParse(String? value) {
    for (final role in values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }
}
