import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../data/stall_category.dart';

/// A selectable category: green with a check when picked, light grey when not.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, required this.selected, required this.onTap});

  final StallCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.input);
    final foreground = selected ? AppColors.surface : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceMuted,
            borderRadius: radius,
            border: Border.all(color: selected ? AppColors.primary : AppColors.border.withValues(alpha: 0.6)),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        category.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: foreground),
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.check_circle, size: 18, color: AppColors.surface),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
