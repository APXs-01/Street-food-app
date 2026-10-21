import 'dart:ui' show ImageFilter;

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
import 'widgets/map_quick_info_card.dart';
import 'widgets/section_header.dart';
import 'widgets/simulated_map.dart';
import 'widgets/stall_peek_card.dart';

/// The main discovery screen: a full-bleed map with floating controls, pins for
/// every stall that passes the filters and the search text, and a draggable
/// bottom sheet listing them.
class FullMapScreen extends ConsumerStatefulWidget {
  const FullMapScreen({super.key});

  @override
  ConsumerState<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends ConsumerState<FullMapScreen> {
  static const _peekExtent = 0.30;
  static const _expandedExtent = 0.86;

  final _search = TextEditingController();

  /// The highlighted pin; none until one is tapped.
  int? _selectedId;
  double _sheetExtent = _peekExtent;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _retry() {
    ref.invalidate(searchCenterProvider);
    ref.invalidate(allStallsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final stalls = ref.watch(filteredStallsProvider).whenData(
          (list) => list.where((stall) => stall.matches(_search.text)).toList(),
        );
    final visible = stalls.asData?.value ?? const <DiscoveryStall>[];
    final center = ref.watch(searchCenterProvider).asData?.value ?? SearchCenter.fallback;
    final spots = layoutOnMap(visible, center);
    final filterActive = ref.watch(discoveryFilterProvider.select((filter) => filter.isActive));

    DiscoveryStall? selected;
    for (final stall in visible) {
      if (stall.id == _selectedId && spots.containsKey(stall.id)) selected = stall;
    }

    return Scaffold(
      backgroundColor: AppColors.mapLand,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: SimulatedMap(
                  placements: [
                    MapPlacement(x: kMapCentre.x, y: kMapCentre.y, centered: true, child: const UserLocationDot()),
                    // The selected pin goes last so it draws on top.
                    for (final stall in visible)
                      if (stall.id != selected?.id && spots[stall.id] != null)
                        MapPlacement(
                          x: spots[stall.id]!.x,
                          y: spots[stall.id]!.y,
                          child: RatingPin(stall: stall, onTap: () => setState(() => _selectedId = stall.id)),
                        ),
                    if (selected != null)
                      MapPlacement(
                        x: spots[selected.id]!.x,
                        y: spots[selected.id]!.y,
                        child: SelectedPin(stall: selected, onTap: () => context.push(Routes.consumerVendor(selected!.id))),
                      ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(child: _FrostedLocationPill(label: center.label)),
                          const SizedBox(width: AppSpacing.sm),
                          _LivePill(count: stalls.hasValue ? visible.where((stall) => stall.isOpenNow).length : null),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SearchField(
                        controller: _search,
                        filterActive: filterActive,
                        onChanged: (_) => setState(() {}),
                        onFilter: () => showFilterSheet(context),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.screenPadding,
                top: MediaQuery.paddingOf(context).top + 150,
                child: Column(
                  children: [
                    _RoundMapButton(
                      icon: Icons.layers_outlined,
                      tooltip: context.l10n.mapLayers,
                      onTap: () => showComingSoon(context, context.l10n.mapLayers),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RoundMapButton(
                      icon: Icons.my_location,
                      tooltip: context.l10n.mapUseMyLocation,
                      filled: true,
                      onTap: _retry,
                    ),
                  ],
                ),
              ),
              // Over the map while the sheet is at rest; hidden once it is pulled up.
              if (selected != null && _sheetExtent < 0.45)
                Positioned(
                  left: AppSpacing.screenPadding,
                  right: AppSpacing.screenPadding,
                  bottom: _sheetExtent * screenHeight + AppSpacing.md,
                  child: MapQuickInfoCard(stall: selected),
                ),
              NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  setState(() => _sheetExtent = notification.extent);
                  return false;
                },
                child: DraggableScrollableSheet(
                  initialChildSize: _peekExtent,
                  minChildSize: _peekExtent,
                  maxChildSize: _expandedExtent,
                  snap: true,
                  snapSizes: const [_peekExtent, _expandedExtent],
                  builder: (context, scrollController) => _StallsSheet(
                    controller: scrollController,
                    stalls: stalls,
                    selectedId: selected?.id,
                    onSelect: (stall) => setState(() => _selectedId = stall.id),
                    onRetry: _retry,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FrostedLocationPill extends StatelessWidget {
  const _FrostedLocationPill({required this.label});

  /// "Current location", or the default area's name when GPS is unavailable.
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.surface.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong.copyWith(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "18 Open Stalls Nearby" with a pulsing dot; "Finding stalls…" until they load.
class _LivePill extends StatefulWidget {
  const _LivePill({required this.count});

  final int? count;

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1).animate(_pulse),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            widget.count == null ? context.l10n.mapFinding : context.l10n.mapOpenStallsNearby(widget.count!),
            style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: AppColors.surface),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.filterActive,
    required this.onChanged,
    required this.onFilter,
  });

  final TextEditingController controller;
  final bool filterActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppColors.secondary,
              style: AppTextStyles.input,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.mapSearchHint,
                hintStyle: AppTextStyles.hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: context.l10n.commonClear,
                          icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                          onPressed: () {
                            controller.clear();
                            onChanged('');
                          },
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _RoundMapButton(icon: Icons.tune, tooltip: context.l10n.mapFilters, onTap: onFilter),
            if (filterActive)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({required this.icon, required this.tooltip, required this.onTap, this.filled = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// The emerald GPS button; the others are white.
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
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: filled ? AppColors.surface : AppColors.textPrimary, size: 22),
          ),
        ),
      ),
    );
  }
}

/// The draggable sheet: handle, "Nearby Stalls" header, then the stalls.
class _StallsSheet extends StatelessWidget {
  const _StallsSheet({
    required this.controller,
    required this.stalls,
    required this.selectedId,
    required this.onSelect,
    required this.onRetry,
  });

  final ScrollController controller;
  final AsyncValue<List<DiscoveryStall>> stalls;
  final int? selectedId;
  final ValueChanged<DiscoveryStall> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              context.l10n.mapNearbyStalls,
                              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (stalls.hasValue) ...[
                            const SizedBox(width: AppSpacing.sm),
                            CountBadge(stalls.requireValue.length),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.mapSortedByDistance,
                        style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                SectionLink(
                  label: context.l10n.mapListView,
                  icon: Icons.view_list_rounded,
                  onTap: () => context.push(Routes.consumerMapSplit),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AsyncView<List<DiscoveryStall>>(
            value: stalls,
            onRetry: onRetry,
            builder: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 32, color: AppColors.textMuted),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.mapNoMatch,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < list.length; i++)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.md),
                      child: StallPeekCard(
                        stall: list[i],
                        rank: i + 1,
                        selected: list[i].id == selectedId,
                        onTap: () => onSelect(list[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
