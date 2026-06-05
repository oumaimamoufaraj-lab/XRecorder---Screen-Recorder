import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/context_extensions.dart';

/// Instructions for stopping an active ReplayKit broadcast (no programmatic stop on iOS).
Future<void> showBroadcastStopHelpDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final palette = context.palette;
      return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.stop_circle_rounded,
                color: Colors.redAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How to stop recording',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Full-screen broadcast is controlled by iOS. XRecorder cannot stop it from inside the app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: palette.textSecondary.withValues(alpha: 0.95),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            const _StopStep(
              number: '1',
              text: 'Tap the red status bar or red recording indicator at the top of your screen.',
            ),
            const SizedBox(height: 10),
            const _StopStep(
              number: '2',
              text: 'Or open Control Center and tap Stop on Screen Broadcast.',
            ),
            const SizedBox(height: 10),
            const _StopStep(
              number: '3',
              text: 'Reopen XRecorder so your recording can import and save to Photos.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
    },
  );
}

class BroadcastActiveBanner extends StatelessWidget {
  const BroadcastActiveBanner({super.key, required this.onHowToStop});

  final VoidCallback onHowToStop;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onHowToStop,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Broadcast recording active',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap here for how to stop and save your video',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textSecondary.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopStep extends StatelessWidget {
  const _StopStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: palette.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
