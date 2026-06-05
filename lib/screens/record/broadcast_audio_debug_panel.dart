import 'package:flutter/material.dart';

import '../../models/broadcast_audio_debug_report.dart';
import '../../theme/app_colors.dart';

class BroadcastAudioDebugPanel extends StatelessWidget {
  const BroadcastAudioDebugPanel({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    required this.onViewReport,
    this.enabled = true,
  });

  final BroadcastAudioTestMode selectedMode;
  final ValueChanged<BroadcastAudioTestMode> onModeChanged;
  final VoidCallback onViewReport;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report_outlined, size: 18, color: AppColors.primaryOrange),
              const SizedBox(width: 8),
              const Text(
                'Broadcast audio (developer)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<BroadcastAudioTestMode>(
            segments: const [
              ButtonSegment(
                value: BroadcastAudioTestMode.appAudioOnly,
                label: Text('appAudioOnly'),
                icon: Icon(Icons.volume_up_outlined, size: 18),
              ),
              ButtonSegment(
                value: BroadcastAudioTestMode.micOnly,
                label: Text('micOnly'),
                icon: Icon(Icons.mic_outlined, size: 18),
              ),
            ],
            selected: {selectedMode},
            onSelectionChanged: enabled
                ? (selected) => onModeChanged(selected.first)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            selectedMode == BroadcastAudioTestMode.appAudioOnly
                ? 'Test: Microphone OFF in Apple’s broadcast sheet; play sound from another app.'
                : 'Test: Microphone ON in Apple’s broadcast sheet.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onViewReport,
            child: const Text('View last broadcast audio debug report'),
          ),
        ],
      ),
    );
  }
}
