import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/brand.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A translucent, blurred bar: back button, the green wordmark in the middle
/// (with an optional badge or a verified shield beside it) and an optional
/// widget on the right. Content scrolling under it shows through, blurred.
class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AuthAppBar({super.key, this.badge, this.trailing, this.showShield = false});

  final Widget? badge;
  final Widget? trailing;

  /// A small verified-shield icon after the wordmark (the customer sign-up bar).
  final bool showShield;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// A screen opened with go() has nothing to pop, so back returns to role select.
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.roleSelect);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      backgroundColor: AppColors.background.withValues(alpha: 0.82),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: const SizedBox.expand(),
        ),
      ),
      leading: IconButton(
        tooltip: context.l10n.commonBack,
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => goBack(context),
      ),
      centerTitle: true,
      // Scales down instead of overflowing when a badge sits beside the wordmark
      // on a narrow phone.
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(kBrandName, style: AppTextStyles.wordmark),
            if (showShield) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified_user, size: 18, color: AppColors.secondary),
            ],
            if (badge != null) ...[const SizedBox(width: AppSpacing.sm), badge!],
          ],
        ),
      ),
      actions: [trailing ?? const SizedBox.shrink(), const SizedBox(width: AppSpacing.sm)],
    );
  }
}
