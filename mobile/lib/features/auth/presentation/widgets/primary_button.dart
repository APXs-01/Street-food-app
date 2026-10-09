import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The full-width pill call to action. While [isLoading] it shows a spinner and
/// cannot be pressed, so a request is never sent twice.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color = AppColors.primary,
    this.trailingIcon = Icons.arrow_forward,
    this.labelStyle,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  /// False greys the button out and ignores taps (for example, until a rating is chosen).
  final bool enabled;

  /// Consumer screens use AppColors.primary, the vendor sign-up AppColors.vendorAccent.
  final Color color;
  final IconData? trailingIcon;

  /// Overrides the default 14px bold label.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: isLoading || !enabled ? const [] : [AppShadows.button(color)],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: isLoading || !enabled ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: AppColors.surface,
            // While loading it stays green with a spinner; when disabled it goes grey.
            disabledBackgroundColor: enabled ? color.withValues(alpha: 0.75) : AppColors.borderLight,
            disabledForegroundColor: enabled ? AppColors.surface : AppColors.textMuted,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.surface),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: (labelStyle ?? AppTextStyles.button).copyWith(color: enabled ? null : AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(trailingIcon, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
