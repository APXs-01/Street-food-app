import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/pill_badge.dart';
import '../../data/discovery_stall.dart';
import '../../presentation/widgets/hygiene_pills.dart';
import '../../presentation/widgets/stall_thumbnail.dart';

/// A card in the "Best Rating Vendor Shop" row: a photo with the
/// "4.9 ★ Verified Clean" pill, the name, two lines about the food, then the
/// distance and closing time. A stall nobody has reviewed shows "New".
class BestRatingCard extends StatelessWidget {
  const BestRatingCard({super.key, required this.stall});

  final DiscoveryStall stall;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);

    return SizedBox(
      width: 256,
      height: 275,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
            border: Border.all(color: AppShadows.cardBorder),
            boxShadow: const [AppShadows.card],
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: () => context.push(Routes.consumerVendor(stall.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 144,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
                        child: StallThumbnail(url: stall.photoUrl, width: double.infinity, height: 144, radius: 0, iconSize: 40),
                      ),
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: RatingHygienePill(
                          rating: stall.ratingLabel,
                          caption: hygieneCaption(stall),
                          caution: stall.isCaution,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stall.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stall.dish,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            if (stall.hasDistance) ...[
                              const Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                              const SizedBox(width: 2),
                              Text(
                                stall.distanceLabel,
                                style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: AppColors.secondary),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              stall.openLabel,
                              style: AppTextStyles.bodyStrong.copyWith(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
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

/// A full-width card in "Shops Near You": a 96px thumbnail, the name with its
/// distance pill, the dish, the hygiene badge and whether it is open.
class NearbyShopCard extends StatelessWidget {
  const NearbyShopCard({super.key, required this.stall});

  final DiscoveryStall stall;

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
          boxShadow: const [AppShadows.card],
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => context.push(Routes.consumerVendor(stall.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StallThumbnail(url: stall.photoUrl, width: 96, height: 96),
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
                              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (stall.hasDistance) ...[
                            const SizedBox(width: AppSpacing.sm),
                            PillBadge(
                              label: stall.distanceShort,
                              background: AppColors.surfaceMuted,
                              foreground: AppColors.textSecondary,
                            ),
                          ],
                        ],
                      ),
                      if (stall.dish.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          stall.dish,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          HygieneBadge(stall.hygiene),
                          Text(
                            stall.openNowLabel,
                            style: AppTextStyles.bodyStrong.copyWith(
                              fontSize: 12,
                              color: !stall.isOpenNow
                                  ? AppColors.textMuted
                                  : (stall.isCaution ? AppColors.textSecondary : AppColors.secondary),
                            ),
                          ),
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
