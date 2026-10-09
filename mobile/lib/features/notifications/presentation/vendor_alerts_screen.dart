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
import '../../consumer/presentation/widgets/stall_thumbnail.dart';
import '../../vendor/providers/vendor_providers.dart';
import '../data/alert_models.dart';
import '../providers/alerts_providers.dart';

/// The vendor's notifications for their own stall, read from
/// `GET /notifications`: reviews, hygiene updates, and comments and likes on
/// their statuses. Opened from the bell. The server has no delete, so the old
/// "Clear All" is "Mark all read". There is no review-reply endpoint, so the
/// "Reply to Review" button is shown switched off.
class VendorAlertsScreen extends ConsumerStatefulWidget {
  const VendorAlertsScreen({super.key});

  @override
  ConsumerState<VendorAlertsScreen> createState() => _VendorAlertsScreenState();
}

class _VendorAlertsScreenState extends ConsumerState<VendorAlertsScreen> {
  VendorAlertFilter _filter = VendorAlertFilter.all;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.vendorHome);
    }
  }

  void _markRead(AppAlert alert) {
    if (alert.isRead) return;

    // Fire and forget: the badge catches up when the list reloads.
    ref.read(alertRepositoryProvider).markRead(alert.id).then((_) => ref.invalidate(alertsProvider), onError: (_) {});
  }

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

  @override
  Widget build(BuildContext context) {
    final stall = ref.watch(vendorStallProvider).asData?.value;
    final async = ref.watch(alertsProvider);
    final alerts = async.asData?.value.items ?? const <AppAlert>[];
    final unread = ref.watch(unreadAlertsProvider);
    final visible = alerts.where(_filter.matches).toList();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.screenPadding, AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(tooltip: context.l10n.commonBack, icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: _back),
                  if (stall != null) ...[
                    ClipOval(child: StallThumbnail(url: stall.photoUrl, width: 36, height: 36, radius: 18, iconSize: 18)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stall.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13)),
                          Text(
                            [stall.stallNumberLabel, stall.locationLabel].where((part) => part.isNotEmpty).join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    const Spacer(),
                  const SizedBox(width: AppSpacing.sm),
                  PillBadge(
                    label: context.l10n.vaVendorView,
                    uppercase: true,
                    background: AppColors.orangeAccentBg,
                    foreground: AppColors.orangeAccentText,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(alertsProvider);
                  await ref.read(alertsProvider.future).then((_) {}, onError: (_) {});
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.xxl),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.vaTitle, style: AppTextStyles.display.copyWith(fontSize: 28, height: 1.15)),
                              const SizedBox(height: 2),
                              Text(
                                unread == 0 ? context.l10n.vaSubtitle : context.l10n.alertsUnreadCount(unread),
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
                        itemCount: VendorAlertFilter.values.length,
                        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final filter = VendorAlertFilter.values[index];

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
                      builder: (_) {
                        if (visible.isEmpty) {
                          return EmptyNote(alerts.isEmpty ? context.l10n.vaNone : context.l10n.vaNothingForFilter);
                        }

                        return Column(
                          children: [
                            for (final alert in visible) ...[
                              _AlertCard(
                                alert: alert,
                                now: now,
                                onOpenHygiene: stall == null
                                    ? null
                                    : () {
                                        _markRead(alert);
                                        context.push(Routes.vendorStall(stall.id, tab: 'hygiene'));
                                      },
                                onOpenStatus: alert.statusId == null
                                    ? null
                                    : () {
                                        _markRead(alert);
                                        context.push(Routes.vendorStatus(alert.statusId!));
                                      },
                                onOpenReviews: stall == null
                                    ? null
                                    : () {
                                        _markRead(alert);
                                        context.push(Routes.vendorStall(stall.id, tab: 'reviews'));
                                      },
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            child: Text(label, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: selected ? AppColors.surface : AppColors.textPrimary)),
          ),
        ),
      ),
    );
  }
}

/// The unread dot colour for each type.
Color _dotColor(AlertType type) => switch (type) {
      AlertType.newReview => AppColors.amber,
      AlertType.hygieneUpdated || AlertType.hygieneOverdue => AppColors.secondary,
      AlertType.statusComment => AppColors.skyBlue,
      AlertType.statusLike => AppColors.lavender,
      _ => AppColors.secondary,
    };

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.now,
    required this.onOpenHygiene,
    required this.onOpenStatus,
    required this.onOpenReviews,
  });

  final AppAlert alert;
  final DateTime now;
  final VoidCallback? onOpenHygiene;
  final VoidCallback? onOpenStatus;
  final VoidCallback? onOpenReviews;

  @override
  Widget build(BuildContext context) {
    final isHygiene = alert.type == AlertType.hygieneUpdated;
    final body = alert.body?.trim() ?? '';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeIcon(type: alert.type),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: AppTextStyles.bodyStrong.copyWith(fontSize: 14, height: 1.3)),
                  const SizedBox(height: 2),
                  Text(agoFrom(alert.createdAt, now: now), style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (!alert.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(color: _dotColor(alert.type), shape: BoxShape.circle),
              ),
          ],
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _InsetText(text: body, rating: alert.type == AlertType.newReview ? alert.rating : null),
        ],
        ..._actions(context),
      ],
    );

    if (isHygiene) {
      // Good news: a mint border and a soft gradient set it apart from the white cards.
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.successBg, AppColors.surface],
          ),
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.55), width: 1.5),
          boxShadow: const [AppShadows.card],
        ),
        child: content,
      );
    }

    return SurfaceCard(padding: const EdgeInsets.all(AppSpacing.lg), child: content);
  }

  List<Widget> _actions(BuildContext context) {
    switch (alert.type) {
      case AlertType.newReview:
        return [
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ActionButton(label: context.l10n.vaSeeReviews, icon: Icons.rate_review_outlined, onTap: onOpenReviews),
              // The API has no review-reply endpoint, so this stays off.
              _ActionButton(label: context.l10n.vaReplyUnavailable, icon: Icons.reply, onTap: null),
            ],
          ),
        ];
      case AlertType.hygieneUpdated:
      case AlertType.hygieneOverdue:
        return [
          if (alert.type == AlertType.hygieneUpdated && alert.score != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (alert.previousScore != null) ...[
                  Text(context.l10n.alertScoreWas(alert.previousScore!.toStringAsFixed(1)), style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
                  const Icon(Icons.arrow_right_alt, size: 20, color: AppColors.textMuted),
                ],
                Text(alert.score!.toStringAsFixed(1), style: AppTextStyles.display.copyWith(fontSize: 28, height: 1, color: AppColors.successText)),
                Text(' / 5', style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _ActionButton(label: context.l10n.vaViewHygiene, icon: Icons.description_outlined, onTap: onOpenHygiene),
        ];
      case AlertType.statusComment:
        return [
          const SizedBox(height: AppSpacing.md),
          _ActionButton(label: context.l10n.vaViewReply, icon: Icons.chat_bubble_outline, onTap: onOpenStatus),
        ];
      case AlertType.statusLike:
        return [
          if (onOpenStatus != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ActionButton(label: context.l10n.vaViewStatus, icon: Icons.slideshow_outlined, onTap: onOpenStatus),
          ],
        ];
      default:
        return const [];
    }
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final AlertType type;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color background, Color color) = switch (type) {
      AlertType.newReview => (Icons.rate_review_outlined, AppColors.orangeAccentBg, AppColors.orangeAccentText),
      AlertType.hygieneUpdated => (Icons.verified_user, AppColors.primaryLight, AppColors.primary),
      AlertType.hygieneOverdue => (Icons.schedule, AppColors.amberBg, AppColors.orangeAccentText),
      AlertType.statusComment => (Icons.chat_bubble_outline, const Color(0xFFDBEAFE), AppColors.skyBlue),
      AlertType.statusLike => (Icons.favorite, AppColors.lavenderBg, AppColors.lavender),
      _ => (Icons.notifications_none_rounded, AppColors.borderLight, AppColors.textSecondary),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.softButton)),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// The server's one-line description in a grey box, with stars if it is a review.
class _InsetText extends StatelessWidget {
  const _InsetText({required this.text, this.rating});

  final String text;
  final int? rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.softButton)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rating != null) ...[
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(i <= rating! ? Icons.star_rounded : Icons.star_outline_rounded, size: 14, color: AppColors.amber),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Text(text, style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.45, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;

  /// Null switches the button off.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: AppTextStyles.button.copyWith(fontSize: 12)),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.borderLight,
        disabledForegroundColor: AppColors.textMuted,
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
    );
  }
}
