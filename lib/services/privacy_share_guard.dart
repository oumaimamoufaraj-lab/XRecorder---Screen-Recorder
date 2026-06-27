import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/privacy_scan_result.dart';
import '../services/privacy_scan_service.dart';
import '../services/privacy_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/privacy_status_badge.dart';
import '../models/privacy_video_state.dart';
import '../screens/privacy/privacy_studio_screen.dart';

/// Prompts users to review recordings for sensitive content before sharing.
abstract final class PrivacyShareGuard {
  PrivacyShareGuard._();

  static const checklistItems = [
    'Email addresses and phone numbers',
    'Names, usernames, and profile photos',
    'Account numbers, passwords, and messages',
    'Notifications and personal images',
  ];

  /// Returns `true` when the user confirms they want to share.
  static Future<bool> confirmBeforeShare(
    BuildContext context, {
    AssetEntity? video,
  }) async {
    PrivacyScanResult? scanResult;
    PrivacyVideoState? savedState;

    if (video != null) {
      savedState = await PrivacyStorageService.instance.load(video.id);
      if (savedState.lastScanScore != null) {
        scanResult = PrivacyScanResult(
          score: savedState.lastScanScore!,
          findings: savedState.lastScanFindings,
        );
      } else {
        scanResult = await PrivacyScanService.instance.scanVideo(video);
        await PrivacyStorageService.instance.save(
          savedState.copyWith(
            status: PrivacyClipStatus.scanned,
            lastScanScore: scanResult.score,
            lastScanFindings: scanResult.findings,
          ),
        );
      }
    }

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.privacyTeal),
            SizedBox(width: 10),
            Expanded(child: Text('Safe Share check')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (scanResult != null) ...[
                Row(
                  children: [
                    PrivacyScoreRing(score: scanResult.score),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Privacy Score',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(scanResult.scoreLabel),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (scanResult.findings.isNotEmpty)
                  ...scanResult.findings.take(4).map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• ${f.typeLabel}: ${f.label}'),
                        ),
                      ),
                if (scanResult.findings.isNotEmpty) const SizedBox(height: 8),
              ],
              const Text(
                'Review your video before sharing:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              for (final item in checklistItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: AppColors.primaryOrange.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              if (savedState?.hasSafeExport == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tip: Share your safe export from Privacy Studio for best protection.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.privacyTealDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (video != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrivacyStudioScreen(video: video),
                  ),
                );
              },
              child: const Text('Protect'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Share anyway'),
          ),
        ],
      ),
    );
    return result == true;
  }
}
