import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The tabs of the vendor profile.
enum VendorProfileTab { overview, hygiene, reviews }

/// The pill-shaped segmented tab bar: a light grey track with a white pill (and
/// a soft shadow) behind the active tab. One widget drives all three tab bodies;
/// the screen owns which is active.
class VendorProfileTabs extends StatelessWidget {
  const VendorProfileTabs({super.key, required this.current, required this.reviewCount, required this.onChanged});

  final VendorProfileTab current;
  final int reviewCount;
  final ValueChanged<VendorProfileTab> onChanged;

  String _label(VendorProfileTab tab) => switch (tab) {
        VendorProfileTab.overview => l10n.vpTabOverview,
        VendorProfileTab.hygiene => l10n.vpTabHygiene,
        VendorProfileTab.reviews => l10n.vpTabReviews(reviewCount),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final tab in VendorProfileTab.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: tab == current,
                label: _label(tab),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
                    decoration: BoxDecoration(
                      color: tab == current ? AppColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: tab == current
                          ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _label(tab),
                        maxLines: 1,
                        style: AppTextStyles.bodyStrong.copyWith(
                          fontSize: 12,
                          color: tab == current ? AppColors.secondary : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
