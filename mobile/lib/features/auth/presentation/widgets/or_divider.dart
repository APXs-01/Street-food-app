import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A rule with a label in the middle: "or continue with".
class OrDivider extends StatelessWidget {
  const OrDivider(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, letterSpacing: 0.3),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
