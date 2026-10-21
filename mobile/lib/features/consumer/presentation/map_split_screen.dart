import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/presentation/widgets/coming_soon.dart';
import '../data/discovery_stall.dart';
import '../providers/discovery_providers.dart';
import 'filter_sheet.dart';
import 'widgets/map_layout.dart';
import 'widgets/map_pins.dart';
import 'widgets/simulated_map.dart';
import 'widgets/stall_list_card.dart';

enum _Sort { distance, rating }

/// Half map, half list. Pins are numbered to match the cards; tapping one
/// highlights and scrolls to its card and tapping a card highlights its pin.
/// The grip at the bottom of the map resizes the two halves.
class MapSplitScreen extends ConsumerStatefulWidget {
  const MapSplitScreen({super.key});

  @override
  ConsumerState<MapSplitScreen> createState() => _MapSplitScreenState();
}

class _MapSplitScreenState extends ConsumerState<MapSplitScreen> {
  static const _minMapFraction = 0.25;
  static const _maxMapFraction = 0.70;

  final Map<int, GlobalKey> _cardKeys = {};

  double _mapFraction = 0.5;
  int? _selectedId;
  bool _highHygieneOnly = false;
  bool _compact = false;
  _Sort _sort = _Sort.distance;

  GlobalKey _keyFor(int id) => _cardKeys.putIfAbsent(id, GlobalKey.new);

  /// The stalls shown, in list order. Numbers on pins and thumbnails are positions in this list.
  AsyncValue<List<DiscoveryStall>> _stalls() {
    return ref.watch(filteredStallsProvider).whenData((all) {
      final stalls = all
          .where((s) => !_highHygieneOnly || s.hygiene == HygieneLevel.verified || s.hygiene == HygieneLevel.high)
          .toList();

      if (_sort == _Sort.rating) {
        stalls.sort((a, b) => b.rating.compareTo(a.rating));
      }

      return stalls;
    });
  }

  void _retry() {
    ref.invalidate(searchCenterProvider);
    ref.invalidate(allStallsProvider);
  }

  void _select(int id, {required bool scrollToCard}) {
    setState(() => _selectedId = id);

    if (!scrollToCard) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _keyFor(id).currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = _stalls();
    final stalls = async.asData?.value ?? const <DiscoveryStall>[];
    final filter = ref.watch(discoveryFilterProvider);
    final center = ref.watch(searchCenterProvider).asData?.value ?? SearchCenter.fallback;
    final selectedId = stalls.any((s) => s.id == _selectedId) ? _selectedId : (stalls.isEmpty ? null : stalls.first.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(label: center.label, filterActive: filter.isActive, onFilter: () => showFilterSheet(context)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final total = constraints.maxHeight;
                  final mapHeight = total * _mapFraction;

                  return Column(
                    children: [
                      SizedBox(
                        height: mapHeight,
                        child: _MapHalf(
                          stalls: stalls,
                          center: center,
                          loaded: async.hasValue,
                          selectedId: selectedId,
                          radiusKm: filter.radiusKm,
                          onLocate: _retry,
                          onPin: (id) => _select(id, scrollToCard: true),
                          onResize: (dy) => setState(
                            () => _mapFraction = (_mapFraction + dy / total).clamp(_minMapFraction, _maxMapFraction),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _ListHalf(
                          value: async,
                          onRetry: _retry,
                          stalls: stalls,
                          selectedId: selectedId,
                          highHygieneOnly: _highHygieneOnly,
                          compact: _compact,
                          sort: _sort,
                          keyFor: _keyFor,
                          onSelect: (id) => _select(id, scrollToCard: false),
                          onToggleHighHygiene: () => setState(() => _highHygieneOnly = !_highHygieneOnly),
                          onToggleCompact: () => setState(() => _compact = !_compact),
                          onSort: (sort) => setState(() => _sort = sort),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.label, required this.filterActive, required this.onFilter});

  /// "Current location", or the default area's name when GPS is unavailable.
  final String label;
  final bool filterActive;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.commonBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.canPop() ? context.pop() : context.go(Routes.consumerHome),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.splitLiveRadar, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 15, color: AppColors.secondary),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: context.l10n.mapFilters,
                icon: const Icon(Icons.tune, color: AppColors.textPrimary),
                onPressed: onFilter,
              ),
              if (filterActive)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: context.l10n.commonAlerts,
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
            onPressed: () => context.go(Routes.consumerAlerts),
          ),
        ],
      ),
    );
  }
}

class _MapHalf extends StatelessWidget {
  const _MapHalf({
    required this.stalls,
    required this.center,
    required this.loaded,
    required this.selectedId,
    required this.radiusKm,
    required this.onLocate,
    required this.onPin,
    required this.onResize,
  });

  final List<DiscoveryStall> stalls;
  final SearchCenter center;
  final bool loaded;
  final int? selectedId;
  final double radiusKm;
  final VoidCallback onLocate;
  final ValueChanged<int> onPin;
  final ValueChanged<double> onResize;

  @override
  Widget build(BuildContext context) {
    final radiusLabel = context.l10n.commonDistanceKm(
      radiusKm == radiusKm.roundToDouble() ? '${radiusKm.round()}' : radiusKm.toStringAsFixed(1),
    );
    final spots = layoutOnMap(stalls, center);

    return Stack(
      children: [
        Positioned.fill(
          child: SimulatedMap(
            placements: [
              MapPlacement(x: kMapCentre.x, y: kMapCentre.y, centered: true, child: const UserLocationDot()),
              for (var i = 0; i < stalls.length; i++)
                if (stalls[i].id != selectedId && spots[stalls[i].id] != null)
                  MapPlacement(
                    x: spots[stalls[i].id]!.x,
                    y: spots[stalls[i].id]!.y,
                    child: NumberedPin(number: i + 1, selected: false, onTap: () => onPin(stalls[i].id)),
                  ),
              for (var i = 0; i < stalls.length; i++)
                if (stalls[i].id == selectedId && spots[stalls[i].id] != null)
                  MapPlacement(
                    x: spots[stalls[i].id]!.x,
                    y: spots[stalls[i].id]!.y,
                    child: NumberedPin(number: i + 1, selected: true, onTap: () => onPin(stalls[i].id)),
                  ),
            ],
          ),
        ),
        Positioned(
          left: AppSpacing.md,
          top: AppSpacing.md,
          right: 72,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Text(
                loaded ? context.l10n.splitShowing(stalls.length, radiusLabel) : context.l10n.mapFinding,
                style: AppTextStyles.bodyStrong.copyWith(fontSize: 12),
              ),
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.md,
          bottom: 30,
          child: Column(
            children: [
              _SmallMapButton(icon: Icons.layers_outlined, onTap: () => showComingSoon(context, context.l10n.mapLayers)),
              const SizedBox(height: AppSpacing.sm),
              _SmallMapButton(
                icon: Icons.my_location,
                filled: true,
                onTap: onLocate,
              ),
            ],
          ),
        ),
        // The grip: drag it to give the map or the list more room.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) => onResize(details.delta.dy),
            child: Center(
              child: Container(
                width: 88,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallMapButton extends StatelessWidget {
  const _SmallMapButton({required this.icon, required this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.secondary : AppColors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: const Color(0x40000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 20, color: filled ? AppColors.surface : AppColors.textPrimary)),
      ),
    );
  }
}

class _ListHalf extends StatelessWidget {
  const _ListHalf({
    required this.value,
    required this.onRetry,
    required this.stalls,
    required this.selectedId,
    required this.highHygieneOnly,
    required this.compact,
    required this.sort,
    required this.keyFor,
    required this.onSelect,
    required this.onToggleHighHygiene,
    required this.onToggleCompact,
    required this.onSort,
  });

  final AsyncValue<List<DiscoveryStall>> value;
  final VoidCallback onRetry;
  final List<DiscoveryStall> stalls;
  final int? selectedId;
  final bool highHygieneOnly;
  final bool compact;
  final _Sort sort;
  final GlobalKey Function(int id) keyFor;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggleHighHygiene;
  final VoidCallback onToggleCompact;
  final ValueChanged<_Sort> onSort;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.xs, AppSpacing.xs, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.hasValue
                        ? (highHygieneOnly ? context.l10n.splitHighHygieneCount(stalls.length) : context.l10n.splitStallsCount(stalls.length))
                        : context.l10n.splitStallsTitle,
                    style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: compact ? context.l10n.splitDetailedCards : context.l10n.splitCompactCards,
                  icon: Icon(compact ? Icons.view_agenda_outlined : Icons.view_list_rounded, color: AppColors.textSecondary),
                  onPressed: onToggleCompact,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.sm),
            child: Row(
              children: [
                _FilterPill(
                  label: context.l10n.hygieneHigh,
                  selected: highHygieneOnly,
                  icon: Icons.verified_user,
                  onTap: onToggleHighHygiene,
                ),
                const Spacer(),
                PopupMenuButton<_Sort>(
                  tooltip: context.l10n.splitSort,
                  initialValue: sort,
                  onSelected: onSort,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.softButton)),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: _Sort.distance, child: Text(context.l10n.splitSortDistance)),
                    PopupMenuItem(value: _Sort.rating, child: Text(context.l10n.splitSortRating)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sort == _Sort.distance ? context.l10n.splitSortDistance : context.l10n.splitSortRating,
                          style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: !value.hasValue
                ? SingleChildScrollView(child: AsyncView<List<DiscoveryStall>>(value: value, onRetry: onRetry, builder: (_) => const SizedBox.shrink()))
                : stalls.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        context.l10n.splitNoMatch,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  )
                // Not lazy on purpose: every card must exist so a pin can scroll to it.
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.xxl),
                    child: Column(
                      children: [
                        for (var i = 0; i < stalls.length; i++)
                          Padding(
                            key: keyFor(stalls[i].id),
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: StallListCard(
                              stall: stalls[i],
                              number: i + 1,
                              selected: stalls[i].id == selectedId,
                              footer: compact ? StallCardFooter.tags : StallCardFooter.actions,
                              onTap: () => onSelect(stalls[i].id),
                            ),
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.icon, required this.onTap});

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
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
                Icon(icon, size: 14, color: selected ? AppColors.secondary : AppColors.textMuted),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTextStyles.bodyStrong.copyWith(
                    fontSize: 12,
                    color: selected ? AppColors.successText : AppColors.textSecondary,
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
