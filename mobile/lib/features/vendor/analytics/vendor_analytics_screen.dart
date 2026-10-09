import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/presentation/widgets/coming_soon.dart';
import '../../auth/presentation/widgets/pill_badge.dart';
import '../../auth/presentation/widgets/primary_button.dart';
import '../../auth/presentation/widgets/surface_card.dart';
import '../../consumer/data/discovery_stall.dart';
import '../../consumer/data/stall_detail_models.dart';
import '../data/vendor_models.dart';
import '../presentation/widgets/no_stall_action.dart';
import '../presentation/widgets/review_snippet_card.dart';
import '../presentation/widgets/vendor_bottom_nav.dart';
import '../providers/vendor_providers.dart';
import 'widgets/rating_curve_chart.dart';

/// Vendor Analytics, from `GET /vendors/{id}/analytics`: the stall's star rating,
/// the scores of its last inspections (a trend of up to 10 points) and the likes
/// and comments across its live statuses. The server does not count views, so
/// that figure is shown as "not tracked" rather than as a number.
class VendorAnalyticsScreen extends ConsumerWidget {
  const VendorAnalyticsScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(vendorStallProvider);
    ref.invalidate(vendorAnalyticsProvider);
    ref.invalidate(vendorReviewsProvider);

    await ref.read(vendorAnalyticsProvider.future).then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stallAsync = ref.watch(vendorStallProvider);
    final stall = stallAsync.asData?.value;
    final analytics = ref.watch(vendorAnalyticsProvider);
    final reviews = ref.watch(vendorReviewsProvider);

    return VendorScaffold(
      tab: VendorTab.analytics,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, VendorScaffold.navClearance),
            children: [
              _Title(stall: stall),
              const SizedBox(height: AppSpacing.lg),
              if (stall != null) ...[
                _HygieneSummary(stall: stall),
                const SizedBox(height: AppSpacing.lg),
              ] else
                AsyncView<DiscoveryStall>(
                  value: stallAsync,
                  compact: true,
                  onRetry: () => ref.invalidate(vendorStallProvider),
                  errorAction: noStallAction,
                  builder: (_) => const SizedBox.shrink(),
                ),
              AsyncView<VendorAnalytics>(
                value: analytics,
                onRetry: () => ref.invalidate(vendorAnalyticsProvider),
                builder: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Metrics(data: data),
                    const SizedBox(height: AppSpacing.lg),
                    _TrendCard(trend: data.trend),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(context.l10n.vanFeedback, style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  if (reviews.hasValue && reviews.requireValue.count > 0)
                    PillBadge(
                      label: context.l10n.vanReviewCount(reviews.requireValue.count),
                      background: AppColors.successBg,
                      foreground: AppColors.successText,
                      borderColor: AppColors.successBorder,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AsyncView<ReviewsPage>(
                value: reviews,
                compact: true,
                onRetry: () => ref.invalidate(vendorReviewsProvider),
                builder: (page) {
                  if (page.reviews.isEmpty) return EmptyNote(context.l10n.vanNoReviews);

                  return Column(
                    children: [
                      for (final review in page.reviews.take(3)) ...[
                        ReviewSnippetCard(review: review, compact: true),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              // Not built: there is no badge graphic or QR code yet.
              PrimaryButton(
                label: context.l10n.vanShareBadge,
                trailingIcon: Icons.ios_share,
                onPressed: () => showComingSoon(context, context.l10n.vanFeatureShareBadge),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.commonComingSoonTag,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.stall});

  final DiscoveryStall? stall;

  @override
  Widget build(BuildContext context) {
    final isOpen = stall?.isOpenNow ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stall != null)
                Row(
                  children: [
                    const Icon(Icons.storefront, size: 13, color: AppColors.secondary),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        stall!.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 2),
              Text(context.l10n.vanTitle, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.15)),
            ],
          ),
        ),
        if (stall != null) ...[
          const SizedBox(width: AppSpacing.sm),
          PillBadge(
            label: isOpen ? context.l10n.vanLiveStall : context.l10n.vanClosed,
            uppercase: true,
            background: isOpen ? AppColors.successBg : AppColors.surfaceMuted,
            foreground: isOpen ? AppColors.successText : AppColors.textMuted,
            borderColor: isOpen ? AppColors.successBorder : AppColors.border.withValues(alpha: 0.6),
            leading: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: isOpen ? AppColors.secondary : AppColors.textMuted, shape: BoxShape.circle),
            ),
          ),
        ],
      ],
    );
  }
}

/// The inspector's current score and hygiene level.
class _HygieneSummary extends StatelessWidget {
  const _HygieneSummary({required this.stall});

  final DiscoveryStall stall;

  @override
  Widget build(BuildContext context) {
    final unrated = stall.hygiene == HygieneLevel.unrated;
    final caution = stall.isCaution;

    final String label = switch (stall.hygiene) {
      HygieneLevel.verified || HygieneLevel.high => context.l10n.hygieneVerifiedClean,
      HygieneLevel.pending => context.l10n.hygieneReverificationPending,
      HygieneLevel.unrated => context.l10n.hygieneNotInspected,
    };

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // A soft mint glow in the corner.
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.primaryLight.withValues(alpha: 0.5), AppColors.primaryLight.withValues(alpha: 0)]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PillBadge(
                        label: label,
                        background: unrated ? AppColors.surfaceMuted : (caution ? AppColors.amberBg : AppColors.successBg),
                        foreground: unrated ? AppColors.textSecondary : (caution ? AppColors.orangeAccentText : AppColors.successText),
                        borderColor: unrated ? AppColors.border : (caution ? AppColors.orangeAccentBg : AppColors.successBorder),
                        leading: Icon(
                          unrated ? Icons.shield_outlined : (caution ? Icons.warning_amber_rounded : Icons.verified_user),
                          size: 13,
                          color: unrated ? AppColors.textMuted : (caution ? AppColors.orangeAccentText : AppColors.secondary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(context.l10n.vanCurrentScore, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stall.hygieneScore == null ? '–' : stall.hygieneScore!.toStringAsFixed(1),
                            style: AppTextStyles.display.copyWith(fontSize: 48, height: 1),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('/ 5', style: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadii.card)),
                  child: const Icon(Icons.workspace_premium, color: AppColors.surface, size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.data});

  final VendorAnalytics data;

  @override
  Widget build(BuildContext context) {
    final views = data.views;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  label: context.l10n.vanCustomerRating,
                  icon: Icons.star_outline_rounded,
                  value: data.ratingAverage == null ? '–' : data.ratingAverage!.toStringAsFixed(1),
                  sub: data.ratingCount == 0 ? context.l10n.vanNoReviewsSub : context.l10n.vanReviewCountLower(data.ratingCount),
                  subColor: data.ratingCount == 0 ? AppColors.textMuted : AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  label: context.l10n.vanStatusLikes,
                  icon: Icons.favorite_border,
                  value: _format(data.likes),
                  sub: data.statuses == 0 ? context.l10n.vanNoLiveStatus : context.l10n.vanOnStatuses(data.statuses),
                  subColor: data.statuses == 0 ? AppColors.textMuted : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  label: context.l10n.vanStatusComments,
                  icon: Icons.chat_bubble_outline,
                  value: _format(data.comments),
                  sub: data.statuses == 0 ? context.l10n.vanNoLiveStatus : context.l10n.vanOnLive,
                  subColor: data.statuses == 0 ? AppColors.textMuted : AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  label: context.l10n.vanStatusViews,
                  icon: Icons.visibility_outlined,
                  value: views == null ? '–' : _format(views),
                  sub: views == null ? context.l10n.vanNotTracked : context.l10n.vanOnLive,
                  subColor: views == null ? AppColors.textMuted : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3720 becomes `3,720`.
  static String _format(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.sub,
    required this.subColor,
  });

  final String label;
  final IconData icon;
  final String value;
  final String sub;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Icon(icon, size: 18, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTextStyles.display.copyWith(fontSize: 30, height: 1.1)),
          ),
          const SizedBox(height: 4),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong.copyWith(fontSize: 11, color: subColor)),
        ],
      ),
    );
  }
}

/// The scores of the stall's latest inspections, oldest first, labelled by date.
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});

  final List<TrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final scores = [for (final point in trend) point.score];

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(context.l10n.vanTrendTitle, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800))),
              if (trend.isNotEmpty)
                PillBadge(
                  label: context.l10n.vanLastInspections(trend.length),
                  background: AppColors.surfaceMuted,
                  foreground: AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 2),
          if (trend.isEmpty)
            EmptyNote(context.l10n.vanNoInspections)
          else ...[
            Text(
              scores.length == 1
                  ? context.l10n.vanScoredOne(scores.first.toStringAsFixed(1))
                  : context.l10n.vanScoredRange(scores.first.toStringAsFixed(1), scores.last.toStringAsFixed(1)),
              style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            RatingCurveChart(
              values: scores,
              labels: [
                for (final point in trend) point.inspectedAt == null ? '' : context.l10n.vanChartDate(point.inspectedAt!.day, _monthName(context, point.inspectedAt!.month)),
              ],
              minY: _floorOfLow(scores),
              maxY: 5,
              step: 0.5,
              valueSuffix: '',
            ),
          ],
        ],
      ),
    );
  }

  static String _monthName(BuildContext context, int month) {
    final l10n = context.l10n;

    return [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr, l10n.monthMay, l10n.monthJun,
      l10n.monthJul, l10n.monthAug, l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ][month - 1];
  }

  /// The bottom of the plot: the lowest score rounded down to a half, at most 4.
  static double _floorOfLow(List<double> scores) {
    final lowest = scores.reduce((a, b) => a < b ? a : b);

    return ((lowest * 2).floor() / 2).clamp(0.0, 4.0);
  }
}
