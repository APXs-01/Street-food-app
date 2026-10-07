import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/discovery_stall.dart';

Color _pinColor(bool caution) => caution ? AppColors.amber : AppColors.secondary;

/// The little pointer under a pin's head.
class _Stem extends StatelessWidget {
  const _Stem({required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size * 1.6, size), painter: _StemPainter(color));
  }
}

class _StemPainter extends CustomPainter {
  _StemPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StemPainter old) => old.color != color;
}

/// A regular map pin: a rounded badge with the stall's name and star rating,
/// emerald when clean and amber (with a warning triangle) when in caution.
class RatingPin extends StatelessWidget {
  const RatingPin({super.key, required this.stall, required this.onTap});

  final DiscoveryStall stall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _pinColor(stall.isCaution);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.surface, width: 1.5),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (stall.isCaution) ...[
                  const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.surface),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    stall.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.surface, letterSpacing: 0),
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.star_rounded, size: 12, color: AppColors.surface),
                Text(
                  stall.ratingLabel,
                  style: AppTextStyles.caption.copyWith(color: AppColors.surface, letterSpacing: 0),
                ),
              ],
            ),
          ),
          _Stem(color: color),
        ],
      ),
    );
  }
}

/// The selected pin: larger, with an icon head, a bold rating badge and a soft
/// pulsing ring on the ground beneath it.
class SelectedPin extends StatefulWidget {
  const SelectedPin({super.key, required this.stall, required this.onTap});

  final DiscoveryStall stall;
  final VoidCallback onTap;

  @override
  State<SelectedPin> createState() => _SelectedPinState();
}

class _SelectedPinState extends State<SelectedPin> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _pinColor(widget.stall.isCaution);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color, width: 1.5),
              boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 14, color: color),
                const SizedBox(width: 2),
                Text(
                  widget.stall.ratingLabel,
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 13, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 3),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(widget.stall.isCaution ? Icons.warning_amber_rounded : Icons.restaurant, color: AppColors.surface, size: 22),
          ),
          _Stem(color: color, size: 9),
          SizedBox(
            width: 56,
            height: 14,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = _pulse.value;

                return Center(
                  child: Container(
                    width: 22 + 34 * t,
                    height: 6 + 8 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.28 * (1 - t)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A small rating-only pin for the map preview on the home screen.
class CompactPin extends StatelessWidget {
  const CompactPin({super.key, required this.label, this.caution = false, this.large = false});

  /// The rating text on the pin: `4.9`, or `New`.
  final String label;
  final bool caution;

  /// The one selected pin on the preview is larger.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = _pinColor(caution);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 7 : 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.surface, width: large ? 2 : 1.5),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyStrong.copyWith(fontSize: large ? 14 : 11, color: AppColors.surface),
          ),
        ),
        _Stem(color: color, size: large ? 9 : 6),
      ],
    );
  }
}

/// A numbered pin for the split screen: the number matches the stall's card in
/// the list. White with a grey number normally, emerald with white when selected.
class NumberedPin extends StatelessWidget {
  const NumberedPin({super.key, required this.number, required this.selected, required this.onTap});

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 38.0 : 30.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.secondary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? AppColors.surface : AppColors.border, width: selected ? 2.5 : 1.5),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Text(
              '$number',
              style: AppTextStyles.bodyStrong.copyWith(
                fontSize: selected ? 16 : 13,
                color: selected ? AppColors.surface : AppColors.textMuted,
              ),
            ),
          ),
          _Stem(color: selected ? AppColors.secondary : AppColors.surface, size: 6),
        ],
      ),
    );
  }
}

/// The user's own position: a blue dot inside a translucent accuracy ring.
class UserLocationDot extends StatelessWidget {
  const UserLocationDot({super.key, this.accuracyRadius = 44});

  final double accuracyRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: accuracyRadius * 2,
      height: accuracyRadius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.skyBlue.withValues(alpha: 0.16),
        border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.skyBlue,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4)],
        ),
      ),
    );
  }
}
