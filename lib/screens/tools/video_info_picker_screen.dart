import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../services/video_library_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/photos_permission_view.dart';
import 'video_info_detail_screen.dart';

class VideoInfoPickerScreen extends StatefulWidget {
  const VideoInfoPickerScreen({super.key});

  @override
  State<VideoInfoPickerScreen> createState() => _VideoInfoPickerScreenState();
}

class _VideoInfoPickerScreenState extends State<VideoInfoPickerScreen> {
  final VideoLibraryService _library = VideoLibraryService();
  bool _loading = true;
  bool _permissionDenied = false;
  List<AssetEntity> _videos = const [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _loading = true);
    try {
      final hasPermission = await _library.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        setState(() {
          _permissionDenied = true;
          _videos = const [];
          _loading = false;
        });
        return;
      }
      final entities = await _library.loadVideos();
      if (!mounted) return;
      setState(() {
        _permissionDenied = false;
        _videos = entities;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load videos. Try again.')),
      );
    }
  }

  void _onVideoSelected(AssetEntity video) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoInfoDetailScreen(video: video),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String two(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    }
    return '${d.inMinutes}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select a video',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : _permissionDenied
          ? const PhotosPermissionView(
              message:
                  'Allow Photos access to choose a recording and view its details.',
            )
          : _videos.isEmpty
          ? _EmptyPickerView(onRefresh: _loadVideos)
          : RefreshIndicator(
              onRefresh: _loadVideos,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: _videos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final video = _videos[index];
                  return _PickerTile(
                    video: video,
                    durationText: _formatDuration(video.duration),
                    onTap: () => _onVideoSelected(video),
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyPickerView extends StatelessWidget {
  const _EmptyPickerView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 56,
              color: palette.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No recordings found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record from the Record tab, then return here to inspect a video.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.video,
    required this.durationText,
    required this.onTap,
  });

  final AssetEntity video;
  final String durationText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder<Uint8List?>(
                  future: video.thumbnailDataWithSize(const ThumbnailSize(120, 68)),
                  builder: (context, snapshot) {
                    final bytes = snapshot.data;
                    if (bytes == null) {
                      return Container(
                        width: 72,
                        height: 48,
                        color: palette.peachLight,
                        child: const Icon(
                          Icons.videocam_rounded,
                          color: AppColors.primaryOrange,
                          size: 22,
                        ),
                      );
                    }
                    return Image.memory(bytes, width: 72, height: 48, fit: BoxFit.cover);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title ?? 'Screen Recording',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationText,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
