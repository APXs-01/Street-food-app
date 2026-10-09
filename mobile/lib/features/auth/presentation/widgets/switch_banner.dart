import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The tappable card that moves between the customer and vendor sides: a round
/// icon, a small eyebrow, a line of text and a chevron. Mint by default (the
/// customer login's "Vendor Portal"); [white] gives the vendor login's
/// "Are you a customer?" card.
class SwitchBanner extends StatelessWidget {
  const SwitchBanner({
    super.key,
    required this.eyebrow,
    required this.text,
    required this.onTap,
    required this.icon,
    this.iconBackground = AppColors.primary,
    this.iconColor = AppColors.surface,
    this.white = false,
  });

  final String eyebrow;
  final String text;
  final VoidCallback onTap;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final bool white;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: white ? AppColors.surface : AppColors.successBg,
          borderRadius: radius,
          border: Border.all(color: white ? AppShadows.cardBorder : AppColors.successBorder),
          boxShadow: white ? const [AppShadows.card] : null,
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(color: white ? AppColors.textMuted : AppColors.successText),
                      ),
                      const SizedBox(height: 2),
                      Text(text, style: AppTextStyles.bodyStrong),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: white ? AppColors.textMuted : AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
