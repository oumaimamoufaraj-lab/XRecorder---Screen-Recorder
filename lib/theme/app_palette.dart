import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.peachLight,
    required this.orangeTint,
    required this.indicatorInactive,
    required this.logoBackground,
    required this.divider,
    required this.cardShadow,
    required this.simulatorBannerBg,
    required this.bottomNavBackground,
  });

  final Color background;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color peachLight;
  final Color orangeTint;
  final Color indicatorInactive;
  final Color logoBackground;
  final Color divider;
  final Color cardShadow;
  final Color simulatorBannerBg;
  final Color bottomNavBackground;

  static const light = AppPalette(
    background: AppColors.background,
    card: AppColors.cardWhite,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    peachLight: AppColors.peachLight,
    orangeTint: AppColors.orangeTint,
    indicatorInactive: AppColors.indicatorInactive,
    logoBackground: Colors.white,
    divider: Color(0x1F8E8E93),
    cardShadow: Color(0x0A000000),
    simulatorBannerBg: Color(0xFFFFF3E0),
    bottomNavBackground: Colors.white,
  );

  static const dark = AppPalette(
    background: Color(0xFF121212),
    card: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFFAEAEB2),
    textMuted: Color(0xFF8E8E93),
    peachLight: Color(0xFF3A2A24),
    orangeTint: Color(0xFF2C221D),
    indicatorInactive: Color(0xFF48484A),
    logoBackground: Color(0xFF2C2C2E),
    divider: Color(0xFF38383A),
    cardShadow: Color(0x66000000),
    simulatorBannerBg: Color(0xFF3D3020),
    bottomNavBackground: Color(0xFF1C1C1E),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? peachLight,
    Color? orangeTint,
    Color? indicatorInactive,
    Color? logoBackground,
    Color? divider,
    Color? cardShadow,
    Color? simulatorBannerBg,
    Color? bottomNavBackground,
  }) {
    return AppPalette(
      background: background ?? this.background,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      peachLight: peachLight ?? this.peachLight,
      orangeTint: orangeTint ?? this.orangeTint,
      indicatorInactive: indicatorInactive ?? this.indicatorInactive,
      logoBackground: logoBackground ?? this.logoBackground,
      divider: divider ?? this.divider,
      cardShadow: cardShadow ?? this.cardShadow,
      simulatorBannerBg: simulatorBannerBg ?? this.simulatorBannerBg,
      bottomNavBackground: bottomNavBackground ?? this.bottomNavBackground,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      peachLight: Color.lerp(peachLight, other.peachLight, t)!,
      orangeTint: Color.lerp(orangeTint, other.orangeTint, t)!,
      indicatorInactive: Color.lerp(indicatorInactive, other.indicatorInactive, t)!,
      logoBackground: Color.lerp(logoBackground, other.logoBackground, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      simulatorBannerBg: Color.lerp(simulatorBannerBg, other.simulatorBannerBg, t)!,
      bottomNavBackground: Color.lerp(bottomNavBackground, other.bottomNavBackground, t)!,
    );
  }
}
