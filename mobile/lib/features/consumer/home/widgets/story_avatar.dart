import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../statuses/data/status_models.dart';

/// One "Daily Fresh Story": a 64px photo in a coloured ring (emerald, or amber
/// in the last hour) with a countdown pill overlapping the bottom edge, and the
/// name of the stall or person underneath.
class StoryAvatar extends StatelessWidget {
  const StoryAvatar({super.key, required this.story, required this.onTap});

  final StoryCircle story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ring = story.cautionAt(now) ? AppColors.amber : AppColors.secondary;
    final timeLeft = story.timeLeftLabelAt(now);

    return Semantics(
      button: true,
      label: '${story.name}, $timeLeft',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: 3)),
                    child: ClipOval(
                      child: story.photoUrl.isEmpty
                          ? _fallback()
                          : Image.network(
                              ApiConfig.resolveMedia(story.photoUrl),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => _fallback(),
                              loadingBuilder: (context, child, progress) => progress == null ? child : _fallback(),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: -9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ring,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                      child: Text(
                        timeLeft,
                        style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0, color: AppColors.surface),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                story.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.primaryLight.withValues(alpha: 0.4),
      alignment: Alignment.center,
      child: Text(initialOf(story.name), style: AppTextStyles.title.copyWith(color: AppColors.primary)),
    );
  }
}
