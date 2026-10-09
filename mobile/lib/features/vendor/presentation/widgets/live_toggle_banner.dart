import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/json.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/vendor_providers.dart';

/// Switches the stall open or closed (`PATCH /vendors/{id}/status`). It reads and
/// writes [vendorStallProvider], the same state as the Homepage's open/closed
/// pill, so the two always agree. If the server refuses (for instance a closed
/// stall with no hours set), its message is shown.
class LiveToggleBanner extends ConsumerStatefulWidget {
  const LiveToggleBanner({super.key});

  @override
  ConsumerState<LiveToggleBanner> createState() => _LiveToggleBannerState();
}

class _LiveToggleBannerState extends ConsumerState<LiveToggleBanner> {
  bool _busy = false;

  Future<void> _toggle(bool isOpen) async {
    if (_busy) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    try {
      await ref.read(vendorStallProvider.notifier).setOpen(!isOpen);
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
    final stall = ref.watch(vendorStallProvider).asData?.value;

    // Until the stall has loaded there is nothing honest to show.
    if (stall == null) return const SizedBox.shrink();

    final isOpen = stall.isOpenNow;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.successBg : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: isOpen ? AppColors.successBorder : AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? context.l10n.vtOpenTitle : context.l10n.vtClosedTitle,
                  style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  isOpen ? context.l10n.vtOpenBody : context.l10n.vtClosedBody,
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton(
            onPressed: _busy ? null : () => _toggle(isOpen),
            style: FilledButton.styleFrom(
              backgroundColor: isOpen ? AppColors.surface : AppColors.secondary,
              foregroundColor: isOpen ? AppColors.textPrimary : AppColors.surface,
              side: isOpen ? BorderSide(color: AppColors.border.withValues(alpha: 0.9)) : null,
              shape: const StadiumBorder(),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    isOpen ? context.l10n.vtCloseToday : context.l10n.vtReopen,
                    style: AppTextStyles.button.copyWith(fontSize: 13, color: isOpen ? AppColors.textPrimary : AppColors.surface),
                  ),
          ),
        ],
      ),
    );
  }
}
