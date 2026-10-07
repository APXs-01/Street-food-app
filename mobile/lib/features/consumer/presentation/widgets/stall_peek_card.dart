import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/discovery_stall.dart';
import 'hygiene_pills.dart';
import 'stall_thumbnail.dart';

/// A stall in the full map's bottom sheet: an 80px thumbnail with its rank, the
/// name with a "Clean" pill (once inspected), "Stall #N • Xm away • Open until..."
/// and the star rating ("New" while nobody has reviewed the stall).
class StallPeekCard extends StatelessWidget {
  const StallPeekCard({super.key, required this.stall, required this.rank, this.selected = false, this.onTap});

  final DiscoveryStall stall;
  final int rank;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.border.withValues(alpha: 0.5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap ?? () => context.push(Routes.consumerVendor(stall.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StallThumbnail(url: stall.photoUrl, width: 80, height: 80, badge: '#$rank'),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              stall.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyStrong.copyWith(fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (stall.hygiene != HygieneLevel.unrated)
                            CleanPill(label: stall.isCaution ? context.l10n.stallCaution : context.l10n.stallClean, caution: stall.isCaution),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [stall.stallNumberLabel, stall.distanceLabel, stall.openLabel].where((part) => part.isNotEmpty).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (var i = 0; i < 5; i++)
                            Icon(
                              i < stall.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 15,
                              color: AppColors.amber,
                            ),
                          const SizedBox(width: 6),
                          Text(stall.ratingLabel, style: AppTextStyles.bodyStrong.copyWith(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
