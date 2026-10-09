import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'widgets/auth_scroll_body.dart';
import 'widgets/pill_badge.dart';
import 'widgets/surface_card.dart';

/// App entry point: pick customer or vendor, then go to that role's login.
///
/// The progress bar is decorative. Nothing is being synced yet, and the role
/// cards are usable straight away rather than after an artificial delay.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          AuthScrollBody(
            topPadding: AppSpacing.xl,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PillBadge(
                  label: context.l10n.authRoleLiveProtocol,
                  background: AppColors.surface,
                  foreground: AppColors.successText,
                  borderColor: AppColors.successBorder,
                  leading: const _GreenDot(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Flexible(child: Text(kBrandName, style: AppTextStyles.display)),
                  const SizedBox(width: AppSpacing.md),
                  PillBadge(
                    label: context.l10n.authRoleVerified,
                    leading: const Icon(Icons.verified, size: 13, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.authRoleTagline,
                style: AppTextStyles.body.copyWith(fontSize: 16, height: 1.45),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SyncProgress(),
              const SizedBox(height: AppSpacing.xl),
              const _HygieneTipCard(),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(context.l10n.authRoleChoose, style: AppTextStyles.title.copyWith(fontSize: 16)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.l10n.commonStepOf(1, 2),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleCard(
                icon: Icons.restaurant,
                avatarColor: AppColors.primary,
                title: context.l10n.authRoleCustomerTitle,
                badge: PillBadge(label: context.l10n.authRolePopular, background: AppColors.primaryLight, foreground: AppColors.primary),
                subtitle: context.l10n.authRoleCustomerSubtitle,
                tags: [context.l10n.authRoleTagGps, context.l10n.authRoleTagCleanScore],
                emphasized: true,
                onTap: () => context.push(Routes.consumerLogin),
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleCard(
                icon: Icons.storefront,
                avatarColor: AppColors.darkAvatar,
                title: context.l10n.authRoleVendorTitle,
                badge: PillBadge(label: context.l10n.authRoleCommission, background: AppColors.borderLight, foreground: AppColors.textSecondary),
                subtitle: context.l10n.authRoleVendorSubtitle,
                tags: [context.l10n.authRoleTagOnboarding, context.l10n.authRoleTagCertified],
                emphasized: false,
                onTap: () => context.push(Routes.vendorLogin),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                context.l10n.authRoleDisclaimer,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreenDot extends StatelessWidget {
  const _GreenDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(color: AppColors.vendorAccent, shape: BoxShape.circle),
    );
  }
}

/// Soft mint, peach and green glows behind the content.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(top: -90, right: -70, child: _Blob(color: AppColors.primaryLight, size: 280, opacity: 0.4)),
          Positioned(top: 300, left: -120, child: _Blob(color: AppColors.orangeAccentBg, size: 260, opacity: 0.5)),
          Positioned(bottom: -100, right: -60, child: _Blob(color: AppColors.vendorAccent, size: 280, opacity: 0.14)),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _SyncProgress extends StatelessWidget {
  const _SyncProgress();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1800),
          curve: Curves.easeInOut,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: AppColors.borderLight,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.authRoleSyncing,
          style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// The "Daily Vendor Standard" card: a gradient stripe along the top, a shield and
/// a hygiene tip that changes every few seconds.
class _HygieneTipCard extends StatefulWidget {
  const _HygieneTipCard();

  @override
  State<_HygieneTipCard> createState() => _HygieneTipCardState();
}

class _HygieneTipCardState extends State<_HygieneTipCard> {
  static const _tipCount = 4;

  Timer? _timer;
  int _index = 0;

  List<String> get _tips => [
        context.l10n.authTip1,
        context.l10n.authTip2,
        context.l10n.authTip3,
        context.l10n.authTip4,
      ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _tipCount);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.secondary, AppColors.primaryLight, AppColors.amber]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.authTipHeading, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Text(
                          _tips[_index],
                          key: ValueKey(_index),
                          style: AppTextStyles.body.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.avatarColor,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.tags,
    required this.emphasized,
    required this.onTap,
  });

  final IconData icon;
  final Color avatarColor;
  final String title;
  final Widget badge;
  final String subtitle;
  final List<String> tags;

  /// The customer card has a 2px primary-tinted border; the vendor card a plain 1px one.
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
            border: Border.all(
              color: emphasized ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border.withValues(alpha: 0.5),
              width: emphasized ? 2 : 1,
            ),
            boxShadow: const [AppShadows.card],
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: avatarColor, borderRadius: BorderRadius.circular(AppRadii.card)),
                    child: Icon(icon, color: AppColors.surface, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [Text(title, style: AppTextStyles.title), badge],
                        ),
                        const SizedBox(height: 6),
                        Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 13)),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: 6,
                          children: [for (final tag in tags) _MicroTag(tag)],
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MicroTag extends StatelessWidget {
  const _MicroTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 13, color: AppColors.vendorAccent),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0.2)),
      ],
    );
  }
}
