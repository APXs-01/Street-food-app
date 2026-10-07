import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/presentation/widgets/pill_badge.dart';
import '../../auth/presentation/widgets/surface_card.dart';
import '../../statuses/data/status_models.dart';
import '../../statuses/providers/status_providers.dart';
import '../presentation/widgets/stall_thumbnail.dart';

/// "My Status History & Vault": every status the customer has posted that the
/// server still holds, live or expired (`GET /statuses?mine=1`). Statuses leave
/// the radar after 24 hours; the server's daily purge removes them later, so
/// "vault" is only as long as that retention.
class StatusHistoryScreen extends ConsumerWidget {
  const StatusHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(myStatusesProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.shTitle, style: AppTextStyles.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.consumerProfile),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(myStatusesProvider);
          await ref.read(myStatusesProvider.future).then((_) {}, onError: (_) {});
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            AsyncView<List<StatusPost>>(
              value: statuses,
              onRetry: () => ref.invalidate(myStatusesProvider),
              builder: (list) {
                if (list.isEmpty) {
                  return EmptyNote(context.l10n.shEmpty);
                }

                return Column(
                  children: [
                    for (final status in list) ...[
                      _HistoryCard(status: status, now: now),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.status, required this.now});

  final StatusPost status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final live = status.isActive && status.remainingAt(now) > Duration.zero;
    final caption = status.caption?.trim() ?? '';

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push(Routes.consumerStatus(status.id)),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StallThumbnail(url: status.photoUrl, width: 72, height: 72, radius: 12),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PillBadge(
                          label: status.isHidden ? context.l10n.shHidden : (live ? context.l10n.shLive : context.l10n.shArchived),
                          background: live && !status.isHidden ? AppColors.successBg : AppColors.borderLight,
                          foreground: live && !status.isHidden ? AppColors.successText : AppColors.textSecondary,
                        ),
                        const Spacer(),
                        Text(status.postedAgoLabelAt(now), style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    if (caption.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13)),
                    ],
                    if (status.vendorName != null)
                      Text('📍 ${status.vendorName}', style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      '♥ ${status.likesCount}   💬 ${status.commentsCount}',
                      style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.textMuted),
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
