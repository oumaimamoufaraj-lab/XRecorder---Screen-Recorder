import 'package:flutter/material.dart';

import '../models/privacy_video_state.dart';
import '../theme/app_colors.dart';

class PrivacyStatusBadge extends StatelessWidget {
  const PrivacyStatusBadge({
    super.key,
    required this.state,
    this.compact = false,
  });

  final PrivacyVideoState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style(state);

    if (compact) {
      return Icon(icon, size: 16, color: color);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            state.statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _style(PrivacyVideoState state) {
    return switch (state.status) {
      PrivacyClipStatus.unreviewed => (
          AppColors.primaryOrange,
          Icons.shield_outlined,
        ),
      PrivacyClipStatus.scanned when state.lastScanScore != null && state.lastScanScore! < 85 =>
        (Colors.orange.shade800, Icons.warning_amber_rounded),
      PrivacyClipStatus.scanned => (AppColors.privacyTeal, Icons.check_circle_outline),
      PrivacyClipStatus.protected => (AppColors.privacyTeal, Icons.blur_on),
      PrivacyClipStatus.safeToShare => (AppColors.greenAccent, Icons.verified_user_outlined),
    };
  }
}

class PrivacyScoreRing extends StatelessWidget {
  const PrivacyScoreRing({
    super.key,
    required this.score,
    this.size = 56,
  });

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = score >= 85
        ? AppColors.greenAccent
        : score >= 60
        ? Colors.orange.shade700
        : Colors.red.shade600;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 4,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
          Text(
            '$score',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.28,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
