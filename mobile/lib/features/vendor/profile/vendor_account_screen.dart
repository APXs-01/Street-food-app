import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/widgets/coming_soon.dart';
import '../../auth/presentation/widgets/pill_badge.dart';
import '../../auth/presentation/widgets/surface_card.dart';
import '../../../core/api/json.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../consumer/data/discovery_stall.dart';
import '../../consumer/presentation/widgets/stall_thumbnail.dart';
import '../../consumer/vendor_profile/widgets/frosted.dart';
import '../presentation/widgets/no_stall_action.dart';
import '../presentation/widgets/vendor_bottom_nav.dart';
import '../providers/vendor_providers.dart';

/// The vendor's Profile tab: stall identity, the open/closed switch (the same
/// state as the Dashboard banner and the Homepage pill) and the configuration menu.
class VendorAccountScreen extends ConsumerStatefulWidget {
  const VendorAccountScreen({super.key});

  @override
  ConsumerState<VendorAccountScreen> createState() => _VendorAccountScreenState();
}

class _VendorAccountScreenState extends ConsumerState<VendorAccountScreen> {
  bool _busy = false;

  Future<void> _setOpen(bool open) async {
    if (_busy) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    try {
      await ref.read(vendorStallProvider.notifier).setOpen(open);
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
    final stallAsync = ref.watch(vendorStallProvider);
    final stall = stallAsync.asData?.value;

    if (stall == null) {
      return VendorScaffold(
        tab: VendorTab.profile,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: AsyncView<DiscoveryStall>(
                value: stallAsync,
                onRetry: () => ref.invalidate(vendorStallProvider),
                errorAction: noStallAction,
                builder: (_) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
    }

    final isOpen = stall.isOpenNow;
    final closes = stall.opensUntil;

    return VendorScaffold(
      tab: VendorTab.profile,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, VendorScaffold.navClearance),
          children: [
            _IdentityCard(stall: stall),
            const SizedBox(height: AppSpacing.lg),
            SurfaceCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: isOpen ? AppColors.secondary : AppColors.textMuted, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isOpen ? context.l10n.vacctStatusOpen : context.l10n.vacctStatusClosed,
                          style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Transform.scale(
                        scale: 1.25,
                        child: Switch(
                          value: isOpen,
                          activeTrackColor: AppColors.secondary,
                          activeThumbColor: AppColors.surface,
                          onChanged: _busy ? null : _setOpen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isOpen
                          ? (closes == null ? context.l10n.vacctOpenServing : context.l10n.vacctOpenUntil(closes))
                          : context.l10n.vacctClosedNote,
                      style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider()),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.l10n.vacctAutoCloses,
                          style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                      InkWell(
                        onTap: () => context.go(Routes.vendorDashboardAt('hours')),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(context.l10n.vacctChangeHours, style: AppTextStyles.link.copyWith(fontSize: 12, color: AppColors.secondary)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(context.l10n.vacctConfig, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Not built: `PATCH /vendors/{id}` exists, but the app has no edit screen for it yet.
                  _MenuRow(
                    icon: Icons.storefront_outlined,
                    iconBackground: AppColors.successBg,
                    iconColor: AppColors.secondary,
                    title: context.l10n.vacctEditStall,
                    subtitle: context.l10n.vacctEditStallSub,
                    soon: true,
                    onTap: () => showComingSoon(context, context.l10n.vacctFeatureEditStall),
                  ),
                  const Divider(height: 1),
                  _MenuRow(
                    icon: Icons.workspace_premium_outlined,
                    iconBackground: AppColors.orangeAccentBg,
                    iconColor: AppColors.orangeAccentText,
                    title: context.l10n.vacctCertificate,
                    subtitle: context.l10n.vacctCertificateSub,
                    onTap: () => context.push(Routes.vendorStall(stall.id, tab: 'hygiene')),
                  ),
                  const Divider(height: 1),
                  _MenuRow(
                    icon: Icons.settings_outlined,
                    iconBackground: AppColors.borderLight,
                    iconColor: AppColors.textSecondary,
                    title: context.l10n.settingsTitle,
                    subtitle: context.l10n.settingsRowSub,
                    onTap: () => context.push(Routes.appSettings),
                  ),
                  const Divider(height: 1),
                  // Not built: the backend holds no hotline number or contact for inspectors.
                  _MenuRow(
                    icon: Icons.support_agent_outlined,
                    iconBackground: AppColors.successBg,
                    iconColor: AppColors.secondary,
                    title: context.l10n.vacctHelp,
                    subtitle: context.l10n.vacctHelpSub,
                    soon: true,
                    onTap: () => showComingSoon(context, context.l10n.vacctFeatureHotline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(context.l10n.vacctLogOut, style: AppTextStyles.button.copyWith(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.error.withValues(alpha: 0.06),
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                shape: const StadiumBorder(),
                minimumSize: const Size(0, 52),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              [if (stall.stallCode != null) context.l10n.vacctStallId(stall.stallCode!), context.l10n.vacctAppVersion(kAppVersion)].join(' • '),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// The cover photo with the avatar overlapping its bottom edge, then the name,
/// location and hygiene pill.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.stall});

  final DiscoveryStall stall;

  static const _coverHeight = 140.0;
  static const _avatar = 84.0;

  @override
  Widget build(BuildContext context) {
    final caution = stall.isCaution;
    final unrated = stall.hygiene == HygieneLevel.unrated;
    final location = [stall.locationLabel, stall.stallNumberLabel].where((part) => part.isNotEmpty).join(' • ');

    final String hygiene = switch (stall.hygiene) {
      HygieneLevel.verified || HygieneLevel.high => context.l10n.vacctVerifiedCleanVendor,
      HygieneLevel.pending => context.l10n.hygieneReverificationPending,
      HygieneLevel.unrated => context.l10n.hygieneNotInspected,
    };

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StallThumbnail(url: stall.photoUrl, width: double.infinity, height: _coverHeight, radius: 0, iconSize: 40),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, _avatar / 2 + AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stall.name, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.15, letterSpacing: -0.4)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PillBadge(
                      label: stall.hasRating ? '${stall.ratingLabel} ★ $hygiene' : hygiene,
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
              ),
            ],
          ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: GestureDetector(
              onTap: () => showComingSoon(context, context.l10n.vacctFeatureCover),
              child: Frosted(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_camera_outlined, size: 14, color: AppColors.textPrimary),
                    const SizedBox(width: 6),
                    Text(context.l10n.vacctCover, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: _coverHeight - _avatar / 2,
            left: AppSpacing.lg,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _avatar,
                  height: _avatar,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 4),
                    boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 3))],
                  ),
                  child: const Icon(Icons.storefront, color: AppColors.surface, size: 36),
                ),
                Positioned(
                  right: -2,
                  bottom: 0,
                  child: Tooltip(
                    message: context.l10n.vacctEditPhoto,
                    child: Material(
                      color: AppColors.surface,
                      shape: CircleBorder(side: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => showComingSoon(context, context.l10n.vacctFeatureStallPhoto),
                        child: const SizedBox(width: 28, height: 28, child: Icon(Icons.edit, size: 14, color: AppColors.textPrimary)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.soon = false,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// A feature that is not built yet: shows a "Soon" tag beside the title.
  final bool soon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(AppRadii.softButton)),
              child: Icon(icon, size: 21, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(title, style: AppTextStyles.bodyStrong)),
                      if (soon) ...[
                        const SizedBox(width: 6),
                        PillBadge(label: context.l10n.commonSoon, background: AppColors.borderLight, foreground: AppColors.textSecondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
