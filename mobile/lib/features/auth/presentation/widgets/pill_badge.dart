import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A small fully rounded label: eyebrows, "Popular", "VENDOR PORTAL", "SMS Ready".
class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.label,
    this.background = AppColors.successBg,
    this.foreground = AppColors.primary,
    this.borderColor,
    this.leading,
    this.uppercase = false,
  });

  /// The green-tinted eyebrow used above screen headings.
  const PillBadge.eyebrow(
    this.label, {
    super.key,
    this.leading,
  })  : background = AppColors.successBg,
        foreground = AppColors.successText,
        borderColor = AppColors.successBorder,
        uppercase = true;

  /// The orange vendor-portal badge.
  const PillBadge.orange(this.label, {super.key, this.leading})
      : background = AppColors.orangeAccentBg,
        foreground = AppColors.orangeAccentText,
        borderColor = null,
        uppercase = true;

  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final Widget? leading;

  /// Micro badges are set in capitals; the text is uppercased here so the
  /// callers keep the words as written.
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              style: AppTextStyles.caption.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
