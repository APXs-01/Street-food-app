import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A rounded frosted-glass container: the page behind it shows blurred through
/// a translucent white. Used for the buttons and badges over the hero photo.
class Frosted extends StatelessWidget {
  const Frosted({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 999,
    this.opacity = 0.82,
    this.color = AppColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.surface.withValues(alpha: 0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A 44px frosted white circle with an icon: back, bookmark, share.
class FrostedCircleButton extends StatelessWidget {
  const FrostedCircleButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.iconColor});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Frosted(
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: iconColor ?? AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
