import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../models/blur_region.dart';
import '../../models/privacy_scan_result.dart';
import '../../models/privacy_video_state.dart';
import '../../services/privacy_scan_service.dart';
import '../../services/privacy_storage_service.dart';
import '../../services/safe_export_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/blur_region_overlay.dart';
import '../../widgets/privacy_status_badge.dart';

class PrivacyStudioScreen extends StatefulWidget {
  const PrivacyStudioScreen({super.key, required this.video});

  final AssetEntity video;

  @override
  State<PrivacyStudioScreen> createState() => _PrivacyStudioScreenState();
}

class _PrivacyStudioScreenState extends State<PrivacyStudioScreen> {
  final _storage = PrivacyStorageService.instance;
  final _scanner = PrivacyScanService.instance;
  final _exporter = SafeExportService.instance;

  VideoPlayerController? _controller;
  List<BlurRegion> _regions = [];
  String? _selectedId;
  PrivacyScanResult? _scanResult;
  PrivacyVideoState? _state;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  File? _lastSafeExport;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final file = await widget.video.file;
      if (file == null || !file.existsSync()) {
        setState(() {
          _error = 'Video file could not be loaded.';
          _loading = false;
        });
        return;
      }

      final saved = await _storage.load(widget.video.id);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _regions = List<BlurRegion>.from(saved.blurRegions);
        _scanResult = saved.lastScanScore != null
            ? PrivacyScanResult(
                score: saved.lastScanScore!,
                findings: saved.lastScanFindings,
              )
            : null;
        _state = saved;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _persistState({
    PrivacyClipStatus? status,
    bool? hasSafeExport,
  }) async {
    final current = _state ?? PrivacyVideoState.unreviewed(widget.video.id);
    final next = current.copyWith(
      blurRegions: _regions,
      status: status ?? current.status,
      lastScanScore: _scanResult?.score,
      lastScanFindings: _scanResult?.findings ?? current.lastScanFindings,
      hasSafeExport: hasSafeExport ?? current.hasSafeExport,
    );
    await _storage.save(next);
    if (mounted) setState(() => _state = next);
  }

  void _addRegionAt(Offset normalized) {
    const defaultW = 0.35;
    const defaultH = 0.12;
    var left = (normalized.dx - defaultW / 2).clamp(0.0, 1.0 - defaultW);
    var top = (normalized.dy - defaultH / 2).clamp(0.0, 1.0 - defaultH);
    final id = const Uuid().v4();
    setState(() {
      _regions = [
        ..._regions,
        BlurRegion(
          id: id,
          left: left,
          top: top,
          width: defaultW,
          height: defaultH,
        ),
      ];
      _selectedId = id;
    });
    unawaited(_persistState(status: PrivacyClipStatus.protected));
  }

  void _moveRegion(String id, Offset delta) {
    setState(() {
      _regions = _regions.map((region) {
        if (region.id != id) return region;
        final left = (region.left + delta.dx).clamp(0.0, 1.0 - region.width);
        final top = (region.top + delta.dy).clamp(0.0, 1.0 - region.height);
        return region.copyWith(left: left, top: top);
      }).toList();
    });
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    setState(() {
      _regions = _regions.where((r) => r.id != _selectedId).toList();
      _selectedId = null;
    });
    unawaited(_persistState());
  }

  Future<void> _runScan() async {
    setState(() => _busy = true);
    try {
      final result = await _scanner.scanVideo(widget.video);
      if (!mounted) return;
      setState(() => _scanResult = result);
      await _persistState(status: PrivacyClipStatus.scanned);
      if (!mounted) return;
      _showScanSheet(result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportSafeCopy() async {
    if (_regions.isEmpty) {
      _showSnack('Add at least one blur region first.');
      return;
    }

    final file = await widget.video.file;
    final controller = _controller;
    if (file == null || controller == null || !controller.value.isInitialized) {
      _showSnack('Video not ready for export.');
      return;
    }

    setState(() => _busy = true);
    try {
      final size = controller.value.size;
      final exported = await _exporter.exportRedactedCopy(
        sourceFile: file,
        regions: _regions,
        videoWidth: size.width.round(),
        videoHeight: size.height.round(),
      );
      if (!mounted) return;
      if (exported == null) {
        _showSnack('Export failed. Try fewer or smaller blur regions.');
        return;
      }

      final saved = await _exporter.saveToPhotos(
        exported,
        title: 'Safe ${widget.video.title ?? 'Recording'}',
      );
      if (!mounted) return;

      setState(() => _lastSafeExport = exported);
      await _persistState(
        status: PrivacyClipStatus.safeToShare,
        hasSafeExport: true,
      );

      _showSnack(
        saved
            ? 'Safe copy saved to Photos.'
            : 'Export created but could not save to Photos.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareSafeCopy() async {
    final file = _lastSafeExport;
    if (file == null || !file.existsSync()) {
      _showSnack('Export a safe copy first.');
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Safe recording'),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showScanSheet(PrivacyScanResult result) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.privacySurface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PrivacyScoreRing(score: result.score),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Privacy Score',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          result.scoreLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (result.findings.isEmpty)
                Text(
                  'No emails or phone numbers detected in sampled frames.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                )
              else
                ...result.findings.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          f.type == PrivacyFindingType.email
                              ? Icons.email_outlined
                              : Icons.phone_outlined,
                          size: 18,
                          color: AppColors.privacyTeal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${f.typeLabel}: ${f.label}\n${f.timeLabel}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.privacyTeal,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.privacyNavy,
      appBar: AppBar(
        backgroundColor: AppColors.privacyNavy,
        foregroundColor: Colors.white,
        title: const Text('Privacy Studio'),
        actions: [
          if (_state != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: PrivacyStatusBadge(state: _state!)),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.privacyTeal),
            )
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white70)),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPlayer(_controller!),
                          BlurRegionOverlay(
                            regions: _regions,
                            selectedId: _selectedId,
                            onRegionTap: (id) => setState(() => _selectedId = id),
                            onRegionDrag: _moveRegion,
                            onBackgroundTap: _addRegionAt,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_scanResult != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        PrivacyScoreRing(score: _scanResult!.score, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _scanResult!.scoreLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _busy ? null : _runScan,
                          child: const Text('Rescan'),
                        ),
                      ],
                    ),
                  ),
                _StudioToolbar(
                  busy: _busy,
                  hasSelection: _selectedId != null,
                  regionCount: _regions.length,
                  onScan: _runScan,
                  onDelete: _deleteSelected,
                  onExport: _exportSafeCopy,
                  onShare: _shareSafeCopy,
                  onPlayPause: () {
                    final c = _controller!;
                    c.value.isPlaying ? c.pause() : c.play();
                    setState(() {});
                  },
                  isPlaying: _controller!.value.isPlaying,
                ),
              ],
            ),
    );
  }
}

class _StudioToolbar extends StatelessWidget {
  const _StudioToolbar({
    required this.busy,
    required this.hasSelection,
    required this.regionCount,
    required this.onScan,
    required this.onDelete,
    required this.onExport,
    required this.onShare,
    required this.onPlayPause,
    required this.isPlaying,
  });

  final bool busy;
  final bool hasSelection;
  final int regionCount;
  final VoidCallback onScan;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final VoidCallback onShare;
  final VoidCallback onPlayPause;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      decoration: const BoxDecoration(
        color: AppColors.privacySurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap video to add blur · Drag to move · $regionCount region${regionCount == 1 ? '' : 's'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ToolChip(
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                label: isPlaying ? 'Pause' : 'Play',
                onTap: busy ? null : onPlayPause,
              ),
              _ToolChip(
                icon: Icons.document_scanner_outlined,
                label: busy ? 'Scanning…' : 'Scan',
                onTap: busy ? null : onScan,
              ),
              _ToolChip(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: busy || !hasSelection ? null : onDelete,
              ),
              _ToolChip(
                icon: Icons.blur_on,
                label: 'Safe export',
                highlighted: true,
                onTap: busy ? null : onExport,
              ),
              _ToolChip(
                icon: Icons.ios_share,
                label: 'Share safe',
                onTap: busy ? null : onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bg = highlighted
        ? AppColors.privacyTeal
        : (isLight ? Colors.white : Colors.white.withValues(alpha: 0.08));

    final fg = highlighted
        ? Colors.white
        : isLight
        ? (enabled ? AppColors.textPrimary : AppColors.textMuted)
        : Colors.white.withValues(alpha: enabled ? 0.95 : 0.4);

    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18, color: fg),
      label: Text(label),
      backgroundColor: bg,
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
      side: BorderSide(
        color: isLight
            ? AppColors.indicatorInactive.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.08),
      ),
    );
  }
}
