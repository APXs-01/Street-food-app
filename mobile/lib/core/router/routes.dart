import '../models/user_role.dart';

abstract final class Routes {
  static const roleSelect = '/';
  static const consumerLogin = '/login/consumer';
  static const consumerSignup = '/signup/consumer';
  static const vendorLogin = '/login/vendor';
  static const vendorSignup = '/signup/vendor';

  static const consumerHome = '/consumer/home';
  static const consumerSearch = '/consumer/search';
  static const consumerMap = '/consumer/map';
  static const consumerMapSplit = '/consumer/map/split';
  static const consumerAlerts = '/consumer/alerts';
  static const consumerProfile = '/consumer/profile';

  /// Route pattern for the vendor profile; build a link with [consumerVendor].
  static const consumerVendorPattern = '/consumer/vendor/:id';
  static String consumerVendor(int id) => '/consumer/vendor/$id';

  /// The review and photo form for a stall; build a link with [consumerVendorReview].
  static const consumerVendorReviewPattern = '/consumer/vendor/:id/review';
  static String consumerVendorReview(int id) => '/consumer/vendor/$id/review';

  static const consumerFriends = '/consumer/friends';

  /// Customers post statuses too. These two must be matched before the
  /// `:id` pattern below.
  static const consumerStatusCreate = '/consumer/status/create';
  static const consumerStatusHistory = '/consumer/status/history';

  /// A status (story) viewed from the customer side; build with [consumerStatus].
  static const consumerStatusPattern = '/consumer/status/:id';
  static String consumerStatus(int id) => '/consumer/status/$id';

  static const vendorHome = '/vendor/home';
  static const vendorDashboard = '/vendor/dashboard';
  static const vendorAnalytics = '/vendor/analytics';
  static const vendorProfile = '/vendor/profile';

  /// Vendor notifications, opened from the bell (the nav has no Alerts tab).
  static const vendorAlerts = '/vendor/alerts';

  /// The health inspector's checklist. The app has no inspector sign-in yet, so
  /// nothing links here; it is reachable by route only.
  static const inspectorChecklist = '/inspector/checklist';
  static const vendorStatusCreate = '/vendor/status/create';

  /// The vendor's own status with its comments; build with [vendorStatus].
  static const vendorStatusPattern = '/vendor/status/:id';
  static String vendorStatus(int id) => '/vendor/status/$id';

  /// The vendor's own stall as a customer sees it (read-only). Customers have
  /// /consumer/vendor/:id; vendors may not enter /consumer, so they get this.
  /// [tab] opens the `hygiene` or `reviews` tab.
  static const vendorStallPattern = '/vendor/stall/:id';
  static String vendorStall(int id, {String? tab}) => tab == null ? '/vendor/stall/$id' : '/vendor/stall/$id?tab=$tab';

  /// The Dashboard scrolls to [section] (`hours` or `menu`) when opened with it.
  static String vendorDashboardAt(String section) => '/vendor/dashboard?section=$section';

  /// App settings (language, notifications, privacy), shared by customers and vendors.
  static const appSettings = '/settings';

  /// Placeholder until the stall onboarding screen is built.
  static const vendorOnboarding = '/vendor/onboarding';

  static String homeFor(UserRole role) => switch (role) {
        UserRole.consumer => consumerHome,
        UserRole.vendor => vendorHome,
      };

  static String loginFor(UserRole role) => switch (role) {
        UserRole.consumer => consumerLogin,
        UserRole.vendor => vendorLogin,
      };

  /// Screens a signed-out person uses: role select, login and sign-up.
  static bool isAuthFlow(String location) =>
      location == roleSelect || location.startsWith('/login/') || location.startsWith('/signup/');
}
