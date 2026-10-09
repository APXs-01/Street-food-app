import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A round avatar showing a person's initial on mint. No photo: reviewers and
/// commenters on the vendor side are shown by initial.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({super.key, required this.name, this.size = 40, this.color});

  final String name;
  final double size;

  /// Defaults to mint with a green initial.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color ?? AppColors.primaryLight.withValues(alpha: 0.55), shape: BoxShape.circle),
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase(),
        style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primary, fontSize: size * 0.42),
      ),
    );
  }
}
