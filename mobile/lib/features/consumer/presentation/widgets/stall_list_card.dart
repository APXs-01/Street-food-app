import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/coming_soon.dart';
import '../../../auth/presentation/widgets/pill_badge.dart';
import '../../data/discovery_stall.dart';
import 'hygiene_pills.dart';
import 'stall_thumbnail.dart';

/// What the foot of a [StallListCard] shows.
enum StallCardFooter {
  /// "Directions (2 min)" and "View Menu" buttons.
  actions,

  /// A green "Order Pick-up" text link.
  link,

  /// The stall's dish categories as small tags (search results).
  tags,
}

/// A stall in a vertical list: the split screen's list and search results.
///
/// [number] is the stall's position, shown on the thumbnail and matching its
/// pin on the split screen's map. [selected] outlines the card in green. A tap
/// on the card calls [onTap]; the buttons in its footer do their own thing.
class StallListCard extends StatelessWidget {
  const StallListCard({
    super.key,
    required this.stall,
    required this.footer,
    this.number,
    this.selected = false,
    this.onTap,
  });

  final DiscoveryStall stall;
  final StallCardFooter footer;
  final int? number;
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
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap ?? () => context.push(Routes.consumerVendor(stall.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StallThumbnail(
                      url: stall.photoUrl,
                      width: 84,
                      height: 84,
                      badge: number == null ? null : '$number',
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stall.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.title.copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                [stall.stallNumberLabel, stall.distanceLabel].where((part) => part.isNotEmpty).join(' • '),
                                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                              ),
                              RatingHygienePill(
                                rating: stall.ratingLabel,
                                caption: hygieneCaption(stall),
                                caution: stall.isCaution,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (stall.dish.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    stall.dish,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    switch (footer) {
      case StallCardFooter.actions:
        return Row(
          children: [
            Expanded(
              flex: 5,
              child: FilledButton(
                onPressed: () => showComingSoon(context, context.l10n.commonDirections),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.surface,
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(stall.hasDistance ? context.l10n.stallWalkMinutes(stall.walkMinutes) : context.l10n.commonDirections, style: AppTextStyles.button.copyWith(fontSize: 12)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 4,
              child: OutlinedButton(
                onPressed: () => context.push(Routes.consumerVendor(stall.id)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(context.l10n.stallViewMenu, style: AppTextStyles.button.copyWith(fontSize: 12, color: AppColors.secondary)),
              ),
            ),
          ],
        );
      case StallCardFooter.link:
        return Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () => showComingSoon(context, context.l10n.stallFeaturePickup),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(context.l10n.stallOrderPickup, style: AppTextStyles.link.copyWith(color: AppColors.secondary)),
            ),
          ),
        );
      case StallCardFooter.tags:
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final category in stall.categories)
              PillBadge(
                label: category.label,
                background: AppColors.surfaceMuted,
                foreground: AppColors.textSecondary,
              ),
            if (!stall.isOpenNow)
              PillBadge(label: context.l10n.stallClosedNow, background: AppColors.borderLight, foreground: AppColors.textMuted),
          ],
        );
    }
  }
}
