import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/json.dart';
import '../../../core/format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/presentation/widgets/pill_badge.dart';
import '../../auth/presentation/widgets/surface_card.dart';
import '../../notifications/data/alert_models.dart';
import '../../notifications/providers/alerts_providers.dart';
import '../../vendor/onboarding/presentation/widgets/dashed_border.dart';
import '../presentation/widgets/consumer_bottom_nav.dart';

/// The customer's notifications, read from `GET /notifications`: updates from
/// stalls they follow, likes and comments on their statuses, friend requests.
/// Tapping one marks it read. The server has no delete, so the old "Clear All"
/// is "Mark all read".
class ConsumerAlertsScreen extends ConsumerStatefulWidget {
  const ConsumerAlertsScreen({super.key});

  @override
  ConsumerState<ConsumerAlertsScreen> createState() => _ConsumerAlertsScreenState();
}

class _ConsumerAlertsScreenState extends ConsumerState<ConsumerAlertsScreen> {
  ConsumerAlertFilter _filter = ConsumerAlertFilter.all;

  Future<void> _markAllRead() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(alertRepositoryProvider).markAllRead();
      ref.invalidate(alertsProvider);
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }

  Future<void> _open(AppAlert alert) async {
    if (!alert.isRead) {
      // Fire and forget: the badge catches up when the list reloads.
      ref.read(alertRepositoryProvider).markRead(alert.id).then((_) => ref.invalidate(alertsProvider), onError: (_) {});
    }

    final statusId = alert.statusId;
    final vendorId = alert.vendorId;

    switch (alert.type) {
      case AlertType.friendRequest:
      case AlertType.friendAccepted:
        context.push(Routes.consumerFriends);
      case AlertType.hygieneUpdated:
      case AlertType.hygieneOverdue:
        if (vendorId != null) context.push(Routes.consumerVendor(vendorId));
      case AlertType.vendorStatus:
      case AlertType.statusComment:
      case AlertType.statusLike:
        if (statusId != null) context.push(Routes.consumerStatus(statusId));
      case AlertType.newReview:
      case AlertType.unknown:
        if (vendorId != null) context.push(Routes.consumerVendor(vendorId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(alertsProvider);
    final alerts = async.asData?.value.items ?? const <AppAlert>[];
    final unread = ref.watch(unreadAlertsProvider);
    final visible = alerts.where(_filter.matches).toList();
    final now = DateTime.now();

    return ConsumerScaffold(
      tab: ConsumerTab.alerts,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(alertsProvider);
            await ref.read(alertsProvider.future).then((_) {}, onError: (_) {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, ConsumerScaffold.navClearance),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.alertsTitle, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.15)),
                        const SizedBox(height: 2),
                        Text(
                          unread == 0 ? context.l10n.alertsSubtitle : context.l10n.alertsUnreadCount(unread),
                          style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: unread == 0 ? null : _markAllRead,
                    child: Text(context.l10n.alertsMarkAllRead, style: AppTextStyles.link.copyWith(color: unread == 0 ? AppColors.textMuted : AppColors.secondary)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ConsumerAlertFilter.values.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final filter = ConsumerAlertFilter.values[index];

                    return _FilterPill(
                      label: async.hasValue ? '${filter.label} (${alerts.where(filter.matches).length})' : filter.label,
                      selected: filter == _filter,
                      onTap: () => setState(() => _filter = filter),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AsyncView<({List<AppAlert> items, int unread})>(
                value: async,
                onRetry: () => ref.invalidate(alertsProvider),
                builder: (_) => visible.isEmpty
                    ? const _CaughtUp()
                    : Column(
                        children: [
                          for (final alert in visible) ...[
                            _AlertCard(alert: alert, now: now, onTap: () => _open(alert)),
                            const SizedBox(height: AppSpacing.md),
                          ],
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.textPrimary : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.textPrimary : AppColors.border.withValues(alpha: 0.8))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: selected ? AppColors.surface : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// "You're All Caught Up!" in a dashed card, with a way back to discovery.
class _CaughtUp extends StatelessWidget {
  const _CaughtUp();

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: AppColors.border,
      radius: AppRadii.card,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_off_outlined, size: 30, color: AppColors.secondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.l10n.alertsCaughtUp, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.alertsCaughtUpBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.push(Routes.consumerMap),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.surface,
                shape: const StadiumBorder(),
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
              child: Text(context.l10n.alertsDiscover, style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.now, required this.onTap});

  final AppAlert alert;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (String category, IconData icon) = switch (alert.type) {
      AlertType.vendorStatus => (context.l10n.alertTypeStallUpdate, Icons.storefront),
      AlertType.statusComment => (context.l10n.alertTypeComment, Icons.chat_bubble_outline),
      AlertType.statusLike => (context.l10n.alertTypeLike, Icons.favorite_border),
      AlertType.friendRequest => (context.l10n.alertTypeFriendRequest, Icons.person_add_alt),
      AlertType.friendAccepted => (context.l10n.alertTypeNewFriend, Icons.group_outlined),
      AlertType.hygieneUpdated => (context.l10n.alertTypeHygieneUpdate, Icons.verified_user),
      AlertType.hygieneOverdue => (context.l10n.alertTypeRecheck, Icons.schedule),
      AlertType.newReview => (context.l10n.alertTypeNewReview, Icons.rate_review_outlined),
      AlertType.unknown => (context.l10n.alertTypeOther, Icons.notifications_none_rounded),
    };

    final showScore = alert.type == AlertType.hygieneUpdated && alert.score != null;
    final body = alert.body?.trim() ?? '';

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.secondary, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PillBadge(label: category, background: AppColors.successBg, foreground: AppColors.successText),
                        const Spacer(),
                        if (!alert.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                          ),
                        Text(
                          agoFrom(alert.createdAt, now: now),
                          style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.title,
                      style: AppTextStyles.bodyStrong.copyWith(fontSize: 14, height: 1.3, fontWeight: alert.isRead ? FontWeight.w600 : FontWeight.w800),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(body, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                    ],
                    if (showScore) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _HygieneStrip(score: alert.score!, previous: alert.previousScore),
                    ],
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

class _HygieneStrip extends StatelessWidget {
  const _HygieneStrip({required this.score, required this.previous});

  final double score;
  final double? previous;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(AppRadii.softButton)),
      child: Row(
        children: [
          Text(score.toStringAsFixed(1), style: AppTextStyles.display.copyWith(fontSize: 22, height: 1, color: AppColors.successText)),
          const Icon(Icons.star_rounded, size: 18, color: AppColors.amber),
          if (previous != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(context.l10n.alertScoreWas(previous!.toStringAsFixed(1)), style: AppTextStyles.bodyStrong.copyWith(fontSize: 11, color: AppColors.successText)),
          ],
        ],
      ),
    );
  }
}
