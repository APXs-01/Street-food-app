import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A round avatar: the person's own photo when they have one, otherwise their
/// initial on mint. There is no stand-in picture: a face is only shown when it is real.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.name, this.photoUrl, this.size = 40, this.ringColor});

  final String name;

  /// The person's avatar from the API; null or empty shows the initial.
  final String? photoUrl;
  final double size;

  /// A border drawn around the avatar (white, to overlap in a stack).
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: AppColors.primaryLight.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Text(
        initialOf(name),
        style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primary, fontSize: size * 0.4),
      ),
    );

    final url = photoUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ringColor == null ? null : Border.all(color: ringColor!, width: 2),
      ),
      child: ClipOval(
        child: url == null || url.isEmpty
            ? fallback
            : Image.network(
                ApiConfig.resolveMedia(url),
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
                errorBuilder: (context, error, stack) => fallback,
              ),
      ),
    );
  }
}
