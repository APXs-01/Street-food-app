import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/discovery_stall.dart';
import 'hygiene_pills.dart';

/// The compact card that appears over the map when a pin is tapped: a mint
/// thumbnail, the stall's name with its "% Clean" pill, the distance and place,
/// the star rating and a "View" button.
///
/// Used by the full map, the split screen and the home screen's map preview.
/// Tapping anywhere on it (or "View") opens the stall's profile unless [onView]
/// says otherwise.
class MapQuickInfoCard extends StatelessWidget {
  const MapQuickInfoCard({super.key, required this.stall, this.onView});

  final DiscoveryStall stall;
  final VoidCallback? onView;

  void _view(BuildContext context) {
    if (onView != null) {
      onView!();
    } else {
      context.push(Routes.consumerVendor(stall.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: AppShadows.cardBorder),
          boxShadow: const [BoxShadow(color: Color(0x240F172A), blurRadius: 18, offset: Offset(0, 6))],
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => _view(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadii.softButton),
                  ),
                  child: const Icon(Icons.restaurant, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              stall.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                            ),
                          ),
                          if (stall.cleanPercent != null) ...[
                            const SizedBox(width: 6),
                            CleanPill(label: context.l10n.stallCleanPercent(stall.cleanPercent!), caution: stall.isCaution),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              [stall.distanceLabel, stall.locationLabel].where((part) => part.isNotEmpty).join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                          const SizedBox(width: 2),
                          Text(stall.ratingLabel, style: AppTextStyles.bodyStrong.copyWith(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () => _view(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.surface,
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(context.l10n.commonView, style: AppTextStyles.button.copyWith(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
