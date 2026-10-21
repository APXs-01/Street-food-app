import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/discovery_stall.dart';
import '../../presentation/widgets/map_layout.dart';
import '../../presentation/widgets/map_pins.dart';
import '../../presentation/widgets/map_quick_info_card.dart';
import '../../presentation/widgets/simulated_map.dart';
import '../../providers/discovery_providers.dart';

/// The "Live Hygiene Radar" card on the home screen: a 256px map preview with
/// the nearest stalls as pins and the quick-info card for the selected one
/// (the nearest, until another pin is tapped). Tapping the map opens the Full
/// Map; tapping the quick-info card opens that stall's profile.
class RadarPreview extends StatefulWidget {
  const RadarPreview({super.key, required this.stalls, required this.center});

  /// Nearest first; never empty.
  final List<DiscoveryStall> stalls;
  final SearchCenter center;

  /// How many pins the preview draws.
  static const maxPins = 6;

  @override
  State<RadarPreview> createState() => _RadarPreviewState();
}

class _RadarPreviewState extends State<RadarPreview> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);
    final shown = widget.stalls.take(RadarPreview.maxPins).toList();
    final featured = shown.firstWhere((stall) => stall.id == _selectedId, orElse: () => shown.first);
    final spots = layoutOnMap(shown, widget.center);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        height: 256,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppShadows.cardBorder),
          boxShadow: const [AppShadows.card],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push(Routes.consumerMap),
                  child: SimulatedMap(
                    placements: [
                      MapPlacement(x: kMapCentre.x, y: kMapCentre.y, centered: true, child: const UserLocationDot(accuracyRadius: 26)),
                      for (final stall in shown)
                        if (spots[stall.id] != null && stall.id != featured.id)
                          MapPlacement(
                            x: spots[stall.id]!.x,
                            y: spots[stall.id]!.y,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedId = stall.id),
                              child: CompactPin(label: stall.ratingLabel, caution: stall.isCaution),
                            ),
                          ),
                      if (spots[featured.id] != null)
                        MapPlacement(
                          x: spots[featured.id]!.x,
                          y: spots[featured.id]!.y,
                          child: CompactPin(label: featured.ratingLabel, caution: featured.isCaution, large: true),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                top: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.skyBlue, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.homeRadarStallsNearby(widget.stalls.length),
                        style: AppTextStyles.caption.copyWith(letterSpacing: 0.2, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: MapQuickInfoCard(stall: featured),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
