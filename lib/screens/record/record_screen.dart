import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../config/build_features.dart';
import '../../models/broadcast_audio_debug_report.dart';
import '../../models/recording_preset.dart';
import '../../services/recording_service.dart';
import '../../services/replaykit_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/appearance_sheet.dart';
import '../../widgets/vault_screen_header.dart';
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
  RecordingPreset _preset = RecordingPreset.standard;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recording saved. ${_preset.hint}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
          '3. Select NowRecorder in the list.\n'
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
    final isActive = _isRecording || _broadcastActive;

    return Column(
      children: [
        VaultScreenHeader(
          title: 'Capture',
          subtitle: _preset.hint,
          trailing: [
            VaultIconAction(
              icon: Icons.palette_outlined,
              tooltip: 'Appearance',
              onPressed: () => showAppearanceSheet(context),
            ),
            const SizedBox(width: 6),
            VaultIconAction(
              icon: Icons.help_outline,
              tooltip: 'Help',
              onPressed: _showRecordingHelp,
            ),
          ],
        ),
        if (_isSimulator)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.simulatorBannerBg,
                borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Simulator detected — use a physical iPhone to record.',
                style: TextStyle(fontSize: 13, color: palette.textPrimary),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RecordingPreset.values.map((preset) {
              final selected = _preset == preset;
              return FilterChip(
                selected: selected,
                showCheckmark: false,
                avatar: Icon(
                  preset.icon,
                  size: 16,
                  color: selected ? Colors.white : palette.accent,
                ),
                label: Text(preset.label),
                selectedColor: palette.accent,
                backgroundColor: palette.elevated,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _preset = preset),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: Center(
            child: _CaptureStatusRing(
              isActive: isActive,
              isRecording: _isRecording,
              statusText: _statusText,
              broadcastActive: _broadcastActive,
            ),
          ),
        ),
        if (Platform.isIOS && _broadcastActive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BroadcastActiveBanner(
              onHowToStop: _showBroadcastStopHelp,
            ),
          ),
        if (_showBroadcastDebugTools && _replayKitAvailable) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BroadcastAudioDebugPanel(
              selectedMode: _broadcastAudioMode,
              enabled: !_broadcastActive && !_appOnlyRecording,
              onModeChanged: _onBroadcastAudioModeChanged,
              onViewReport: () => unawaited(_showBroadcastAudioDebugReport()),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDesign.radiusLg),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.cardShadow,
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _statusText,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Platform.isIOS
                    ? (_broadcastActive
                        ? 'Stop via Control Center or status bar'
                        : 'Mic: enable in Apple\'s broadcast sheet')
                    : 'Tap the button to start or stop',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_replayKitAvailable)
                    _DockIcon(
                      icon: Icons.smartphone_rounded,
                      label: 'In-app',
                      enabled: !_broadcastActive && !_appOnlyRecording,
                      onTap: (_broadcastActive || _appOnlyRecording)
                          ? null
                          : () => unawaited(_startAppOnlyRecording()),
                    ),
                  const SizedBox(width: 28),
                  _CaptureMainButton(
                    isSimulator: _isSimulator,
                    isRecording: _isRecording,
                    broadcastActive: _broadcastActive,
                    appOnlyRecording: _appOnlyRecording,
                    onTap: () {
                      if (_broadcastActive ||
                          (_isRecording && !_appOnlyRecording)) {
                        _showBroadcastStopHelp();
                      } else {
                        _toggleRecording();
                      }
                    },
                  ),
                  const SizedBox(width: 28),
                  _DockIcon(
                    icon: Icons.lightbulb_outline,
                    label: 'Tips',
                    onTap: _showRecordingHelp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CaptureStatusRing extends StatelessWidget {
  const _CaptureStatusRing({
    required this.isActive,
    required this.isRecording,
    required this.statusText,
    required this.broadcastActive,
  });

  final bool isActive;
  final bool isRecording;
  final String statusText;
  final bool broadcastActive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ringColor = isActive ? AppColors.recordRed : palette.accent;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ringColor.withValues(alpha: isActive ? 0.5 : 0.2),
                width: 3,
              ),
            ),
          ),
          if (isActive)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ringColor.withValues(alpha: 0.08),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                broadcastActive
                    ? Icons.sensors
                    : isRecording
                    ? Icons.stop_rounded
                    : Icons.videocam_outlined,
                size: 48,
                color: ringColor,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  isActive ? 'LIVE' : 'STANDBY',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _BroadcastStatusChip(
                statusText: statusText,
                isRecording: isRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaptureMainButton extends StatelessWidget {
  const _CaptureMainButton({
    required this.isSimulator,
    required this.isRecording,
    required this.broadcastActive,
    required this.appOnlyRecording,
    required this.onTap,
  });

  final bool isSimulator;
  final bool isRecording;
  final bool broadcastActive;
  final bool appOnlyRecording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = broadcastActive
        ? AppColors.recordRedGlow
        : isRecording
        ? AppColors.recordRed
        : AppColors.primaryOrange;

    return Material(
      color: color,
      elevation: 8,
      shadowColor: color.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: isSimulator ? null : onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Icon(
            broadcastActive
                ? Icons.help_outline
                : isRecording
                ? Icons.stop
                : Icons.fiber_manual_record,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Column(
        children: [
          IconButton.filledTonal(
            onPressed: enabled ? onTap : null,
            icon: Icon(icon),
            style: IconButton.styleFrom(
              backgroundColor: palette.elevated,
              foregroundColor: palette.accent,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: palette.textSecondary),
          ),
        ],
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
    } else if (widget.statusText == 'Select NowRecorder in Broadcast Picker') {
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
