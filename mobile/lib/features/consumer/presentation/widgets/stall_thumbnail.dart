import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A stall's photo with a food icon on mint while it loads or when it cannot
/// load (no network, bad URL). Optional [badge] sits in the top-left corner.
class StallThumbnail extends StatelessWidget {
  const StallThumbnail({
    super.key,
    required this.url,
    this.width = 96,
    this.height = 96,
    this.radius = 12,
    this.badge,
    this.iconSize = 28,
  });

  final String url;
  final double width;
  final double height;
  final double radius;
  final double iconSize;

  /// Text such as `#1` laid over the top-left corner.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            // No photo (the stall has none): the food icon on mint, without a request.
            child: url.isEmpty
                ? _placeholder()
                : Image.network(
                    ApiConfig.resolveMedia(url),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) => progress == null ? child : _placeholder(),
                    errorBuilder: (context, error, stack) => _placeholder(),
                  ),
          ),
          if (badge != null)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.surface, letterSpacing: 0, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.4),
      alignment: Alignment.center,
      child: Icon(Icons.restaurant, size: iconSize, color: AppColors.primary),
    );
  }
}
