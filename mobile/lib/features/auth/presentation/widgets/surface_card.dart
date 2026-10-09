import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// The white rounded card: 16px radius, hairline border, soft shadow. An
/// [accentColor] adds the 6px bar down the left edge.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.surface,
    this.borderColor,
    this.accentColor,
    this.shadow = true,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final Color? accentColor;
  final bool shadow;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final padded = Padding(padding: padding, child: child);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: borderColor ?? AppShadows.cardBorder, width: borderWidth),
        boxShadow: shadow ? const [AppShadows.card] : null,
      ),
      child: accentColor == null
          ? padded
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 6, color: accentColor),
                  Expanded(child: padded),
                ],
              ),
            ),
    );
  }
}
