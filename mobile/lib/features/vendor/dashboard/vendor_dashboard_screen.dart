import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/json.dart';
import '../../../core/brand.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/presentation/widgets/coming_soon.dart';
import '../../auth/presentation/widgets/pill_badge.dart';
import '../../auth/presentation/widgets/surface_card.dart';
import '../../consumer/data/discovery_stall.dart';
import '../../consumer/presentation/widgets/stall_thumbnail.dart';
import '../../notifications/providers/alerts_providers.dart';
import '../data/vendor_models.dart';
import '../onboarding/data/onboarding_draft.dart';
import '../presentation/widgets/live_toggle_banner.dart';
import '../presentation/widgets/no_stall_action.dart';
import '../presentation/widgets/vendor_bottom_nav.dart';
import '../providers/vendor_providers.dart';

/// How far one tap on an hours stepper moves the time.
const int _stepMinutes = 30;

/// The vendor's control panel: live open/closed, operating hours, the daily menu
/// and a link to the stall profile. [initialSection] (`hours` or `menu`) scrolls
/// there on arrival, for the Homepage's "Update Hours" and "Update Menu".
///
/// Real calls: `PATCH /vendors/{id}/status`, `PATCH /vendors/{id}/hours` and the
/// `/menu-items` endpoints. Every write waits for the server and shows its
/// message if it refuses.
class VendorDashboardScreen extends ConsumerStatefulWidget {
  const VendorDashboardScreen({super.key, this.initialSection});

  final String? initialSection;

  @override
  ConsumerState<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends ConsumerState<VendorDashboardScreen> {
  final _hoursKey = GlobalKey();
  final _menuKey = GlobalKey();

  /// The hours being edited; null until the stall has loaded, then a copy of its hours.
  TimeOfDay? _opens;
  TimeOfDay? _closes;
  bool _savingHours = false;

  @override
  void initState() {
    super.initState();

    final target = switch (widget.initialSection) {
      'hours' => _hoursKey,
      'menu' => _menuKey,
      _ => null,
    };

    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = target.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 350), curve: Curves.easeOut, alignment: 0.02);
        }
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs a write and shows the server's message if it fails.
  Future<void> _attempt(Future<void> Function() write) async {
    try {
      await write();
    } catch (error) {
      if (mounted) _toast(errorMessage(error));
    }
  }

  Future<void> _saveHours(DiscoveryStall stall) async {
    final opens = _opens;
    final closes = _closes;
    if (opens == null || closes == null || _savingHours) return;

    setState(() => _savingHours = true);

    await _attempt(() => ref.read(vendorStallProvider.notifier).setHours(opens: opens, closes: closes));

    if (!mounted) return;

    setState(() => _savingHours = false);
    _toast(context.l10n.vdHoursSaved);
  }

  Future<void> _editItem({StallMenuItem? existing}) async {
    final result = await showDialog<_MenuItemEdit>(
      context: context,
      builder: (context) => _MenuItemDialog(existing: existing),
    );

    if (result == null || !mounted) return;

    final notifier = ref.read(vendorMenuProvider.notifier);

    await _attempt(
      () => existing == null
          ? notifier.add(result.name, result.price, soldOut: result.soldOut)
          : notifier.edit(existing.id, name: result.name, price: result.price, soldOut: result.soldOut),
    );
  }

  Future<void> _confirmDelete(StallMenuItem item) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.vdDeleteItemTitle(item.name), style: AppTextStyles.title),
        content: Text(context.l10n.vdDeleteItemBody, style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.vdKeep)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.commonDelete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (delete == true && mounted) await _attempt(() => ref.read(vendorMenuProvider.notifier).remove(item.id));
  }

  @override
  Widget build(BuildContext context) {
    final stallAsync = ref.watch(vendorStallProvider);
    final stall = stallAsync.asData?.value;
    final menu = ref.watch(vendorMenuProvider);

    // Seed the hours editor once, from what the server has.
    if (stall != null && _opens == null) {
      _opens = parseApiTime(stall.opensAt) ?? const TimeOfDay(hour: 9, minute: 0);
      _closes = parseApiTime(stall.closesAt) ?? const TimeOfDay(hour: 17, minute: 0);
    }

    return VendorScaffold(
      tab: VendorTab.dashboard,
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: stall == null
                ? SingleChildScrollView(
                    child: AsyncView<DiscoveryStall>(
                      value: stallAsync,
                      onRetry: () => ref.invalidate(vendorStallProvider),
                      errorAction: noStallAction,
                      builder: (_) => const SizedBox.shrink(),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, VendorScaffold.navClearance),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TitleCard(stall: stall),
                        const SizedBox(height: AppSpacing.lg),
                        const LiveToggleBanner(),
                        const SizedBox(height: AppSpacing.xl),
                        KeyedSubtree(key: _hoursKey, child: _hoursSection(stall)),
                        const SizedBox(height: AppSpacing.xl),
                        KeyedSubtree(key: _menuKey, child: _menuSection(menu)),
                        const SizedBox(height: AppSpacing.md),
                        _ProfileLinkCard(locationLabel: stall.locationLabel),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _hoursSection(DiscoveryStall stall) {
    final opens = _opens!;
    final closes = _closes!;
    final saved = parseApiTime(stall.opensAt) == opens && parseApiTime(stall.closesAt) == closes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.vpOperatingHours, style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _TimeStepper(
                label: context.l10n.vdOpenTime,
                time: opens,
                onMinus: () => setState(() => _opens = shiftTime(opens, -_stepMinutes)),
                onPlus: () => setState(() => _opens = shiftTime(opens, _stepMinutes)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _TimeStepper(
                label: context.l10n.vdCloseTime,
                time: closes,
                onMinus: () => setState(() => _closes = shiftTime(closes, -_stepMinutes)),
                onPlus: () => setState(() => _closes = shiftTime(closes, _stepMinutes)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _PresetPill(
                label: context.l10n.vdExtendHour,
                icon: Icons.more_time,
                foreground: AppColors.successText,
                background: AppColors.successBg,
                border: AppColors.successBorder,
                onTap: () => setState(() => _closes = shiftTime(closes, 60)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _PresetPill(
                label: context.l10n.vdCloseEarly,
                icon: Icons.bedtime_outlined,
                foreground: AppColors.orangeAccentText,
                background: AppColors.amberBg,
                border: AppColors.amber.withValues(alpha: 0.5),
                onTap: () async {
                  await _attempt(() => ref.read(vendorStallProvider.notifier).setOpen(false));

                  if (mounted) _toast(context.l10n.vdClosedToast);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: saved || _savingHours ? null : () => _saveHours(stall),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.surface,
            disabledBackgroundColor: AppColors.borderLight,
            shape: const StadiumBorder(),
            minimumSize: const Size(0, 48),
          ),
          child: _savingHours
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface))
              : Text(saved ? context.l10n.vdHoursSavedBtn : context.l10n.vdSaveHours, style: AppTextStyles.button.copyWith(color: saved ? AppColors.textMuted : AppColors.surface)),
        ),
      ],
    );
  }

  Widget _menuSection(AsyncValue<List<StallMenuItem>> menuAsync) {
    final items = menuAsync.asData?.value ?? const <StallMenuItem>[];
    final notifier = ref.read(vendorMenuProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                menuAsync.hasValue ? context.l10n.vdDailyMenuCount(items.length) : context.l10n.vdDailyMenu,
                style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              onPressed: menuAsync.hasValue ? () => _editItem() : null,
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.l10n.vdAddItem, style: AppTextStyles.button.copyWith(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.surface,
                shape: const StadiumBorder(),
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncView<List<StallMenuItem>>(
          value: menuAsync,
          compact: true,
          onRetry: () => ref.invalidate(vendorMenuProvider),
          builder: (list) {
            if (list.isEmpty) return EmptyNote(context.l10n.vdMenuEmpty);

            return Column(
              children: [
                for (final item in list) ...[
                  _MenuRow(
                    item: item,
                    onToggleFresh: () => _attempt(() => notifier.toggleFresh(item.id)),
                    onEdit: () => _editItem(existing: item),
                    onDelete: () => _confirmDelete(item),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.stall});

  final DiscoveryStall stall;

  @override
  Widget build(BuildContext context) {
    final unrated = stall.hygiene == HygieneLevel.unrated;
    final caution = stall.isCaution;

    final String label = switch (stall.hygiene) {
      HygieneLevel.verified || HygieneLevel.high => context.l10n.vdCleanVerified,
      HygieneLevel.pending => context.l10n.hygieneReverificationPending,
      HygieneLevel.unrated => context.l10n.hygieneNotInspected,
    };

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.vdMerchantControl, style: AppTextStyles.caption.copyWith(color: AppColors.secondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(context.l10n.vdTitle, style: AppTextStyles.display.copyWith(fontSize: 26, height: 1.15))),
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
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadAlertsProvider);

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.screenPadding, right: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text(kBrandName, style: AppTextStyles.wordmark)),
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
        ),
      ),
    );
  }
}

/// "Open Time" / "Close Time": the time in large type with round − and + buttons.
class _TimeStepper extends StatelessWidget {
  const _TimeStepper({required this.label, required this.time, required this.onMinus, required this.onPlus});

  final String label;
  final TimeOfDay time;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatTime12(time), style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.1, letterSpacing: -0.4)),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundStep(icon: Icons.remove, tooltip: context.l10n.vdEarlier(_stepMinutes), onTap: onMinus),
              _RoundStep(icon: Icons.add, tooltip: context.l10n.vdLater(_stepMinutes), onTap: onPlus),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundStep extends StatelessWidget {
  const _RoundStep({required this.icon, required this.tooltip, required this.onTap});

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
          child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: StadiumBorder(side: BorderSide(color: border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: AppTextStyles.bodyStrong.copyWith(fontSize: 12, color: foreground))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onToggleFresh, required this.onEdit, required this.onDelete});

  final StallMenuItem item;
  final VoidCallback onToggleFresh;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final soldOut = !item.isAvailable;
    final thumbnail = StallThumbnail(url: item.photoUrl ?? '', width: 52, height: 52, radius: 10, iconSize: 22);

    return Opacity(
      opacity: soldOut ? 0.85 : 1,
      child: SurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                // A sold-out dish is shown in greyscale.
                soldOut
                    ? ColorFiltered(colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation), child: thumbnail)
                    : thumbnail,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                      Row(
                        children: [
                          Text(item.priceLabel, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: AppColors.secondary)),
                          if (soldOut) ...[
                            const SizedBox(width: AppSpacing.sm),
                            PillBadge(label: context.l10n.vpSoldOut, background: AppColors.borderLight, foreground: AppColors.textSecondary),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.vdEditItemTooltip(item.name),
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: context.l10n.vdDeleteItemTooltip(item.name),
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  onPressed: onDelete,
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(context.l10n.vdPreparedness, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                ),
                _FreshPill(on: item.isFreshToday && !soldOut, enabled: !soldOut, onTap: onToggleFresh),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ON: mint with a check. OFF: grey outline. Disabled while the dish is sold out.
class _FreshPill extends StatelessWidget {
  const _FreshPill({required this.on, required this.enabled, required this.onTap});

  final bool on;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: on,
      enabled: enabled,
      label: context.l10n.vdPreparedness,
      child: Material(
        color: on ? AppColors.primaryLight.withValues(alpha: 0.6) : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: on ? AppColors.secondary : AppColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(on ? Icons.check_circle : Icons.radio_button_unchecked, size: 15, color: on ? AppColors.secondary : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  !enabled ? context.l10n.vdUnavailable : (on ? context.l10n.vdFreshOn : context.l10n.vdFreshOff),
                  style: AppTextStyles.caption.copyWith(letterSpacing: 0.2, color: on ? AppColors.successText : AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Editing the stall profile (name, categories, pin, cover photo) is not built
/// yet: the API's `PATCH /vendors/{id}` exists, but this app has no screen for it.
class _ProfileLinkCard extends StatelessWidget {
  const _ProfileLinkCard({required this.locationLabel});

  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => showComingSoon(context, context.l10n.vdFeatureEditProfile),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(AppRadii.softButton)),
                child: const Icon(Icons.storefront_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(context.l10n.vdProfileLink, style: AppTextStyles.bodyStrong),
                        PillBadge(label: context.l10n.commonSoon, background: AppColors.borderLight, foreground: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.vdProfileLinkBody,
                      style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                    ),
                    if (locationLabel.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      PillBadge(label: locationLabel, background: AppColors.surfaceMuted, foreground: AppColors.textSecondary),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemEdit {
  const _MenuItemEdit(this.name, this.price, this.soldOut);

  final String name;
  final double price;
  final bool soldOut;
}

/// Add a dish, or edit one: name, price and whether it is sold out.
class _MenuItemDialog extends StatefulWidget {
  const _MenuItemDialog({this.existing});

  final StallMenuItem? existing;

  @override
  State<_MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<_MenuItemDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _price = TextEditingController(text: widget.existing?.price.toStringAsFixed(2) ?? '');
  late bool _soldOut = !(widget.existing?.isAvailable ?? true);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());

    if (name.isEmpty) {
      setState(() => _error = context.l10n.vdErrName);
    } else if (price == null || price <= 0) {
      setState(() => _error = context.l10n.vdErrPrice);
    } else {
      Navigator.of(context).pop(_MenuItemEdit(name, price, _soldOut));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? context.l10n.vdAddItem : context.l10n.vdEditItemTitle, style: AppTextStyles.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: context.l10n.vdDishName),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: context.l10n.vdPrice, prefixText: '\$ '),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _soldOut,
              onChanged: (value) => setState(() => _soldOut = value ?? false),
              title: Text(context.l10n.vpSoldOut, style: AppTextStyles.body),
            ),
            if (_error != null)
              Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.error, letterSpacing: 0, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.commonCancel)),
        TextButton(onPressed: _save, child: Text(context.l10n.commonSave)),
      ],
    );
  }
}
