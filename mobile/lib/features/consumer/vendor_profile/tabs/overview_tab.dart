import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../auth/presentation/widgets/pill_badge.dart';
import '../../../auth/presentation/widgets/primary_button.dart';
import '../../../auth/presentation/widgets/surface_card.dart';
import '../../data/discovery_stall.dart';
import '../../presentation/widgets/stall_thumbnail.dart';

/// Overview: about, operating hours, the menu and the "Leave a Review" call to
/// action. All of it comes from `GET /vendors/{id}`; a part the vendor has not
/// filled in says so instead of showing sample text.
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key, required this.stall, required this.onLeaveReview});

  final DiscoveryStall stall;

  /// Null hides the button (a vendor viewing their own stall).
  final VoidCallback? onLeaveReview;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  bool _hoursExpanded = false;

  @override
  Widget build(BuildContext context) {
    final stall = widget.stall;
    final about = stall.description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant, size: 20, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.vpAbout(stall.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                about.isEmpty ? context.l10n.vpNoDescription : about,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  height: 1.55,
                  color: about.isEmpty ? AppColors.textMuted : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _HoursCard(
          stall: stall,
          expanded: _hoursExpanded,
          onToggle: () => setState(() => _hoursExpanded = !_hoursExpanded),
        ),
        const SizedBox(height: AppSpacing.lg),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.vpMenu, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              if (stall.menu.isEmpty)
                EmptyNote(context.l10n.vpNoMenu)
              else
                for (var i = 0; i < stall.menu.length; i++) ...[
                  if (i > 0) const Divider(),
                  _MenuRow(item: stall.menu[i]),
                ],
            ],
          ),
        ),
        if (widget.onLeaveReview != null) ...[
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: context.l10n.vpLeaveReview,
            trailingIcon: null,
            onPressed: widget.onLeaveReview!,
          ),
        ],
      ],
    );
  }
}

class _HoursCard extends StatelessWidget {
  const _HoursCard({required this.stall, required this.expanded, required this.onToggle});

  final DiscoveryStall stall;
  final bool expanded;
  final VoidCallback onToggle;

  List<String> get _days => [
        l10n.dayMonday,
        l10n.dayTuesday,
        l10n.dayWednesday,
        l10n.dayThursday,
        l10n.dayFriday,
        l10n.daySaturday,
        l10n.daySunday,
      ];

  /// `5 PM – 2 AM`, or null when the vendor has not set hours.
  String? get _hours {
    final opens = stall.opensAt;
    final closes = stall.closesAt;
    if (opens == null || closes == null) return null;

    return '${clockLabel(opens)} – ${clockLabel(closes)}';
  }

  /// The days the stall opens; null means every day.
  bool _opensOn(int isoDay) => stall.openDays == null || stall.openDays!.contains(isoDay);

  @override
  Widget build(BuildContext context) {
    final hours = _hours;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: hours == null ? null : onToggle,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: const Icon(Icons.schedule, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(context.l10n.vpOperatingHours, style: AppTextStyles.bodyStrong),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: stall.isOpenNow ? AppColors.secondary : AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hours == null
                              ? context.l10n.vpHoursNotSet
                              : (stall.isOpenNow ? context.l10n.vpHoursOpenNow(hours) : context.l10n.vpHoursClosedNow(hours)),
                          style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (hours != null)
                    AnimatedRotation(
                      turns: expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ),
                ],
              ),
              if (expanded && hours != null) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < _days.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text(_days[i], style: AppTextStyles.body.copyWith(fontSize: 12))),
                        Text(
                          _opensOn(i + 1) ? hours : context.l10n.vpClosed,
                          style: AppTextStyles.bodyStrong.copyWith(
                            fontSize: 12,
                            color: _opensOn(i + 1) ? null : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final StallMenuItem item;

  @override
  Widget build(BuildContext context) {
    final description = item.description?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Opacity(
        opacity: item.isAvailable ? 1 : 0.55,
        child: Row(
          children: [
            StallThumbnail(url: item.photoUrl ?? '', width: 48, height: 48, radius: 10, iconSize: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.priceLabel, style: AppTextStyles.bodyStrong.copyWith(color: AppColors.secondary)),
                if (!item.isAvailable)
                  PillBadge(label: context.l10n.vpSoldOut, background: AppColors.borderLight, foreground: AppColors.textMuted)
                else if (item.isFreshToday)
                  Text(
                    context.l10n.vpFreshToday,
                    style: AppTextStyles.caption.copyWith(color: AppColors.secondary, letterSpacing: 0.2, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
