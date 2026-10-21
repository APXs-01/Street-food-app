import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/discovery_stall.dart';
import '../../presentation/widgets/hygiene_pills.dart';

/// The white card that overlaps the bottom of the hero: the hygiene pill, the
/// name, where the stall is, and three quick facts, all from the API.
class VendorInfoCard extends StatelessWidget {
  const VendorInfoCard({super.key, required this.stall});

  final DiscoveryStall stall;

  /// `A+ Grade`, `Needs work`, or `Not yet` before the first inspection.
  String get _grade {
    final grade = stall.hygieneGrade;

    if (grade == null || stall.hygiene == HygieneLevel.unrated) return l10n.vpGradeNone;
    if (grade == 'needs_improvement') return l10n.vpGradeNeedsWork;

    return l10n.vpGrade(grade);
  }

  String get _water {
    if (stall.hygiene == HygieneLevel.unrated) return l10n.vpGradeNone;

    return stall.waterSourceVerified ? l10n.vpWaterVerified : l10n.vpWaterUnverified;
  }

  @override
  Widget build(BuildContext context) {
    // Long names drop a size and wrap onto a second line.
    final nameSize = stall.name.length > 22 ? 20.0 : 26.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppShadows.cardBorder),
        boxShadow: const [BoxShadow(color: Color(0x1F0F172A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingHygienePill(
            rating: stall.ratingLabel,
            caption: hygieneCaption(stall),
            caution: stall.isCaution,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            stall.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.display.copyWith(fontSize: nameSize, height: 1.15, letterSpacing: -0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (stall.distanceLabel.isNotEmpty || stall.locationLabel.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.location_on, size: 15, color: AppColors.secondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [stall.distanceLabel, stall.locationLabel].where((part) => part.isNotEmpty).join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider()),
          Row(
            children: [
              Expanded(child: _Metric(value: _grade, caption: l10n.vpMetricFoodSafety)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _Metric(value: _water, caption: l10n.vpMetricWater)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Metric(
                  value: '${stall.ratingCount}',
                  caption: stall.ratingCount == 1 ? l10n.vpMetricReview : l10n.vpMetricReviews,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.softButton)),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTextStyles.bodyStrong.copyWith(fontSize: 14, color: AppColors.secondary)),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
