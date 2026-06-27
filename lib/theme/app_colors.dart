import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color splashOrange = Color(0xFFFF5722);
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryOrangeLight = Color(0xFFFF7043);

  /// Aliases used by the Vault UI — mapped to orange brand.
  static const Color brandIndigo = primaryOrange;
  static const Color brandIndigoDark = splashOrange;
  static const Color brandMint = primaryOrangeLight;
  static const Color brandMintDark = Color(0xFFE64A19);

  static const Color vaultBg = Color(0xFFF8F9FA);
  static const Color vaultBgDark = Color(0xFF121212);
  static const Color vaultSurface = Color(0xFFFFFFFF);
  static const Color vaultSurfaceDark = Color(0xFF1E1E1E);
  static const Color vaultElevated = Color(0xFFFFF3EE);
  static const Color vaultElevatedDark = Color(0xFF2C221D);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFF2F2F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textSecondaryDark = Color(0xFFAEAEB2);
  static const Color textMuted = Color(0xFF9E9E9E);

  static const Color peachLight = Color(0xFFFFE8DE);
  static const Color orangeTint = Color(0xFFFFF3EE);

  static const Color privacyNavy = Color(0xFF1A1A1A);
  static const Color privacySurface = Color(0xFF2C2C2E);
  static const Color privacyTeal = primaryOrange;
  static const Color privacyTealDark = splashOrange;

  static const Color teal = Color(0xFF4DB6AC);
  static const Color tealDark = Color(0xFF26A69A);
  static const Color purple = Color(0xFF9B59B6);
  static const Color purpleDark = Color(0xFF8E44AD);
  static const Color linkBlue = Color(0xFF007AFF);
  static const Color greenAccent = Color(0xFF4CAF50);
  static const Color recordRed = Color(0xFFFF5722);
  static const Color recordRedGlow = Color(0xFFFF7043);

  static const Color cardWhite = vaultSurface;
  static const Color background = vaultBg;
  static const Color indicatorInactive = Color(0xFFD1D1D6);
  static const Color aiRed = Color(0xFFE8503A);
  static const Color aiRedDark = Color(0xFFD84315);
}
