import 'package:flutter/material.dart';

import '../../../../../core/localization/l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../data/onboarding_draft.dart';

/// "Opens" or "Closes": a tappable box that shows the chosen time as `5:00 PM`.
/// The picker itself is opened by the caller through [onTap].
class TimeField extends StatelessWidget {
  const TimeField({super.key, required this.label, required this.value, required this.onTap, this.hasError = false});

  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.input);
    final time = value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: time == null ? context.l10n.obTimeNotSet(label) : context.l10n.obTimeValue(label, formatTime12(time)),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: radius,
                border: Border.all(color: hasError ? AppColors.error : AppColors.border.withValues(alpha: 0.65)),
              ),
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 15),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          time == null ? context.l10n.obSelectTime : formatTime12(time),
                          style: time == null ? AppTextStyles.hint : AppTextStyles.input,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
