import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// The thin progress bar under the header: [total] segments, the first
/// [filled] of them green. Stall onboarding is the last step, so both are filled.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({super.key, this.total = 2, this.filled = 2});

  final int total;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < filled ? AppColors.primary : AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
