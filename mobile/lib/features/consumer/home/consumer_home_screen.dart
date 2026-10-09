import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../notifications/providers/alerts_providers.dart';
import '../../statuses/data/status_models.dart';
import '../../statuses/providers/status_providers.dart';
import '../../vendor/onboarding/data/stall_category.dart';
import '../../vendor/onboarding/providers/onboarding_providers.dart';
import '../data/discovery_stall.dart';
import '../presentation/filter_sheet.dart';
import '../presentation/widgets/consumer_bottom_nav.dart';
import '../presentation/widgets/section_header.dart';
import '../providers/discovery_providers.dart';
import 'widgets/radar_preview.dart';
import 'widgets/stall_cards.dart';
import 'widgets/story_avatar.dart';

/// The consumer home: stories, the live hygiene radar, category chips, the best
/// rated stalls and the shops nearest to you. Everything comes from the API:
/// stories from the status feed, stalls from `/map/nearby` and `/vendors`.
class ConsumerHomeScreen extends ConsumerStatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  ConsumerState<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends ConsumerState<ConsumerHomeScreen> {
  /// "Nearby" on: nearest first. Off: best rated first.
  bool _sortByProximity = true;

  Future<void> _refresh() async {
    ref.invalidate(feedProvider);
    ref.invalidate(alertsProvider);
    ref.invalidate(searchCenterProvider);
    ref.invalidate(allStallsProvider);

    await ref.read(allStallsProvider.future).then((_) {}, onError: (_) {});
  }

  void _retryStalls() {
    ref.invalidate(searchCenterProvider);
    ref.invalidate(allStallsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allStallsProvider);
    final filtered = ref.watch(filteredStallsProvider);
    final filter = ref.watch(discoveryFilterProvider);
    final center = ref.watch(searchCenterProvider).asData?.value ?? SearchCenter.fallback;

    return ConsumerScaffold(
      tab: ConsumerTab.home,
      body: Column(
        children: [
          _HomeHeader(locationLabel: center.label),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: ConsumerScaffold.navClearance),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: context.l10n.homeStoriesTitle,
                      trailing: SectionLink(
                        label: context.l10n.homeStoriesCycle,
                        icon: Icons.schedule,
                        onTap: () => ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(context.l10n.homeStoriesCycleHint))),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _StoriesRow(),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      title: context.l10n.homeRadarTitle,
                      leadingIcon: Icons.radar,
                      trailing: InkWell(
                        onTap: () => context.push(Routes.consumerMap),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Text(
                            context.l10n.homeOpenMap,
                            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AsyncView<List<DiscoveryStall>>(
                      value: all,
                      onRetry: _retryStalls,
                      compact: true,
                      builder: (stalls) => stalls.isEmpty
                          ? EmptyNote(context.l10n.homeNoStallsNearby)
                          : RadarPreview(stalls: stalls, center: center),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      title: context.l10n.homeForYou,
                      trailing: SectionLink(label: context.l10n.homeFilterCategory, onTap: () => showFilterSheet(context)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CategoryChips(filter: filter),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      title: context.l10n.homeBestRated,
                      subtitle: context.l10n.homeBestRatedSub,
                      trailing: SectionLink(label: context.l10n.homeSeeAll, onTap: () => context.push(Routes.consumerMapSplit)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AsyncView<List<DiscoveryStall>>(
                      value: all,
                      onRetry: _retryStalls,
                      compact: true,
                      builder: (stalls) {
                        final bestRated = (stalls.where((stall) => stall.hasRating).toList()
                              ..sort((a, b) => b.rating.compareTo(a.rating)))
                            .take(3)
                            .toList();

                        if (bestRated.isEmpty) return EmptyNote(context.l10n.homeNoRatings);

                        return SizedBox(
                          height: 275,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                            itemCount: bestRated.length,
                            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) => BestRatingCard(stall: bestRated[index]),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      title: context.l10n.homeShopsNear,
                      subtitle: _sortByProximity
                          ? context.l10n.homeSortedByProximity(center.label)
                          : context.l10n.homeSortedByRating,
                      trailing: _NearbyToggle(
                        selected: _sortByProximity,
                        onTap: () => setState(() => _sortByProximity = !_sortByProximity),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AsyncView<List<DiscoveryStall>>(
                      value: filtered,
                      onRetry: _retryStalls,
                      builder: (stalls) {
                        final nearYou = _sortByProximity ? stalls : ([...stalls]..sort((a, b) => b.rating.compareTo(a.rating)));

                        if (nearYou.isEmpty) {
                          return EmptyNote(context.l10n.homeNoMatch);
                        }

                        return Column(
                          children: [
                            for (final stall in nearYou)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.md),
                                child: NearbyShopCard(stall: stall),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The stories row: one circle per person or stall with a live status in the feed.
class _StoriesRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<List<StatusPost>>(
      value: ref.watch(feedProvider),
      compact: true,
      onRetry: () => ref.invalidate(feedProvider),
      builder: (feed) {
        final stories = storiesFrom(feed);

        if (stories.isEmpty) {
          return EmptyNote(context.l10n.homeNoStories);
        }

        return SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            itemCount: stories.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => StoryAvatar(
              story: stories[index],
              onTap: () => context.push(Routes.consumerStatus(stories[index].statusId)),
            ),
          ),
        );
      },
    );
  }
}

/// The fixed 56px header: current spot on the left, the wordmark in the middle,
/// search and alerts on the right.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.locationLabel});

  /// "Current location", or the default area's name when GPS is unavailable.
  final String locationLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAlerts = ref.watch(unreadAlertsProvider) > 0;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(context.l10n.homeCurrentSpot, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0.55)),
                            Text(
                              locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(kBrandName, style: AppTextStyles.wordmark.copyWith(letterSpacing: -0.55)),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: context.l10n.commonSearch,
                        icon: const Icon(Icons.search, color: AppColors.textPrimary),
                        onPressed: () => context.push(Routes.consumerSearch),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            tooltip: context.l10n.commonAlerts,
                            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                            onPressed: () => context.go(Routes.consumerAlerts),
                          ),
                          if (hasAlerts)
                            Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.background, width: 1.5),
                              ),
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

/// "All" plus one chip per category. "All" is dark when selected; the rest are
/// white with an emoji and turn dark when picked.
class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.filter});

  final DiscoveryFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(discoveryFilterProvider.notifier);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        children: [
          _Chip(
            label: context.l10n.homeAll,
            selected: filter.categories.isEmpty,
            leading: Icon(
              Icons.grid_view_rounded,
              size: 16,
              color: filter.categories.isEmpty ? AppColors.surface : AppColors.textPrimary,
            ),
            onTap: () => notifier.selectOnlyCategory(null),
          ),
          // The categories the server knows; the chips are just "All" while they load.
          for (final category in ref.watch(categoriesProvider).asData?.value ?? const <StallCategory>[]) ...[
            const SizedBox(width: AppSpacing.sm),
            _Chip(
              label: category.label,
              selected: filter.categories.contains(category.slug),
              leading: Text(category.emoji, style: const TextStyle(fontSize: 15)),
              // Tapping the one that is already chosen goes back to "All".
              onTap: () => notifier.selectOnlyCategory(
                filter.categories.length == 1 && filter.categories.contains(category.slug) ? null : category.slug,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.leading, required this.onTap});

  final String label;
  final bool selected;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.textPrimary : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.textPrimary : AppColors.border.withValues(alpha: 0.7))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                leading,
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: selected ? AppColors.surface : AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NearbyToggle extends StatelessWidget {
  const _NearbyToggle({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: selected,
      label: context.l10n.homeSortByNearby,
      child: Material(
        color: selected ? AppColors.successBg : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.successBorder : AppColors.border.withValues(alpha: 0.7))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.near_me, size: 14, color: selected ? AppColors.secondary : AppColors.textMuted),
                const SizedBox(width: 5),
                Text(
                  context.l10n.homeNearbyToggle,
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: selected ? AppColors.successText : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
