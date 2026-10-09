import 'package:flutter/painting.dart';

import 'app_colors.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal padding of every screen.
  static const double screenPadding = 16;

  /// Auth screens stop growing on tablets and landscape phones.
  static const double maxContentWidth = 480;
}

abstract final class AppRadii {
  static const double input = 14;
  static const double card = 16;
  static const double pill = 999;
  static const double softButton = 12;
}

abstract final class AppShadows {
  /// 0px 4px 16px rgba(15, 23, 42, 0.04)
  static const BoxShadow card = BoxShadow(
    color: Color(0x0A0F172A),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static BoxShadow button(Color color) => BoxShadow(
        color: color.withValues(alpha: 0.28),
        blurRadius: 14,
        offset: const Offset(0, 5),
      );

  /// Hairline border used on cards.
  static Color get cardBorder => AppColors.border.withValues(alpha: 0.45);
}
