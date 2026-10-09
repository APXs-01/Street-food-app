import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/surface_card.dart';
import '../../../consumer/data/stall_detail_models.dart';
import 'initial_avatar.dart';

/// A short review as the vendor sees it: initial, name, when, a star pill and
/// the quote. Used on the Homepage and the Analytics screen. The reviewer's
/// name is "Anonymous customer" when they chose to post anonymously. A review
/// with no written comment shows only its stars.
class ReviewSnippetCard extends StatelessWidget {
  const ReviewSnippetCard({super.key, required this.review, this.compact = false});

  final StallReview review;

  /// Analytics shows one-line quotes; the Homepage shows up to three lines.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = review.comment?.trim() ?? '';

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialAvatar(name: review.displayName, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.displayName, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13)),
                    Text(agoFrom(review.createdAt), style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: AppColors.amber),
                    const SizedBox(width: 2),
                    Text('${review.rating}.0', style: AppTextStyles.caption.copyWith(color: AppColors.orangeAccentText, letterSpacing: 0)),
                  ],
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '"$text"',
              maxLines: compact ? 1 : 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}
