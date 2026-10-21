import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_nav_bar.dart';

enum ConsumerTab { home, search, alerts, profile }

/// The consumer's floating bottom navigation: Home / Search / Alerts / Profile.
/// Search opens on top of the current screen (it has its own back button); the
/// other tabs replace the screen.
class ConsumerBottomNav extends StatelessWidget {
  const ConsumerBottomNav({super.key, required this.current});

  final ConsumerTab current;

  void _open(BuildContext context, ConsumerTab tab) {
    if (tab == current) return;

    switch (tab) {
      case ConsumerTab.home:
        context.go(Routes.consumerHome);
      case ConsumerTab.search:
        context.push(Routes.consumerSearch);
      case ConsumerTab.alerts:
        context.go(Routes.consumerAlerts);
      case ConsumerTab.profile:
        context.go(Routes.consumerProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingNavBar(
      items: [
        NavBarItem(Icons.home_rounded, context.l10n.navHome),
        NavBarItem(Icons.search_rounded, context.l10n.navSearch),
        NavBarItem(Icons.notifications_rounded, context.l10n.navAlerts),
        NavBarItem(Icons.person_rounded, context.l10n.navProfile),
      ],
      currentIndex: current.index,
      onTap: (index) => _open(context, ConsumerTab.values[index]),
    );
  }
}

/// A screen with the floating bottom nav. The body runs behind the nav, so give
/// scrolling content about 112px of bottom padding.
class ConsumerScaffold extends StatelessWidget {
  const ConsumerScaffold({super.key, required this.tab, required this.body});

  final ConsumerTab tab;
  final Widget body;

  /// Clearance a scrolling body leaves at the bottom for the floating nav.
  static const double navClearance = 112;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: body,
      bottomNavigationBar: ConsumerBottomNav(current: tab),
    );
  }
}
