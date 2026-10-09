import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_nav_bar.dart';

enum VendorTab { home, dashboard, analytics, profile }

/// The vendor's floating bottom navigation: Home / Dashboard / Analytics /
/// Profile. (The Figma reuses the customer's Home / Search / Alerts / Profile on
/// two vendor screens; this is the standard for every vendor screen.)
class VendorBottomNav extends StatelessWidget {
  const VendorBottomNav({super.key, required this.current});

  final VendorTab current;

  static String _routeFor(VendorTab tab) => switch (tab) {
        VendorTab.home => Routes.vendorHome,
        VendorTab.dashboard => Routes.vendorDashboard,
        VendorTab.analytics => Routes.vendorAnalytics,
        VendorTab.profile => Routes.vendorProfile,
      };

  @override
  Widget build(BuildContext context) {
    return FloatingNavBar(
      items: [
        NavBarItem(Icons.home_rounded, context.l10n.navHome),
        NavBarItem(Icons.dashboard_rounded, context.l10n.navDashboard),
        NavBarItem(Icons.insights_rounded, context.l10n.navAnalytics),
        NavBarItem(Icons.person_rounded, context.l10n.navProfile),
      ],
      currentIndex: current.index,
      onTap: (index) {
        final tab = VendorTab.values[index];
        if (tab != current) context.go(_routeFor(tab));
      },
    );
  }
}

/// A vendor screen with the floating bottom nav, mirroring ConsumerScaffold.
/// The body runs behind the nav: leave [navClearance] at the bottom of scrolling content.
class VendorScaffold extends StatelessWidget {
  const VendorScaffold({super.key, required this.tab, required this.body});

  final VendorTab tab;
  final Widget body;

  static const double navClearance = 112;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: body,
      bottomNavigationBar: VendorBottomNav(current: tab),
    );
  }
}
