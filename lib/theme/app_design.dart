import 'package:flutter/material.dart';

/// Layout and shape tokens for the Vault UI.
abstract final class AppDesign {
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 20);

  static const double bottomNavHeight = 72;
  static const double fabSize = 58;

  static TextStyle sectionLabel(Color color) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color,
      );

  static TextStyle displayTitle(Color color) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        height: 1.15,
        color: color,
      );

  static TextStyle subtitle(Color color) => TextStyle(
        fontSize: 14,
        height: 1.45,
        color: color,
      );

  static BoxDecoration heroCardDecoration({
    required List<Color> gradient,
    double radius = radiusLg,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient,
      ),
      boxShadow: [
        BoxShadow(
          color: gradient.last.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}
