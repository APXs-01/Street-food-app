import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/json.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/presentation/widgets/pill_badge.dart';
import '../../auth/presentation/widgets/surface_card.dart';
import '../../consumer/data/discovery_stall.dart';
import '../../consumer/data/stall_detail_models.dart';
import '../../consumer/presentation/widgets/section_header.dart';
import '../../consumer/presentation/widgets/stall_thumbnail.dart';
import '../../notifications/providers/alerts_providers.dart';
import '../../statuses/data/status_models.dart';
import '../../statuses/providers/status_providers.dart';
import '../presentation/widgets/no_stall_action.dart';
import '../presentation/widgets/review_snippet_card.dart';
import '../presentation/widgets/vendor_bottom_nav.dart';
import '../providers/vendor_providers.dart';

/// The vendor's landing screen after sign-in: stall identity and live status,
/// hygiene, the live status's engagement, quick controls and recent reviews.
/// Everything is read from the API through [vendorStallProvider],
/// [vendorLiveStatusesProvider] and [vendorReviewsProvider].
class VendorHomeScreen extends ConsumerWidget {
  const VendorHomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(vendorStallProvider);
    ref.invalidate(myStatusesProvider);
    ref.invalidate(vendorReviewsProvider);
    ref.invalidate(alertsProvider);

    await ref.read(vendorStallProvider.future).then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stall = ref.watch(vendorStallProvider);

    return VendorScaffold(
      tab: VendorTab.home,
      body: stall.hasValue
          ? Column(
              children: [
                _Header(stall: stall.requireValue),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _refresh(ref),
                    child: _Body(stall: stall.requireValue),
                  ),
                ),
              ],
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: AsyncView<DiscoveryStall>(
                    value: stall,
                    onRetry: () => ref.invalidate(vendorStallProvider),
                    errorAction: noStallAction,
                    builder: (_) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.stall});

  final DiscoveryStall stall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(vendorLiveStatusesProvider);
    final reviews = ref.watch(vendorReviewsProvider);
    final active = statuses.asData?.value.firstOrNull;
    final now = DateTime.now();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: VendorScaffold.navClearance),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: _HygieneBanner(stall: stall, onTap: () => context.push(Routes.vendorStall(stall.id, tab: 'hygiene'))),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: AsyncView<List<StatusPost>>(
            value: statuses,
            compact: true,
            onRetry: () => ref.invalidate(myStatusesProvider),
            builder: (_) => _StoryPerformanceCard(
              status: active,
              now: now,
              onTap: () => active == null ? context.push(Routes.vendorStatusCreate) : context.push(Routes.vendorStatus(active.id)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: context.l10n.vhQuickControls),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: _QuickControls(stallId: stall.id),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: context.l10n.vhRecentReviews,
          subtitle: context.l10n.vhRecentReviewsSub,
          trailing: SectionLink(
            label: reviews.hasValue ? context.l10n.vhSeeAllCount(reviews.requireValue.count) : context.l10n.vhSeeAll,
            onTap: () => context.push(Routes.vendorStall(stall.id, tab: 'reviews')),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncView<ReviewsPage>(
          value: reviews,
          compact: true,
          onRetry: () => ref.invalidate(vendorReviewsProvider),
          builder: (page) {
            if (page.reviews.isEmpty) return EmptyNote(context.l10n.vhNoReviews);

            return Column(
              children: [
                for (final review in page.reviews.take(3))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.md),
                    child: ReviewSnippetCard(review: review),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Stall photo and identity, the open/closed pill and the notification bell.
class _Header extends ConsumerStatefulWidget {
  const _Header({required this.stall});

  final DiscoveryStall stall;

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  bool _busy = false;

  Future<void> _toggleOpen() async {
    if (_busy) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    try {
      await ref.read(vendorStallProvider.notifier).setOpen(!widget.stall.isOpenNow);
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stall = widget.stall;
    final unread = ref.watch(unreadAlertsProvider);
    final subtitle = [stall.stallNumberLabel, stall.locationLabel].where((part) => part.isNotEmpty).join(' • ');

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
          child: Row(
            children: [
              ClipOval(child: StallThumbnail(url: stall.photoUrl, width: 44, height: 44, radius: 22, iconSize: 22)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stall.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _OpenPill(isOpen: stall.isOpenNow, busy: _busy, onTap: _toggleOpen),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: context.l10n.commonNotifications,
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                    onPressed: () => context.push(Routes.vendorAlerts),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.background, width: 1.5),
                        ),
                        child: Text(
                          '$unread',
                          style: AppTextStyles.caption.copyWith(color: AppColors.surface, fontSize: 9, letterSpacing: 0),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenPill extends StatelessWidget {
  const _OpenPill({required this.isOpen, required this.busy, required this.onTap});

  final bool isOpen;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isOpen,
      label: isOpen ? context.l10n.vhOpenNowTap : context.l10n.vhClosedTap,
      child: Material(
        color: isOpen ? AppColors.successBg : AppColors.surfaceMuted,
        shape: StadiumBorder(side: BorderSide(color: isOpen ? AppColors.successBorder : AppColors.border.withValues(alpha: 0.7))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Text(
              isOpen ? context.l10n.vhPillOpen : context.l10n.vhPillClosed,
              style: AppTextStyles.caption.copyWith(
                letterSpacing: 0.3,
                color: isOpen ? AppColors.successText : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The inspector's score out of 5 and the hygiene level. A stall nobody has
/// inspected yet says so instead of showing a number.
class _HygieneBanner extends StatelessWidget {
  const _HygieneBanner({required this.stall, required this.onTap});

  final DiscoveryStall stall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final caution = stall.isCaution;
    final unrated = stall.hygiene == HygieneLevel.unrated;
    final radius = BorderRadius.circular(AppRadii.card);

    final String label = switch (stall.hygiene) {
      HygieneLevel.verified || HygieneLevel.high => context.l10n.hygieneVerifiedClean,
      HygieneLevel.pending => context.l10n.hygieneReverificationPending,
      HygieneLevel.unrated => context.l10n.hygieneNotInspected,
    };

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: unrated ? AppColors.border : (caution ? AppColors.amber : AppColors.secondary), width: 1.5),
          boxShadow: const [AppShadows.card],
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.vhHygieneScore, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            stall.hygieneScore == null ? '–' : stall.hygieneScore!.toStringAsFixed(1),
                            style: AppTextStyles.display.copyWith(fontSize: 36, height: 1),
                          ),
                          const SizedBox(width: 4),
                          Text('/ 5', style: AppTextStyles.body.copyWith(fontSize: 14, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                PillBadge(
                  label: label,
                  uppercase: true,
                  background: unrated ? AppColors.surfaceMuted : (caution ? AppColors.amberBg : AppColors.successBg),
                  foreground: unrated ? AppColors.textSecondary : (caution ? AppColors.orangeAccentText : AppColors.successText),
                  borderColor: unrated ? AppColors.border : (caution ? AppColors.orangeAccentBg : AppColors.successBorder),
                  leading: Icon(
                    unrated ? Icons.shield_outlined : (caution ? Icons.warning_amber_rounded : Icons.verified_user),
                    size: 13,
                    color: unrated ? AppColors.textMuted : (caution ? AppColors.orangeAccentText : AppColors.secondary),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The newest live status and its likes and comments. The server does not count
/// views, so there is no views figure.
class _StoryPerformanceCard extends StatelessWidget {
  const _StoryPerformanceCard({required this.status, required this.now, required this.onTap});

  final StatusPost? status;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final post = status;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.vhStatusCardTitle,
                      style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (post != null)
                    PillBadge(
                      label: post.expiresInLabelAt(now),
                      background: AppColors.amberBg,
                      foreground: AppColors.orangeAccentText,
                      borderColor: AppColors.amber.withValues(alpha: 0.45),
                      leading: const Icon(Icons.schedule, size: 12, color: AppColors.orangeAccentText),
                    )
                  else
                    PillBadge(label: context.l10n.vhNoneLive, background: AppColors.surfaceMuted, foreground: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (post == null)
                Text(
                  context.l10n.vhNoStatusBody,
                  style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textMuted),
                )
              else
                Row(
                  children: [
                    _Stat(icon: Icons.favorite_border, value: post.likesCount, label: context.l10n.vhStatLikes),
                    const _Dot(),
                    _Stat(icon: Icons.chat_bubble_outline, value: post.commentsCount, label: context.l10n.vhStatComments),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  text: '$value ',
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                  children: [TextSpan(text: label, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted))],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle),
    );
  }
}

class _QuickControls extends StatelessWidget {
  const _QuickControls({required this.stallId});

  final int stallId;

  @override
  Widget build(BuildContext context) {
    final post = _ControlCard(
      icon: Icons.add_a_photo_outlined,
      iconBackground: AppColors.primaryLight,
      iconColor: AppColors.primary,
      title: context.l10n.vhPostStatus,
      description: context.l10n.vhPostStatusDesc,
      onTap: () => context.push(Routes.vendorStatusCreate),
    );
    final menu = _ControlCard(
      icon: Icons.restaurant_menu,
      iconBackground: AppColors.orangeAccentBg,
      iconColor: AppColors.orangeAccentText,
      title: context.l10n.vhUpdateMenu,
      description: context.l10n.vhUpdateMenuDesc,
      onTap: () => context.go(Routes.vendorDashboardAt('menu')),
    );
    final hours = _ControlCard(
      icon: Icons.schedule,
      iconBackground: AppColors.borderLight,
      iconColor: AppColors.textSecondary,
      title: context.l10n.vhUpdateHours,
      description: context.l10n.vhUpdateHoursDesc,
      onTap: () => context.go(Routes.vendorDashboardAt('hours')),
    );
    final profile = _ControlCard(
      icon: Icons.storefront_outlined,
      iconBackground: AppColors.lavenderBg,
      iconColor: AppColors.lavender,
      title: context.l10n.vhViewProfile,
      description: context.l10n.vhViewProfileDesc,
      onTap: () => context.push(Routes.vendorStall(stallId)),
    );

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: post), const SizedBox(width: AppSpacing.md), Expanded(child: menu)],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: hours), const SizedBox(width: AppSpacing.md), Expanded(child: profile)],
          ),
        ),
      ],
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(AppRadii.softButton)),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(title, style: AppTextStyles.bodyStrong.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
                const Spacer(),
                const SizedBox(height: AppSpacing.sm),
                Text(context.l10n.vhSingleTap, style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.secondary, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
