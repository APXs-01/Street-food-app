import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Plus Jakarta Sans throughout. These are getters, not constants, because
/// GoogleFonts builds each style on demand.
abstract final class AppTextStyles {
  static TextStyle _style(
    double size,
    FontWeight weight, {
    double? height,
    double? letterSpacing,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// 32 / 40, extra bold, tight tracking: screen headings.
  static TextStyle get display => _style(32, FontWeight.w800, height: 40 / 32, letterSpacing: -0.8);

  /// 28 bold: centred sign-up heading.
  static TextStyle get headline => _style(28, FontWeight.w700, height: 1.25, letterSpacing: -0.5);

  /// 18 bold: card and section titles.
  static TextStyle get title => _style(18, FontWeight.w700, height: 1.3);

  /// 14 medium on a 21px line: body copy.
  static TextStyle get body => _style(14, FontWeight.w500, height: 1.5, color: AppColors.textSecondary);

  static TextStyle get bodyStrong => _style(14, FontWeight.w700, height: 1.5);

  /// 13 bold: form field labels.
  static TextStyle get label => _style(13, FontWeight.w700, height: 1.3);

  /// 11 bold with tracking: badges and eyebrows. Pass uppercase text.
  static TextStyle get caption => _style(11, FontWeight.w700, height: 1.3, letterSpacing: 0.44);

  static TextStyle get button => _style(14, FontWeight.w700, height: 1.2, color: AppColors.surface);

  /// The green "StreetBite" wordmark in app bars.
  static TextStyle get wordmark => _style(22, FontWeight.w700, letterSpacing: -0.3, color: AppColors.primary);

  static TextStyle get input => _style(14, FontWeight.w500, color: AppColors.textPrimary);

  static TextStyle get hint => _style(14, FontWeight.w500, color: AppColors.textMuted.withValues(alpha: 0.7));

  static TextStyle get link => _style(13, FontWeight.w700, color: AppColors.primary);
}
