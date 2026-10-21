import 'package:flutter/material.dart';

import '../../../../auth/presentation/widgets/surface_card.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// One field group of the onboarding form: a white bordered card with a title
/// (and optional red asterisk and trailing widget) and an error line at the bottom.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.isRequired = false,
    this.trailing,
    this.errorText,
  });

  final String title;
  final Widget child;
  final bool isRequired;
  final Widget? trailing;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      borderColor: errorText == null ? null : AppColors.error.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: title,
                    style: AppTextStyles.label.copyWith(fontSize: 14),
                    children: [
                      if (isRequired)
                        TextSpan(text: ' *', style: AppTextStyles.label.copyWith(fontSize: 14, color: AppColors.error)),
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
          if (errorText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ErrorLine(errorText!),
          ],
        ],
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline, size: 14, color: AppColors.error),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.caption.copyWith(color: AppColors.error, letterSpacing: 0, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
