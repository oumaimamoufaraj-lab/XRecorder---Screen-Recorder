import 'package:flutter/material.dart';

import '../controllers/recording_status_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_design.dart';

/// Persistent banner shown at the top of the app while recording is active.
class GlobalRecordingIndicator extends StatefulWidget {
  const GlobalRecordingIndicator({
    super.key,
    required this.controller,
  });

  final RecordingStatusController controller;

  @override
  State<GlobalRecordingIndicator> createState() =>
      _GlobalRecordingIndicatorState();
}

class _GlobalRecordingIndicatorState extends State<GlobalRecordingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _label(RecordingStatusController status) {
    if (status.statusLabel.isNotEmpty) return status.statusLabel;
    if (status.appOnlyRecording) return 'Recording in-app…';
    if (status.broadcastActive) return 'Broadcast recording…';
    return 'Recording…';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final status = widget.controller;
        if (!status.isActive) return const SizedBox.shrink();

        final topPadding = MediaQuery.paddingOf(context).top;
        final label = _label(status);

        return Positioned(
          top: topPadding + 8,
          left: 12,
          right: 12,
          child: IgnorePointer(
            child: Material(
            elevation: 8,
            shadowColor: AppColors.recordRed.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.recordRed,
                    AppColors.recordRedGlow.withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  FadeTransition(
                    opacity: _pulseAnimation,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppDesign.radiusXs),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (status.broadcastActive)
                    Icon(
                      Icons.cast_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    )
                  else if (status.appOnlyRecording)
                    Icon(
                      Icons.smartphone_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    )
                  else
                    Icon(
                      Icons.fiber_manual_record_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}
