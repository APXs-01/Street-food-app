import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/consumer_login_screen.dart';
import '../../features/auth/presentation/consumer_signup_screen.dart';
import '../../features/auth/presentation/role_select_screen.dart';
import '../../features/auth/presentation/vendor_login_screen.dart';
import '../../features/auth/presentation/vendor_signup_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/consumer/alerts/consumer_alerts_screen.dart';
import '../../features/consumer/profile/status_history_screen.dart';
import '../../features/inspector/inspector_checklist_screen.dart';
import '../../features/notifications/presentation/vendor_alerts_screen.dart';
import '../../features/settings/presentation/app_settings_screen.dart';
import '../../features/social/presentation/friends_screen.dart';
import '../../features/consumer/home/consumer_home_screen.dart';
import '../../features/consumer/presentation/full_map_screen.dart';
import '../../features/consumer/presentation/map_split_screen.dart';
import '../../features/consumer/presentation/search_screen.dart';
import '../../features/consumer/profile/consumer_profile_screen.dart';
import '../../features/consumer/vendor_profile/review_upload_screen.dart';
import '../../features/consumer/vendor_profile/vendor_profile_screen.dart';
import '../../features/consumer/vendor_profile/widgets/vendor_profile_tabs.dart';
import '../../features/vendor/analytics/vendor_analytics_screen.dart';
import '../../features/vendor/dashboard/vendor_dashboard_screen.dart';
import '../../features/vendor/home/vendor_home_screen.dart';
import '../../features/vendor/profile/vendor_account_screen.dart';
import '../../features/vendor/status/create_status_screen.dart';
import '../../features/vendor/status/status_detail_screen.dart';
import '../../features/vendor/onboarding/presentation/vendor_onboarding_screen.dart';
import '../models/user_role.dart';
import 'routes.dart';

/// Where a request for [location] should actually go, or null to allow it.
///
/// - Signed out: only role select, login and sign-up are open; anything else
///   goes to role select.
/// - Signed in: the auth screens are skipped, and each role stays inside its
///   own area (a consumer asking for /vendor/... lands on the consumer home).
/// - A vendor with no stall yet ([vendorHasStall] false) is taken to stall
///   onboarding instead of the home screen; once the stall exists the
///   onboarding screen redirects to the home screen. Null means not known yet
///   (a saved session that the server has not confirmed), which changes nothing.
String? resolveRedirect({required UserRole? role, required String location, bool? vendorHasStall}) {
  if (role == null) {
    return Routes.isAuthFlow(location) ? null : Routes.roleSelect;
  }

  var home = Routes.homeFor(role);

  if (role == UserRole.vendor) {
    if (vendorHasStall == false) {
      // Nothing else on the vendor side works without a stall.
      home = Routes.vendorOnboarding;
      if (location.startsWith('/vendor') && location != Routes.vendorOnboarding) return home;
    }

    if (vendorHasStall == true && location == Routes.vendorOnboarding) return Routes.vendorHome;
  }

  if (Routes.isAuthFlow(location)) return home;
  if (location.startsWith('/consumer') && role != UserRole.consumer) return home;
  if (location.startsWith('/vendor') && role != UserRole.vendor) return home;

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever the signed-in role, the vendor's stall, or
  // whether the server has confirmed the user changes (login, logout, expired
  // token, stall created, saved session confirmed). Other auth state changes,
  // such as a request starting, do not. "Confirmed" must be part of this: a
  // vendor with no stall looks the same (vendorId null) before and after the
  // server answers, yet only after it answers can they be sent to onboarding.
  final refresh = ValueNotifier<int>(0);
  ref.listen<(UserRole?, int?, bool)>(
    authControllerProvider.select((state) => (state.session?.role, state.session?.user?.vendorId, state.session?.user != null)),
    (previous, next) => refresh.value++,
  );

  final router = GoRouter(
    initialLocation: Routes.roleSelect,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(authControllerProvider).session;
      final user = session?.user;

      return resolveRedirect(
        role: session?.role,
        location: state.matchedLocation,
        vendorHasStall: user == null ? null : user.vendorId != null,
      );
    },
    routes: [
      GoRoute(path: Routes.roleSelect, builder: (context, state) => const RoleSelectScreen()),
      GoRoute(path: Routes.consumerLogin, builder: (context, state) => const ConsumerLoginScreen()),
      GoRoute(path: Routes.consumerSignup, builder: (context, state) => const ConsumerSignupScreen()),
      GoRoute(path: Routes.vendorLogin, builder: (context, state) => const VendorLoginScreen()),
      GoRoute(path: Routes.vendorSignup, builder: (context, state) => const VendorSignupScreen()),
      GoRoute(path: Routes.consumerHome, builder: (context, state) => const ConsumerHomeScreen()),
      GoRoute(path: Routes.consumerSearch, builder: (context, state) => const SearchScreen()),
      GoRoute(path: Routes.consumerMap, builder: (context, state) => const FullMapScreen()),
      GoRoute(path: Routes.consumerMapSplit, builder: (context, state) => const MapSplitScreen()),
      GoRoute(path: Routes.consumerAlerts, builder: (context, state) => const ConsumerAlertsScreen()),
      GoRoute(path: Routes.consumerProfile, builder: (context, state) => const ConsumerProfileScreen()),
      GoRoute(
        path: Routes.consumerVendorPattern,
        builder: (context, state) => VendorProfileScreen(stallId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      ),
      GoRoute(
        path: Routes.consumerVendorReviewPattern,
        builder: (context, state) => ReviewUploadScreen(stallId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      ),
      GoRoute(path: Routes.consumerFriends, builder: (context, state) => const FriendsScreen()),
      // "create" and "history" must come before ":id" so they are not read as a status id.
      GoRoute(path: Routes.consumerStatusCreate, builder: (context, state) => const CreateStatusScreen(asConsumer: true)),
      GoRoute(path: Routes.consumerStatusHistory, builder: (context, state) => const StatusHistoryScreen()),
      GoRoute(
        path: Routes.consumerStatusPattern,
        builder: (context, state) => StatusDetailScreen(statusId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      ),
      GoRoute(path: Routes.vendorHome, builder: (context, state) => const VendorHomeScreen()),
      GoRoute(
        path: Routes.vendorDashboard,
        builder: (context, state) => VendorDashboardScreen(initialSection: state.uri.queryParameters['section']),
      ),
      GoRoute(path: Routes.vendorAnalytics, builder: (context, state) => const VendorAnalyticsScreen()),
      GoRoute(path: Routes.vendorProfile, builder: (context, state) => const VendorAccountScreen()),
      GoRoute(path: Routes.vendorAlerts, builder: (context, state) => const VendorAlertsScreen()),
      // Not linked from anywhere: the app has no inspector sign-in yet.
      GoRoute(path: Routes.inspectorChecklist, builder: (context, state) => const InspectorChecklistScreen()),
      // "create" must come before ":id" so it is not read as a status id.
      GoRoute(path: Routes.vendorStatusCreate, builder: (context, state) => const CreateStatusScreen()),
      GoRoute(
        path: Routes.vendorStatusPattern,
        builder: (context, state) => StatusDetailScreen(
          statusId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ownerView: true,
        ),
      ),
      GoRoute(
        path: Routes.vendorStallPattern,
        builder: (context, state) => VendorProfileScreen(
          stallId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          readOnly: true,
          initialTab: switch (state.uri.queryParameters['tab']) {
            'hygiene' => VendorProfileTab.hygiene,
            'reviews' => VendorProfileTab.reviews,
            _ => VendorProfileTab.overview,
          },
        ),
      ),
      GoRoute(path: Routes.appSettings, builder: (context, state) => const AppSettingsScreen()),
      GoRoute(path: Routes.vendorOnboarding, builder: (context, state) => const VendorOnboardingScreen()),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });

  return router;
});
