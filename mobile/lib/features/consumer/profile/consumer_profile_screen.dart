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
import '../../auth/providers/auth_providers.dart';
import '../../social/providers/social_providers.dart';
import '../../statuses/data/status_models.dart';
import '../../statuses/providers/status_providers.dart';
import '../../vendor/onboarding/presentation/widgets/dashed_border.dart';
import '../presentation/widgets/consumer_bottom_nav.dart';
import '../presentation/widgets/stall_thumbnail.dart';
import '../vendor_profile/widgets/avatar_circle.dart';

/// The customer's profile: who they are, their counts, their live statuses and
/// the settings and network menu. The name, handle, bio and photo come from the
/// signed-in account; the counts come from `GET /statuses?mine=1` and the
/// friends list. A count that is still loading shows a dash, not a zero.
class ConsumerProfileScreen extends ConsumerWidget {
  const ConsumerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((state) => state.session?.user));
    final statuses = ref.watch(myStatusesProvider);
    final friends = ref.watch(friendsProvider);
    final now = DateTime.now();
    final live = (statuses.asData?.value ?? const <StatusPost>[]).where((status) => status.isActive && status.remainingAt(now) > Duration.zero).toList();

    final name = user?.name ?? '';
    final handle = user?.username ?? user?.email?.split('@').first ?? user?.phone ?? '';
    final bio = (user?.bio ?? '').trim();

    return ConsumerScaffold(
      tab: ConsumerTab.profile,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, ConsumerScaffold.navClearance),
          children: [
            _HeroCard(
              name: name,
              handle: handle,
              bio: bio,
              avatarUrl: user?.avatarUrl,
              statuses: statuses.asData?.value.length,
              friends: friends.asData?.value.length,
              live: statuses.hasValue ? live.length : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(context.l10n.profLiveStatuses, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 190,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _CreateTile(onTap: () => context.push(Routes.consumerStatusCreate)),
                  for (final status in live) ...[
                    const SizedBox(width: AppSpacing.md),
                    _StatusCard(status: status, now: now),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(context.l10n.profSettingsNetwork, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuRow(
                    icon: Icons.group_outlined,
                    iconBackground: AppColors.successBg,
                    iconColor: AppColors.secondary,
                    title: context.l10n.profFriendsNetwork,
                    badge: friends.hasValue
                        ? PillBadge(
                            label: context.l10n.profConnected(friends.requireValue.length),
                            background: AppColors.primaryLight.withValues(alpha: 0.6),
                            foreground: AppColors.successText,
                          )
                        : null,
                    subtitle: context.l10n.profFriendsSub,
                    onTap: () => context.push(Routes.consumerFriends),
                  ),
                  const Divider(height: 1),
                  _MenuRow(
                    icon: Icons.inventory_2_outlined,
                    iconBackground: AppColors.orangeAccentBg,
                    iconColor: AppColors.orangeAccentText,
                    title: context.l10n.profHistory,
                    subtitle: context.l10n.profHistorySub,
                    onTap: () => context.push(Routes.consumerStatusHistory),
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
                  _MenuRow(
                    icon: Icons.health_and_safety_outlined,
                    iconBackground: AppColors.successBg,
                    iconColor: AppColors.secondary,
                    title: context.l10n.profHelp,
                    subtitle: context.l10n.profHelpSub,
                    badge: PillBadge(label: context.l10n.commonSoon, background: AppColors.borderLight, foreground: AppColors.textSecondary),
                    onTap: () => showComingSoon(context, context.l10n.profFeatureHelp),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(context.l10n.profLogOut, style: AppTextStyles.button.copyWith(color: AppColors.error)),
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
              '$kBrandName v$kAppVersion',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.handle,
    required this.bio,
    required this.avatarUrl,
    required this.statuses,
    required this.friends,
    required this.live,
  });

  final String name;
  final String handle;
  final String bio;
  final String? avatarUrl;

  /// Null while the count is loading.
  final int? statuses;
  final int? friends;
  final int? live;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryLight, width: 3)),
                child: AvatarCircle(name: name, photoUrl: avatarUrl, size: 84),
              ),
              Positioned(
                right: 0,
                bottom: 2,
                child: Tooltip(
                  // The API has no profile-photo upload yet.
                  message: context.l10n.profEditPhoto,
                  child: Material(
                    color: AppColors.primary,
                    shape: CircleBorder(side: BorderSide(color: AppColors.surface, width: 2.5)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => showComingSoon(context, context.l10n.profFeaturePhoto),
                      child: const SizedBox(width: 30, height: 30, child: Icon(Icons.edit, size: 15, color: AppColors.surface)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.headline.copyWith(fontSize: 24))),
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 20, color: AppColors.secondary),
            ],
          ),
          if (handle.isNotEmpty) Text('@$handle', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textMuted)),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(bio, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13)),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: Divider()),
          Row(
            children: [
              Expanded(child: _Stat(value: statuses, label: context.l10n.profStatStatuses)),
              Expanded(child: _Stat(value: friends, label: context.l10n.profStatFriends)),
              Expanded(child: _Stat(value: live, label: context.l10n.profStatLive)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  /// Null while loading: shown as a dash.
  final int? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 4),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.softButton)),
      child: Column(
        children: [
          Text(value == null ? '–' : '$value', style: AppTextStyles.display.copyWith(fontSize: 22, height: 1.1, color: AppColors.secondary)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _CreateTile extends StatelessWidget {
  const _CreateTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: DashedBorder(
        color: AppColors.secondary.withValues(alpha: 0.7),
        radius: AppRadii.card,
        child: Material(
          color: AppColors.successBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.card),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: AppColors.surface),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(context.l10n.profCreateStatus, textAlign: TextAlign.center, style: AppTextStyles.bodyStrong.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.now});

  final StatusPost status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: GestureDetector(
        onTap: () => context.push(Routes.consumerStatus(status.id)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              StallThumbnail(url: status.photoUrl, width: double.infinity, height: double.infinity, radius: 0, iconSize: 36),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xB3000000)],
                    stops: [0.4, 1],
                  ),
                ),
              ),
              if (status.vendorName != null)
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PillBadge(
                      label: status.vendorName!,
                      background: AppColors.primaryLight,
                      foreground: AppColors.primary,
                    ),
                  ),
                ),
              Positioned(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.timeLeftLabelAt(now),
                      style: AppTextStyles.caption.copyWith(color: AppColors.surface, letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '♥ ${status.likesCount}   💬 ${status.commentsCount}',
                      style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.surface.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    this.badge,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? badge;

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
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [Text(title, style: AppTextStyles.bodyStrong), ?badge],
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
