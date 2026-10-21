import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../vendor/onboarding/data/stall_category.dart';
import '../../vendor/onboarding/providers/onboarding_providers.dart';
import '../providers/discovery_providers.dart';

/// Opens the radius and hygiene filter as a modal bottom sheet. Changes are
/// kept as a draft and only applied by "Show N Results"; closing discards them.
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => const FilterSheet(),
  );
}

String _kmLabel(double km) =>
    l10n.commonDistanceKm(km == km.roundToDouble() ? '${km.round()}' : km.toStringAsFixed(1));

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late DiscoveryFilter _draft = ref.read(discoveryFilterProvider);

  void _show() {
    ref.read(discoveryFilterProvider.notifier).apply(_draft);
    Navigator.of(context).pop();
  }

  void _clearAll() {
    ref.read(discoveryFilterProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Null while the stalls are still loading or could not be loaded.
    final count = ref.watch(allStallsProvider).whenOrNull(data: (stalls) => applyDiscoveryFilter(stalls, _draft).length);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0),
            child: Row(
              children: [
                Expanded(child: Text(context.l10n.filtersTitle, style: AppTextStyles.title.copyWith(fontSize: 20, fontWeight: FontWeight.w800))),
                TextButton(
                  onPressed: () => setState(() => _draft = const DiscoveryFilter()),
                  child: Text(context.l10n.filtersReset, style: AppTextStyles.link.copyWith(color: AppColors.secondary)),
                ),
                IconButton(
                  tooltip: context.l10n.commonClose,
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _radiusSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _hygieneSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _categorySection(),
                  const SizedBox(height: AppSpacing.xl),
                  _openNowRow(),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearAll,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: const StadiumBorder(),
                          side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
                          foregroundColor: AppColors.textPrimary,
                        ),
                        child: Text(context.l10n.filtersClearAll, style: AppTextStyles.bodyStrong),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: count == 0 ? null : _show,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: const StadiumBorder(),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          disabledBackgroundColor: AppColors.borderLight,
                        ),
                        child: Text(
                          switch (count) {
                            null => context.l10n.filtersApply,
                            0 => context.l10n.filtersNoMatch,
                            _ => context.l10n.filtersShowResults(count),
                          },
                          style: AppTextStyles.button.copyWith(color: count == 0 ? AppColors.textMuted : AppColors.surface),
                        ),
                      ),
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

  Widget _radiusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(context.l10n.filtersSearchRadius, style: AppTextStyles.label.copyWith(fontSize: 14))),
            Text(_kmLabel(_draft.radiusKm), style: AppTextStyles.title.copyWith(color: AppColors.secondary)),
          ],
        ),
        Slider(
          value: _draft.radiusKm,
          min: DiscoveryFilter.minRadiusKm,
          max: DiscoveryFilter.maxRadiusKm,
          divisions: 9,
          activeColor: AppColors.secondary,
          inactiveColor: AppColors.borderLight,
          label: _kmLabel(_draft.radiusKm),
          onChanged: (value) => setState(() => _draft = _draft.copyWith(radiusKm: value)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.commonDistanceKm('0.5'), style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0)),
              Text(l10n.commonDistanceKm('5'), style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hygieneSection() {
    Widget choice(String label, HygieneFilter value, {Color? color, IconData? icon}) {
      return _ChoiceChip(
        label: label,
        selected: _draft.hygiene == value,
        selectedColor: color ?? AppColors.textPrimary,
        icon: icon,
        onTap: () => setState(() => _draft = _draft.copyWith(hygiene: value)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.filtersHygieneRating, style: AppTextStyles.label.copyWith(fontSize: 14)),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            choice(context.l10n.filtersAll, HygieneFilter.all),
            choice(context.l10n.filtersHighOnly, HygieneFilter.highOnly, color: AppColors.secondary),
            choice(context.l10n.hygieneVerifiedClean, HygieneFilter.verifiedClean, color: AppColors.secondary, icon: Icons.verified_user),
          ],
        ),
      ],
    );
  }

  Widget _categorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.filtersFoodCategory, style: AppTextStyles.label.copyWith(fontSize: 14)),
        const SizedBox(height: AppSpacing.md),
        AsyncView<List<StallCategory>>(
          value: ref.watch(categoriesProvider),
          compact: true,
          onRetry: () => ref.invalidate(categoriesProvider),
          builder: (categories) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final category in categories)
                _ChoiceChip(
                  label: category.label,
                  emoji: category.emoji,
                  selected: _draft.categories.contains(category.slug),
                  selectedColor: AppColors.secondary,
                  onTap: () => setState(() => _draft = _draft.toggleCategory(category.slug)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _openNowRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.filtersOpenNow, style: AppTextStyles.label.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                context.l10n.filtersOpenNowSub,
                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Switch(
          value: _draft.openNow,
          activeTrackColor: AppColors.secondary,
          activeThumbColor: AppColors.surface,
          onChanged: (value) => setState(() => _draft = _draft.copyWith(openNow: value)),
        ),
      ],
    );
  }
}

/// A pill the person can select: filled with [selectedColor] and white text
/// when chosen, white with a border when not.
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
    this.emoji,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;
  final String? emoji;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.surface : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? selectedColor : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? selectedColor : AppColors.border.withValues(alpha: 0.8))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 15)), const SizedBox(width: 6)],
                if (icon != null) ...[Icon(icon, size: 15, color: foreground), const SizedBox(width: 6)],
                Text(label, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
