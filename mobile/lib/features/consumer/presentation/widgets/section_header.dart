import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/pill_badge.dart';

/// A section title with an optional subtitle and a widget on the right (a link,
/// a toggle, a location label).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing, this.leadingIcon});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 6),
                    ],
                    Flexible(child: Text(title, style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800))),
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
        ],
      ),
    );
  }
}

/// The green count pill beside a title: "18".
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return PillBadge(
      label: '$count',
      background: AppColors.successBg,
      foreground: AppColors.successText,
      borderColor: AppColors.successBorder,
    );
  }
}

/// The small green link on the right of a section header: "See all", "24h cycle".
class SectionLink extends StatelessWidget {
  const SectionLink({super.key, required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: AppColors.secondary), const SizedBox(width: 4)],
            Text(label, style: AppTextStyles.link.copyWith(fontSize: 12, color: AppColors.secondary)),
          ],
        ),
      ),
    );
  }
}
