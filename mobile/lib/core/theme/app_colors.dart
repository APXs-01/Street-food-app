import 'package:flutter/painting.dart';

/// Colour tokens from the StreetBite Figma file. Nothing outside this file
/// should contain a hex colour.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF006948);
  static const Color primaryLight = Color(0xFF85F8C4);

  /// Vendor sign-up CTA. Vendor screens use a slightly different green from
  /// the consumer screens on purpose, so keep the two apart.
  static const Color vendorAccent = Color(0xFF059669);

  /// Secondary green: the active bottom-nav pill, "Open now" and hygiene rings.
  static const Color secondary = Color(0xFF00855D);

  /// Caution amber: re-verification pending, low scores, live-activity pills.
  static const Color amber = Color(0xFFFE932C);
  static const Color amberBg = Color(0xFFFFF1E0);

  /// The lavender tile behind "View Stall Profile" on the vendor home.
  static const Color lavenderBg = Color(0xFFEDE9FE);
  static const Color lavender = Color(0xFF6D4FC7);

  /// "Coastline Active" dot on the map.
  static const Color skyBlue = Color(0xFF3B82F6);

  // The simulated map (there is no real map SDK yet)
  static const Color mapLand = Color(0xFFF1F4F2);
  static const Color mapBlock = Color(0xFFE1E7E3);
  static const Color mapPark = Color(0xFFCDE8D6);
  static const Color mapWater = Color(0xFFD3E8F5);
  static const Color mapWaterText = Color(0xFF6C93AD);

  // Vendor portal badges
  static const Color orangeAccentBg = Color(0xFFFFDCC3);
  static const Color orangeAccentText = Color(0xFF904D00);

  // Text
  static const Color textPrimary = Color(0xFF191C1E);
  static const Color textSecondary = Color(0xFF3D4A42);
  static const Color textMuted = Color(0xFF6D7A72);

  // Surfaces
  static const Color background = Color(0xFFF7F9FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFBCCAC0);
  static const Color borderLight = Color(0xFFE6E8EA);

  /// Unselected category chips, upload box and other quiet fills.
  static const Color surfaceMuted = Color(0xFFF2F4F6);

  /// Dark avatar behind the vendor role card icon.
  static const Color darkAvatar = Color(0xFF2D3133);

  // Feedback
  static const Color error = Color(0xFFBA1A1A);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);
  static const Color successText = Color(0xFF065F46);
}
