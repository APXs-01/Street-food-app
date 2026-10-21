import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../data/discovery_stall.dart';
import '../providers/discovery_providers.dart';
import 'filter_sheet.dart';
import 'widgets/stall_list_card.dart';

/// Search: a focused input at the top; recent searches while it is empty, live
/// results while typing, and an empty state when nothing matches. Results respect
/// the filters from the filter sheet.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  /// The text the server is asked about: the input, a moment after typing stops.
  String _searched = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _query => _controller.text.trim();

  void _typed() {
    _debounce?.cancel();

    if (_query.isEmpty) {
      setState(() => _searched = '');
      return;
    }

    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _searched = _query);
    });
  }

  void _setQuery(String text) {
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    _debounce?.cancel();
    setState(() => _searched = text.trim());
  }

  void _submit(String text) {
    ref.read(recentSearchesProvider.notifier).add(text);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final results = _searched.isEmpty ? null : ref.watch(searchResultsProvider(_searched));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focus: _focus,
              onChanged: (_) => _typed(),
              onSubmitted: _submit,
              onClear: () => _setQuery(''),
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.consumerHome),
            ),
            Expanded(
              child: results == null
                  ? _RecentSearches(onPick: (text) {
                      _setQuery(text);
                      _submit(text);
                    })
                  : AsyncView<List<DiscoveryStall>>(
                      value: results,
                      onRetry: () => ref.invalidate(searchResultsProvider(_searched)),
                      builder: (stalls) => stalls.isEmpty
                          ? _NoResults(query: _searched, onAdjustFilters: () => showFilterSheet(context))
                          : _Results(stalls: stalls, query: _searched),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focus,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.commonBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: onBack,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.secondary, width: 1.5),
              ),
              child: TextField(
                controller: controller,
                focusNode: focus,
                autofocus: true,
                cursorColor: AppColors.secondary,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: context.l10n.searchHint,
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
                            onPressed: onClear,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentSearchesProvider);

    if (recents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            context.l10n.searchEmptyHint,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Row(
          children: [
            Expanded(child: Text(context.l10n.searchRecent, style: AppTextStyles.title.copyWith(fontSize: 16))),
            TextButton(
              onPressed: () => ref.read(recentSearchesProvider.notifier).clear(),
              child: Text(context.l10n.commonClear, style: AppTextStyles.link.copyWith(color: AppColors.secondary)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final text in recents)
              ActionChip(
                avatar: const Icon(Icons.history, size: 16, color: AppColors.textMuted),
                label: Text(text, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13)),
                backgroundColor: AppColors.surface,
                side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                shape: const StadiumBorder(),
                onPressed: () => onPick(text),
              ),
          ],
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.stalls, required this.query});

  final List<DiscoveryStall> stalls;
  final String query;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxl),
      itemCount: stalls.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            context.l10n.searchResultsCount(stalls.length, query),
            style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textMuted),
          );
        }

        return StallListCard(stall: stalls[index - 1], footer: StallCardFooter.tags);
      },
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query, required this.onAdjustFilters});

  final String query;
  final VoidCallback onAdjustFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.surfaceMuted, shape: BoxShape.circle),
              child: const Icon(Icons.search_off, size: 34, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.l10n.searchNoResultsTitle(query), textAlign: TextAlign.center, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.searchNoResultsBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onAdjustFilters,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(context.l10n.searchAdjustFilters),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
