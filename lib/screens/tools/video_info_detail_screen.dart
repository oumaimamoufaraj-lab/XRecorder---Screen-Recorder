import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/video_info_details.dart';
import '../../services/photos_launcher_service.dart';
import '../../services/video_info_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/context_extensions.dart';
import '../videos/video_player_screen.dart';

class VideoInfoDetailScreen extends StatefulWidget {
  const VideoInfoDetailScreen({super.key, required this.video});

  final AssetEntity video;

  @override
  State<VideoInfoDetailScreen> createState() => _VideoInfoDetailScreenState();
}

class _VideoInfoDetailScreenState extends State<VideoInfoDetailScreen> {
  final VideoInfoService _infoService = VideoInfoService();
  final PhotosLauncherService _photosLauncher = PhotosLauncherService();
  VideoInfoDetails? _details;
  Uint8List? _thumbnail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final details = await _infoService.loadDetails(widget.video);
      final thumb = await widget.video.thumbnailDataWithSize(
        const ThumbnailSize(400, 225),
      );
      if (!mounted) return;
      setState(() {
        _details = details;
        _thumbnail = thumb;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load video details.';
      });
    }
  }

  Future<void> _play() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(video: widget.video),
      ),
    );
  }

  Future<void> _share() async {
    final file = await widget.video.file;
    if (!mounted) return;
    if (file == null) {
      _showSnack('Could not read video file for sharing.');
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'NowRecorder video'),
    );
  }

  Future<void> _openInPhotos() async {
    final opened = await _photosLauncher.openInPhotos(widget.video);
    if (!mounted) return;
    if (opened) {
      _showSnack('Opened Photos. Find your recording in Recents or Videos.');
    } else {
      _showSnack('Could not open Photos.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Info',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : details == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _thumbnail != null
                          ? Image.memory(_thumbnail!, fit: BoxFit.cover)
                          : Container(
                              color: palette.peachLight,
                              child: const Icon(
                                Icons.videocam_rounded,
                                size: 48,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    details.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    rows: [
                      _InfoRow(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: details.durationLabel,
                      ),
                      _InfoRow(
                        icon: Icons.sd_storage_outlined,
                        label: 'File size',
                        value: details.fileSizeLabel,
                      ),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created',
                        value: details.createdLabel,
                      ),
                      if (details.resolutionText != null)
                        _InfoRow(
                          icon: Icons.aspect_ratio_outlined,
                          label: 'Resolution',
                          value: details.resolutionText!,
                        ),
                      _InfoRow(
                        icon: Icons.movie_outlined,
                        label: 'Format',
                        value: details.formatText ?? 'Video',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.play_circle_outline,
                          label: 'Play',
                          color: AppColors.primaryOrange,
                          onPressed: _play,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onPressed: _share,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openInPhotos,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Open in Photos'),
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
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 52,
                color: palette.divider,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primaryOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color ?? palette.textPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
