import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../config/build_features.dart';
import '../../config/recording_help_content.dart';
import '../../models/broadcast_audio_debug_report.dart';
import '../../services/ad_action_service.dart';
import '../../services/recording_service.dart';
import '../../services/replaykit_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/appearance_sheet.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/broadcast_stop_help_dialog.dart';
import '../../widgets/recording_help_dialog.dart';
import 'broadcast_audio_debug_panel.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, this.onRecordingSaved});

  final VoidCallback? onRecordingSaved;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with WidgetsBindingObserver {
  final RecordingService _recordingService = RecordingService();
  final ReplayKitService _replayKitService = ReplayKitService();
  bool _isRecording = false;
  bool _appOnlyRecording = false;
  bool _broadcastActive = false;
  bool _replayKitAvailable = false;
  bool _isSimulator = false;
  String _statusText = 'Ready to record';
  Timer? _broadcastStatusTimer;
  String _previousBroadcastStatus = 'idle';
  BroadcastAudioTestMode _broadcastAudioMode = BroadcastAudioTestMode.micOnly;

  bool get _showBroadcastDebugTools => BuildFeatures.showBroadcastAudioDebugTools;

  /// Release uses micOnly (confirmed working). Developer tools can override for testing.
  BroadcastAudioTestMode get _activeBroadcastAudioMode {
    if (_showBroadcastDebugTools) {
      return _broadcastAudioMode;
    }
    return BroadcastAudioTestMode.micOnly;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkRuntime();
    _startBroadcastStatusSync();
    if (Platform.isIOS) {
      unawaited(_applyBroadcastAudioModeToNative());
    }
  }

  Future<void> _applyBroadcastAudioModeToNative() async {
    await _replayKitService.setBroadcastAudioMode(_activeBroadcastAudioMode);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _broadcastStatusTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_importPendingRecordingOnResume());
      _syncBroadcastStatus();
    }
  }

  Future<void> _importPendingRecordingOnResume() async {
    final info = await _replayKitService.getBroadcastInfo();
    if (info.status != 'saved_to_container' &&
        info.status != 'saved' &&
        info.status != 'error') {
      return;
    }
    final imported = await _replayKitService.importPendingBroadcastRecording();
    if (!mounted) return;
    if (imported) {
      widget.onRecordingSaved?.call();
      await _replayKitService.setBroadcastStatus('idle');
    }
    if (_showBroadcastDebugTools) {
      await _showBroadcastAudioDebugReport();
    }
  }

  Future<void> _checkRuntime() async {
    if (!Platform.isIOS) return;
    final isSimulator = await _replayKitService.isSimulator();
    final available = await _replayKitService.isAvailable();
    if (!mounted) return;
    setState(() {
      _isSimulator = isSimulator;
      _replayKitAvailable = available && !isSimulator;
      if (isSimulator) {
        _statusText = 'Simulator — use a real iPhone';
      }
    });
  }

  void _startBroadcastStatusSync() {
    if (!Platform.isIOS) return;
    _broadcastStatusTimer?.cancel();
    _broadcastStatusTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncBroadcastStatus(),
    );
  }

  Future<void> _syncBroadcastStatus() async {
    if (!Platform.isIOS) return;
    final info = await _replayKitService.getBroadcastInfo();
    if (!mounted) return;

    var isRecording = _appOnlyRecording;
    var broadcastActive = info.isBroadcastActive;
    var text = _statusText;

    switch (info.status) {
      case 'recording':
        isRecording = true;
        broadcastActive = true;
        text = 'Broadcast recording…';
        break;
      case 'paused':
        isRecording = true;
        broadcastActive = true;
        text = 'Broadcast paused';
        break;
      case 'saving':
        isRecording = true;
        broadcastActive = true;
        text = 'Saving recording…';
        break;
      case 'requested':
        isRecording = false;
        broadcastActive = true;
        text = 'Confirm broadcast in Apple’s picker';
        break;
      case 'saved':
      case 'saved_to_container':
        isRecording = false;
        broadcastActive = false;
        text = 'Saved to Photos';
        if (_previousBroadcastStatus != 'saved' &&
            _previousBroadcastStatus != 'saved_to_container') {
          await _handleRecordingSaved();
        }
        break;
      case 'error':
        isRecording = false;
        broadcastActive = false;
        text = info.lastError ?? 'Recording failed';
        if (_showBroadcastDebugTools && _previousBroadcastStatus != 'error') {
          unawaited(_showBroadcastAudioDebugReport());
        }
        break;
      case 'stopped':
        isRecording = false;
        broadcastActive = false;
        text = 'Broadcast stopped';
        break;
      default:
        if (_appOnlyRecording) {
          isRecording = true;
          text = 'Recording in-app only…';
        } else if (!broadcastActive) {
          text = 'Ready to record';
        }
    }

    if (info.shouldRefreshVideos) {
      final consumed = await _replayKitService.consumeVideosRefreshFlag();
      if (consumed && mounted) {
        widget.onRecordingSaved?.call();
      }
    }

    _previousBroadcastStatus = info.status;

    if (isRecording != _isRecording ||
        broadcastActive != _broadcastActive ||
        text != _statusText) {
      setState(() {
        _isRecording = isRecording;
        _broadcastActive = broadcastActive;
        _statusText = text;
      });
    }
  }

  Future<void> _handleRecordingSaved() async {
    if (!mounted) return;

    final imported = await _replayKitService.importPendingBroadcastRecording();
    if (!mounted) return;

    if (imported) {
      widget.onRecordingSaved?.call();
      await _replayKitService.consumeVideosRefreshFlag();
      await _replayKitService.setBroadcastStatus('idle');
    }

    if (!mounted) return;
    if (_showBroadcastDebugTools) {
      await _showBroadcastAudioDebugReport();
    }

    if (!mounted) return;
    if (imported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording saved to Photos. Check the Videos tab.')),
      );
    }
  }

  Future<void> _showBroadcastAudioDebugReport() async {
    if (!_showBroadcastDebugTools || !Platform.isIOS || !mounted) return;
    final report = await _replayKitService.getBroadcastAudioDebugReport();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Broadcast audio debug'),
        content: SingleChildScrollView(
          child: SelectableText(
            '${report.summaryText}\nDiagnosis: ${report.diagnosisHint}',
            style: const TextStyle(fontFamily: 'Menlo', fontSize: 12, height: 1.35),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _onBroadcastAudioModeChanged(BroadcastAudioTestMode mode) async {
    setState(() => _broadcastAudioMode = mode);
    await _replayKitService.setBroadcastAudioMode(mode);
  }

  Future<void> _showRecordingHelp() async {
    await showRecordingHelpDialog(context, isSimulator: _isSimulator);
  }

  Future<void> _showAppSettingsPrompt() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Please allow Photos access to save recordings. You can enable it from app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                PhotoManager.openSetting();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBroadcastStopHelp() async {
    await showBroadcastStopHelpDialog(context);
  }

  Future<void> _startFullDeviceRecording() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full-screen recording'),
        content: const Text(
          'iOS will ask you to confirm screen broadcast.\n\n'
          '1. Tap Continue to open Apple’s broadcast menu.\n'
          '2. Turn Microphone ON (required for audio).\n'
          '3. Select XRecorder in the list.\n'
          '4. Tap Start Broadcast.\n'
          '5. Stop from the red status bar or Control Center.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              await _replayKitService.setBroadcastAudioMode(_activeBroadcastAudioMode);
              final result = await _recordingService.startFullDeviceRecording();
              if (!mounted) return;
              if (result.success) {
                setState(() => _statusText = 'Confirm broadcast in Apple’s picker');
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(result.error ?? 'Could not open broadcast picker.')),
                );
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (Platform.isIOS) {
      final isSimulator = await _replayKitService.isSimulator();
      if (!mounted) return;
      if (isSimulator) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Screen recording requires a physical iPhone. It does not work in the iOS Simulator.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      if (_broadcastActive || (_isRecording && !_appOnlyRecording)) {
        await _showBroadcastStopHelp();
        return;
      }

      if (_appOnlyRecording) {
        final result = await _recordingService.stopAppOnlyRecording();
        if (!mounted) return;
        if (result.success) {
          setState(() {
            _appOnlyRecording = false;
            _isRecording = false;
            _statusText = 'Saved to Photos';
          });
          widget.onRecordingSaved?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('In-app recording saved to Photos.')),
          );
        } else {
          setState(() {
            _appOnlyRecording = false;
            _isRecording = false;
            _statusText = 'Ready to record';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Failed to stop recording.')),
          );
        }
        return;
      }

      final hasAccess = await _recordingService.requestMediaPermissions();
      if (!mounted) return;
      if (!hasAccess) {
        await _showAppSettingsPrompt();
        return;
      }

      await _startFullDeviceRecording();
      return;
    }

    if (_isRecording) {
      final result = await _recordingService.stop();
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _isRecording = false;
          _statusText = 'Saved to Photos';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording saved to Photos.')),
        );
      } else {
        setState(() {
          _isRecording = false;
          _statusText = 'Ready to record';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Failed to stop recording.')),
        );
      }
      return;
    }

    final hasAccess = await _recordingService.requestMediaPermissions();
    if (!mounted) return;
    if (!hasAccess) {
      await _showAppSettingsPrompt();
      return;
    }

    final result = await _recordingService.start();
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _isRecording = true;
        _statusText = 'Recording...';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not start recording.')),
      );
    }
  }

  Future<void> _startAppOnlyRecording() async {
    final isSimulator = await _replayKitService.isSimulator();
    if (!mounted) return;
    if (isSimulator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('In-app recording requires a physical iPhone.'),
        ),
      );
      return;
    }

    if (_broadcastActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stop the broadcast before starting in-app recording.'),
        ),
      );
      return;
    }

    final hasAccess = await _recordingService.requestMediaPermissions();
    if (!mounted) return;
    if (!hasAccess) {
      await _showAppSettingsPrompt();
      return;
    }

    final result = await _recordingService.startAppOnlyRecording();
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _appOnlyRecording = true;
        _isRecording = true;
        _statusText = 'Recording in-app only…';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not start in-app recording.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            if (_isSimulator) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.simulatorBannerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.phone_iphone, color: AppColors.primaryOrange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Screen recording does not work in the iOS Simulator. '
                        'Connect a physical iPhone and run: flutter run',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: palette.logoBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const BrandLogo(size: 34, radius: 10, withShadow: false),
                ),
                const Spacer(),
                _RecordHeaderIconButton(
                  icon: Icons.palette_outlined,
                  tooltip: 'Appearance',
                  onPressed: () => showAppearanceSheet(context),
                ),
                const SizedBox(width: 6),
                _RecordHeaderIconButton(
                  icon: Icons.info_outline,
                  tooltip: 'Help',
                  onPressed: () =>
                      AdActionService.runWithInterstitial(_showRecordingHelp),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Screen Recording',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: palette.textSecondary.withValues(alpha: 0.9),
              ),
            ),
            if (Platform.isIOS) ...[
              const SizedBox(height: 8),
              Center(
                child: _BroadcastStatusChip(
                  statusText: _statusText,
                  isRecording: _isRecording,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: palette.cardShadow,
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const BrandLogo(size: 90, radius: 22),
                  const SizedBox(height: 20),
                  Text(
                    _isRecording ? 'Recording in progress' : 'Ready to record',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Platform.isIOS
                        ? (_broadcastActive
                            ? 'Stop via the red status bar or Control Center'
                            : _appOnlyRecording
                            ? 'Tap Stop to save this in-app session'
                            : 'Tap Start — turn Microphone ON in Apple’s broadcast sheet')
                        : _isRecording
                        ? 'Tap stop to finish and save video'
                        : 'Tap the button below to start',
                    style: TextStyle(
                      fontSize: 14,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (Platform.isIOS && _broadcastActive) ...[
              const SizedBox(height: 16),
              BroadcastActiveBanner(
                onHowToStop: () => AdActionService.runWithInterstitial(
                  _showBroadcastStopHelp,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_replayKitAvailable) ...[
              if (_showBroadcastDebugTools) ...[
                BroadcastAudioDebugPanel(
                  selectedMode: _broadcastAudioMode,
                  enabled: !_broadcastActive && !_appOnlyRecording,
                  onModeChanged: _onBroadcastAudioModeChanged,
                  onViewReport: () => unawaited(_showBroadcastAudioDebugReport()),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_broadcastActive || _appOnlyRecording)
                      ? null
                      : () => AdActionService.runWithRewardedAsync(
                          _startAppOnlyRecording,
                        ),
                  icon: const Icon(Icons.smartphone_rounded),
                  label: const Text('Record app only (optional)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                    side: BorderSide(
                      color: AppColors.primaryOrange.withValues(alpha: 0.45),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSimulator
                    ? null
                    : () {
                        if (_broadcastActive ||
                            (_isRecording && !_appOnlyRecording)) {
                          AdActionService.runWithInterstitial(
                            _showBroadcastStopHelp,
                          );
                        } else {
                          AdActionService.runWithRewardedAsync(
                            _toggleRecording,
                          );
                        }
                      },
                icon: Icon(
                  Platform.isIOS && _broadcastActive
                      ? Icons.stop_circle_outlined
                      : _isRecording
                      ? Icons.stop_rounded
                      : Icons.fiber_manual_record,
                  size: 22,
                ),
                label: Text(
                  Platform.isIOS && _broadcastActive
                      ? 'How to Stop Recording'
                      : _isRecording
                      ? 'Stop Recording'
                      : 'Start Recording',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Platform.isIOS && _broadcastActive
                      ? Colors.redAccent
                      : _isRecording
                      ? Colors.red
                      : AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _InfoCard(
              icon: Icons.touch_app_outlined,
              iconBgColor: palette.orangeTint,
              iconColor: AppColors.primaryOrange,
              title: 'How to Start',
              description: Platform.isIOS
                  ? RecordingHelpContent.iosHowToStart
                  : "Tap Start Recording to begin and Stop Recording to save the video.",
            ),
            const SizedBox(height: 12),
            if (Platform.isIOS)
              _InfoCard(
                icon: Icons.stop_circle_outlined,
                iconBgColor: const Color(0xFFFFEBEE),
                iconColor: Colors.redAccent,
                title: 'How to Stop',
                description: RecordingHelpContent.iosHowToStop,
              ),
            if (Platform.isIOS) const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.save_outlined,
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: AppColors.greenAccent,
              title: 'Auto Save',
              description:
                  'Finished recordings are saved to Photos and appear in the Videos tab',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _BroadcastStatusChip extends StatefulWidget {
  const _BroadcastStatusChip({
    required this.statusText,
    required this.isRecording,
  });

  final String statusText;
  final bool isRecording;

  @override
  State<_BroadcastStatusChip> createState() => _BroadcastStatusChipState();
}

class _BroadcastStatusChipState extends State<_BroadcastStatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.10, end: 0.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _BroadcastStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.isRecording || widget.statusText == 'Recording...') {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Color dotColor = Colors.grey;

    if (widget.statusText == 'Broadcast paused') {
      dotColor = Colors.orange;
    } else if (widget.isRecording || widget.statusText == 'Recording...') {
      dotColor = Colors.green;
    } else if (widget.statusText == 'Select XRecorder in Broadcast Picker') {
      dotColor = AppColors.primaryOrange;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final isActive = widget.isRecording || widget.statusText == 'Recording...';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dotColor.withValues(alpha: 0.5)),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: dotColor.withValues(alpha: _glowOpacity.value),
                      blurRadius: 10,
                      spreadRadius: 1.5,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                alignment: Alignment.center,
                child: ScaleTransition(
                  scale: _pulseScale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordHeaderIconButton extends StatelessWidget {
  const _RecordHeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.card,
        shape: const CircleBorder(),
        elevation: 0,
        shadowColor: palette.cardShadow,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 20, color: palette.textPrimary),
          ),
        ),
      ),
    );
  }
}
