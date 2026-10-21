import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/pill_badge.dart';
import '../../data/discovery_stall.dart';

/// "High Hygiene" in green with a shield, "Re-verification Pending" in amber with
/// a warning triangle, or "Not yet inspected" in grey.
class HygieneBadge extends StatelessWidget {
  const HygieneBadge(this.level, {super.key});

  final HygieneLevel level;

  @override
  Widget build(BuildContext context) {
    switch (level) {
      case HygieneLevel.pending:
        return PillBadge(
          label: context.l10n.hygieneReverificationPending,
          background: AppColors.amberBg,
          foreground: AppColors.orangeAccentText,
          borderColor: AppColors.orangeAccentBg,
          leading: const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.orangeAccentText),
        );
      case HygieneLevel.unrated:
        return PillBadge(
          label: context.l10n.hygieneNotInspected,
          background: AppColors.surfaceMuted,
          foreground: AppColors.textSecondary,
          leading: const Icon(Icons.shield_outlined, size: 13, color: AppColors.textMuted),
        );
      case HygieneLevel.verified:
      case HygieneLevel.high:
        return PillBadge(
          label: context.l10n.hygieneHigh,
          background: AppColors.successBg,
          foreground: AppColors.successText,
          borderColor: AppColors.successBorder,
          leading: const Icon(Icons.verified_user, size: 13, color: AppColors.secondary),
        );
    }
  }
}

/// "98% Clean".
class CleanPill extends StatelessWidget {
  const CleanPill({super.key, required this.label, this.caution = false});

  final String label;
  final bool caution;

  @override
  Widget build(BuildContext context) {
    return PillBadge(
      label: label,
      background: caution ? AppColors.amberBg : AppColors.successBg,
      foreground: caution ? AppColors.orangeAccentText : AppColors.successText,
      borderColor: caution ? AppColors.orangeAccentBg : AppColors.successBorder,
    );
  }
}

/// "4.9 ★ Verified Clean" on a photo, or "4.9" beside a caption on a list card.
/// A stall with no reviews shows "New".
class RatingHygienePill extends StatelessWidget {
  const RatingHygienePill({super.key, required this.rating, this.caption, this.caution = false});

  /// The rating text: `4.9`, or `New`.
  final String rating;
  final String? caption;
  final bool caution;

  @override
  Widget build(BuildContext context) {
    final foreground = caution ? AppColors.orangeAccentText : AppColors.successText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: caution ? AppColors.amberBg : AppColors.primaryLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: caution ? AppColors.orangeAccentBg : AppColors.secondary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(caution ? Icons.warning_amber_rounded : Icons.verified_user, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(rating, style: AppTextStyles.caption.copyWith(color: foreground, letterSpacing: 0)),
          if (caption != null) ...[
            const SizedBox(width: 4),
            Text(
              '★ $caption',
              style: AppTextStyles.caption.copyWith(color: foreground, letterSpacing: 0, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

/// The caption for a stall's rating pill: what its hygiene level says.
String hygieneCaption(DiscoveryStall stall) => switch (stall.hygiene) {
      HygieneLevel.verified => l10n.hygieneVerifiedClean,
      HygieneLevel.high => l10n.hygieneHigh,
      HygieneLevel.pending => l10n.hygieneNeedsRecheck,
      HygieneLevel.unrated => l10n.hygieneNotInspected,
    };
