import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/json.dart';
import '../../../../core/format.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../auth/presentation/widgets/pill_badge.dart';
import '../../../auth/presentation/widgets/surface_card.dart';
import '../../data/stall_detail_models.dart';
import '../../presentation/widgets/stall_thumbnail.dart';
import '../../providers/discovery_providers.dart';
import '../data/vendor_profile_data.dart';
import '../widgets/avatar_circle.dart';

/// How the review list is narrowed. Reviews already come newest first, and the
/// server has no "verified visit" notion, so those two Figma chips are gone.
enum ReviewFilter {
  all,
  withPhotos;

  /// The chip's text, in the language in use.
  String get label => switch (this) {
        ReviewFilter.all => l10n.reviewFilterAll,
        ReviewFilter.withPhotos => l10n.reviewFilterPhotos,
      };
}

/// Reviews: the rating summary, filter chips and the review list, read from
/// `GET /vendors/{id}/reviews` a page at a time. The chosen filter belongs to
/// the screen, so it survives switching tabs.
class ReviewsTab extends ConsumerStatefulWidget {
  const ReviewsTab({super.key, required this.stallId, required this.filter, required this.onFilterChanged});

  final int stallId;
  final ReviewFilter filter;
  final ValueChanged<ReviewFilter> onFilterChanged;

  @override
  ConsumerState<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<ReviewsTab> {
  /// Pages after the first, already fetched.
  final List<StallReview> _more = [];
  int _loadedPage = 1;
  bool? _hasMoreOverride;
  bool _loadingMore = false;
  String? _moreProblem;

  ({int id, bool withPhotos}) get _args => (id: widget.stallId, withPhotos: widget.filter == ReviewFilter.withPhotos);

  void _resetPaging() {
    _more.clear();
    _loadedPage = 1;
    _hasMoreOverride = null;
    _moreProblem = null;
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;

    setState(() {
      _loadingMore = true;
      _moreProblem = null;
    });

    try {
      final page = await ref.read(stallRepositoryProvider).reviews(widget.stallId, withPhotos: _args.withPhotos, page: _loadedPage + 1);

      if (!mounted) return;

      setState(() {
        _more.addAll(page.reviews);
        _loadedPage = page.currentPage;
        _hasMoreOverride = page.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _moreProblem = errorMessage(error);
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = ref.watch(stallReviewsProvider(_args));

    return AsyncView<ReviewsPage>(
      value: first,
      onRetry: () => ref.invalidate(stallReviewsProvider(_args)),
      builder: (page) {
        final reviews = [...page.reviews, ..._more];
        final hasMore = _hasMoreOverride ?? page.hasMore;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryCard(page: page),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ReviewFilter.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final filter = ReviewFilter.values[index];

                  return _FilterChip(
                    label: filter.label,
                    selected: filter == widget.filter,
                    onTap: () {
                      setState(_resetPaging);
                      widget.onFilterChanged(filter);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (reviews.isEmpty)
              EmptyNote(
                widget.filter == ReviewFilter.withPhotos ? context.l10n.reviewsNonePhotos : context.l10n.reviewsNone,
              )
            else
              for (final review in reviews) ...[
                _ReviewCard(review: review),
                const SizedBox(height: AppSpacing.md),
              ],
            if (_moreProblem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  _moreProblem!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error, letterSpacing: 0, fontWeight: FontWeight.w600),
                ),
              ),
            if (hasMore)
              Center(
                child: OutlinedButton(
                  onPressed: _loadingMore ? null : _loadMore,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: _loadingMore
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary))
                      : Text(context.l10n.reviewsLoadMore, style: AppTextStyles.bodyStrong.copyWith(color: AppColors.secondary)),
                ),
              )
            else if (reviews.isNotEmpty)
              Center(
                child: Text(
                  context.l10n.reviewsCaughtUp,
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.page});

  final ReviewsPage page;

  @override
  Widget build(BuildContext context) {
    final average = page.average;
    final counts = [for (var star = 5; star >= 1; star--) page.distribution[star] ?? 0];
    final maxCount = counts.reduce((a, b) => a > b ? a : b);

    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(average == null ? '–' : average.toStringAsFixed(1), style: AppTextStyles.display.copyWith(fontSize: 44, height: 1)),
              const SizedBox(height: 6),
              _Stars(rating: average?.round() ?? 0, size: 16),
              const SizedBox(height: 6),
              Text(
                context.l10n.reviewsBasedOn(page.count),
                style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text('${5 - i}★', style: AppTextStyles.caption.copyWith(letterSpacing: 0, color: AppColors.textMuted)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: maxCount == 0 ? 0 : counts[i] / maxCount,
                              minHeight: 6,
                              backgroundColor: AppColors.borderLight,
                              color: i < 2 ? AppColors.secondary : (i == 2 ? AppColors.primaryLight : AppColors.amber),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${counts[i]}',
                            textAlign: TextAlign.right,
                            style: AppTextStyles.caption.copyWith(letterSpacing: 0, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 14});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= rating ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: AppColors.amber),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.textPrimary : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.textPrimary : AppColors.border.withValues(alpha: 0.8))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: selected ? AppColors.surface : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.review});

  final StallReview review;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  static const _collapsedLimit = 120;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final text = review.comment?.trim() ?? '';
    final long = text.length > _collapsedLimit;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarCircle(name: review.displayName, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.displayName, style: AppTextStyles.bodyStrong),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _Stars(rating: review.rating),
                        const SizedBox(width: 8),
                        Text(agoFrom(review.createdAt), style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              maxLines: _expanded || !long ? null : 3,
              overflow: _expanded || !long ? TextOverflow.visible : TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
            ),
          ],
          if (long)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(_expanded ? context.l10n.reviewShowLess : context.l10n.reviewReadMore, style: AppTextStyles.link.copyWith(fontSize: 12, color: AppColors.secondary)),
              ),
            ),
          if (review.observations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final key in review.observations)
                  isNegativeObservation(key)
                      ? PillBadge(
                          label: reviewObservationLabel(key),
                          background: AppColors.amberBg,
                          foreground: AppColors.orangeAccentText,
                          borderColor: AppColors.orangeAccentBg,
                        )
                      : PillBadge(
                          label: reviewObservationLabel(key),
                          background: AppColors.successBg,
                          foreground: AppColors.successText,
                          borderColor: AppColors.successBorder,
                        ),
              ],
            ),
          ],
          if (review.hasPhotos) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final photo in review.photos) StallThumbnail(url: photo.url, width: 72, height: 72, radius: 12, iconSize: 22),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
