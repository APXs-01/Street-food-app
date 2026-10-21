import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/json.dart';
import '../../../core/format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/presentation/widgets/coming_soon.dart';
import '../../social/providers/social_providers.dart';
import '../data/discovery_stall.dart';
import '../data/stall_detail_models.dart';
import '../presentation/widgets/stall_thumbnail.dart';
import '../providers/discovery_providers.dart';
import 'tabs/hygiene_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/reviews_tab.dart';
import 'widgets/frosted.dart';
import 'widgets/vendor_info_card.dart';
import 'widgets/vendor_profile_tabs.dart';

/// The vendor profile: one hero, one info card and one tab bar, with the body
/// swapping between Overview, Hygiene Breakdown and Reviews. Reached from every
/// "View" button and pin on the discovery screens.
class VendorProfileScreen extends ConsumerStatefulWidget {
  const VendorProfileScreen({
    super.key,
    required this.stallId,
    this.initialTab = VendorProfileTab.overview,
    this.readOnly = false,
  });

  final int stallId;

  /// The tab shown first (the vendor's Homepage links straight to Hygiene or Reviews).
  final VendorProfileTab initialTab;

  /// A vendor looking at their own stall as customers see it: no "Leave a Review".
  final bool readOnly;

  @override
  ConsumerState<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends ConsumerState<VendorProfileScreen> {
  /// How far the info card rides up over the bottom of the hero.
  static const _cardOverlap = 32.0;
  static const _heroHeight = 288.0;

  late VendorProfileTab _tab = widget.initialTab;
  ReviewFilter _reviewFilter = ReviewFilter.all;

  /// Whether this customer follows [stall]: what they just did in this run, else
  /// what the server said when the stall was loaded.
  bool _isSaved(DiscoveryStall stall) => ref.watch(followedStallsProvider)[stall.id] ?? stall.followedByMe ?? false;

  /// Saving a stall follows it (`POST` / `DELETE /vendors/{id}/follow`): that is
  /// what makes its statuses reach the saver's feed.
  Future<void> _toggleSaved(DiscoveryStall stall) async {
    final follow = !(ref.read(followedStallsProvider)[stall.id] ?? stall.followedByMe ?? false);
    final repository = ref.read(stallRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(followedStallsProvider.notifier).setFollowing(
            stall.id,
            follow: follow,
            send: () => repository.setFollowing(stall.id, follow: follow),
          );

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(follow ? l10n.vpFollowing(stall.name) : l10n.vpUnfollowed(stall.name))));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.readOnly ? Routes.vendorHome : Routes.consumerHome);
    }
  }

  void _leaveReview(DiscoveryStall stall) => context.push(Routes.consumerVendorReview(stall.id));

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(stallDetailProvider(widget.stallId));
    final stall = detail.asData?.value;

    if (stall == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(tooltip: context.l10n.commonBack, icon: const Icon(Icons.arrow_back), onPressed: _back),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: AsyncView<DiscoveryStall>(
              value: detail,
              onRetry: () => ref.invalidate(stallDetailProvider(widget.stallId)),
              builder: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    final saved = _isSaved(stall);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(
              stall: stall,
              height: _heroHeight,
              saved: saved,
              canSave: !widget.readOnly,
              onBack: _back,
              onSave: () => _toggleSaved(stall),
              onShare: () => showComingSoon(context, context.l10n.vpFeatureSharing),
            ),
            // The card, tabs and body ride up over the hero together. The 32px
            // of unused height this leaves at the very bottom is harmless.
            Transform.translate(
              offset: const Offset(0, -_cardOverlap),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VendorInfoCard(stall: stall),
                    const SizedBox(height: AppSpacing.lg),
                    VendorProfileTabs(
                      current: _tab,
                      reviewCount: stall.ratingCount,
                      onChanged: (tab) => setState(() => _tab = tab),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    switch (_tab) {
                      VendorProfileTab.overview => OverviewTab(
                          stall: stall,
                          onLeaveReview: widget.readOnly ? null : () => _leaveReview(stall),
                        ),
                      VendorProfileTab.hygiene => AsyncView<HygieneBreakdown>(
                          value: ref.watch(stallHygieneProvider(stall.id)),
                          onRetry: () => ref.invalidate(stallHygieneProvider(stall.id)),
                          compact: true,
                          builder: (hygiene) => HygieneTab(
                            stall: stall,
                            hygiene: hygiene,
                            onReadCommunityLogs: () => setState(() => _tab = VendorProfileTab.reviews),
                          ),
                        ),
                      VendorProfileTab.reviews => ReviewsTab(
                          stallId: stall.id,
                          filter: _reviewFilter,
                          onFilterChanged: (filter) => setState(() => _reviewFilter = filter),
                        ),
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ActionBar(
        stall: stall,
        // The hygiene tab offers bookmark beside the call button; the others offer share.
        showBookmark: _tab == VendorProfileTab.hygiene && !widget.readOnly,
        saved: saved,
        onBookmark: () => _toggleSaved(stall),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.stall,
    required this.height,
    required this.saved,
    required this.canSave,
    required this.onBack,
    required this.onSave,
    required this.onShare,
  });

  final DiscoveryStall stall;
  final double height;
  final bool saved;

  /// A vendor looking at their own stall cannot follow it.
  final bool canSave;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          StallThumbnail(url: stall.photoUrl, width: double.infinity, height: height, radius: 0, iconSize: 64),
          // Darkens the top so the buttons read on any photo, and the bottom a little for the badge.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99000000), Color(0x00000000), Color(0x40000000)],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          Positioned(
            top: topInset + AppSpacing.sm,
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            child: Row(
              children: [
                FrostedCircleButton(icon: Icons.arrow_back, tooltip: context.l10n.commonBack, onTap: onBack),
                const Spacer(),
                if (canSave) ...[
                  FrostedCircleButton(
                    icon: saved ? Icons.bookmark : Icons.bookmark_border,
                    tooltip: saved ? context.l10n.vpUnfollow : context.l10n.vpFollow,
                    iconColor: saved ? AppColors.secondary : null,
                    onTap: onSave,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                FrostedCircleButton(icon: Icons.ios_share, tooltip: context.l10n.vpShare, onTap: onShare),
              ],
            ),
          ),
          // Only a stall that has been inspected says when.
          if (stall.lastInspectedAt != null)
            Positioned(
              right: AppSpacing.screenPadding,
              bottom: 44,
              child: Frosted(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.vpInspected(agoFrom(stall.lastInspectedAt)),
                      style: AppTextStyles.caption.copyWith(color: AppColors.successText, letterSpacing: 0.2),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Call, share (or bookmark) and the big Directions button.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.stall, required this.showBookmark, required this.saved, required this.onBookmark});

  final DiscoveryStall stall;
  final bool showBookmark;
  final bool saved;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, AppSpacing.md),
          child: Row(
            children: [
              // Stalls have no phone number in the API yet.
              _OutlineCircle(
                icon: Icons.phone_outlined,
                tooltip: context.l10n.vpCall,
                onTap: () => showComingSoon(context, context.l10n.vpFeatureCalling),
              ),
              const SizedBox(width: AppSpacing.md),
              showBookmark
                  ? _OutlineCircle(
                      icon: saved ? Icons.bookmark : Icons.bookmark_border,
                      tooltip: saved ? context.l10n.vpUnfollow : context.l10n.vpFollow,
                      onTap: onBookmark,
                    )
                  : _OutlineCircle(
                      icon: Icons.ios_share,
                      tooltip: context.l10n.vpShare,
                      onTap: () => showComingSoon(context, context.l10n.vpFeatureSharing),
                    ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showComingSoon(context, context.l10n.commonDirections),
                  icon: const Icon(Icons.near_me, size: 18),
                  label: Text(
                    stall.hasDistance ? context.l10n.vpDirectionsDistance(stall.distanceShort) : context.l10n.commonDirections,
                    style: AppTextStyles.button,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.surface,
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineCircle extends StatelessWidget {
  const _OutlineCircle({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: CircleBorder(side: BorderSide(color: AppColors.border.withValues(alpha: 0.9))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 52, height: 52, child: Icon(icon, color: AppColors.textPrimary, size: 22)),
        ),
      ),
    );
  }
}
