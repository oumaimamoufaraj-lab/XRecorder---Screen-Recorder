import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/ad_action_service.dart';
import '../../services/photos_launcher_service.dart';
import '../../services/video_library_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/context_extensions.dart';
import 'video_player_screen.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => VideosScreenState();
}

class VideosScreenState extends State<VideosScreen> {
  final VideoLibraryService _library = VideoLibraryService();
  final PhotosLauncherService _photosLauncher = PhotosLauncherService();
  bool _loading = true;
  bool _permissionDenied = false;
  List<AssetEntity> _videos = const [];
  List<AssetEntity> _allVideos = const [];
  String _searchQuery = '';
  VideoSortMode _sortMode = VideoSortMode.newest;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void reloadVideos() {
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
          _allVideos = const [];
          _loading = false;
        });
        return;
      }

      final entities = await _library.loadVideos();
      if (!mounted) return;
      setState(() {
        _permissionDenied = false;
        _allVideos = entities;
        _videos = _applyFilters(entities);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _permissionDenied = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load videos. Pull down to try again.')),
      );
    }
  }

  List<AssetEntity> _applyFilters(List<AssetEntity> source) {
    final filtered = _library.filterByQuery(source, _searchQuery);
    return _library.sortVideos(filtered, _sortMode);
  }

  void _applyLocalFilters() {
    setState(() => _videos = _applyFilters(_allVideos));
  }

  void _removeVideoLocally(AssetEntity video) {
    setState(() {
      _allVideos = _allVideos.where((v) => v.id != video.id).toList();
      _videos = _applyFilters(_allVideos);
    });
  }

  Future<void> _openSearch() async {
    final controller = TextEditingController(text: _searchQuery);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search recordings'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by title...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    if (result == null) return;
    _searchQuery = result;
    _applyLocalFilters();
  }

  Future<void> _openSort() async {
    final selected = await showModalBottomSheet<VideoSortMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Newest first'),
              trailing: _sortMode == VideoSortMode.newest
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () => Navigator.pop(context, VideoSortMode.newest),
            ),
            ListTile(
              title: const Text('Oldest first'),
              trailing: _sortMode == VideoSortMode.oldest
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () => Navigator.pop(context, VideoSortMode.oldest),
            ),
            ListTile(
              title: const Text('Longest first'),
              trailing: _sortMode == VideoSortMode.longest
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () => Navigator.pop(context, VideoSortMode.longest),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    _sortMode = selected;
    _applyLocalFilters();
  }

  Future<void> _openVideo(AssetEntity video) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(video: video),
      ),
    );
    await _loadVideos();
  }

  Future<void> _shareVideo(AssetEntity video) async {
    final file = await video.file;
    if (!mounted) return;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read video file for sharing.')),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'XRecorder video'),
    );
  }

  Future<bool> _confirmDelete(AssetEntity video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recording?'),
        content: const Text(
          'This will permanently remove the video from your Photos library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _deleteVideo(AssetEntity video) async {
    final deleted = await _library.deleteVideo(video);
    if (!mounted) return;
    if (deleted) {
      _removeVideoLocally(video);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording deleted.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete recording.')),
      );
    }
  }

  Future<void> _deleteVideoWithConfirmation(AssetEntity video) async {
    await AdActionService.runWithInterstitialAsync(() async {
      if (!await _confirmDelete(video) || !mounted) return;
      await _deleteVideo(video);
    });
  }

  Future<void> _openInPhotos(AssetEntity video) async {
    final opened = await _photosLauncher.openInPhotos(video);
    if (!mounted) return;
    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opened Photos. Find your recording in Recents or Videos.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Photos.')),
      );
    }
  }

  void _showVideoOverflow(AssetEntity video) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Open in Photos'),
              subtitle: const Text('View in the system Photos app'),
              onTap: () {
                Navigator.pop(context);
                _openInPhotos(video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteVideoWithConfirmation(video);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
    }
    return '${d.inMinutes}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Screen Recordings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (_videos.isNotEmpty)
                        Text(
                          '${_videos.length} video${_videos.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openSearch,
                  icon: const Icon(Icons.search),
                  color: palette.textPrimary,
                  tooltip: 'Search',
                ),
                IconButton(
                  onPressed: _openSort,
                  icon: const Icon(Icons.sort),
                  color: palette.textPrimary,
                  tooltip: 'Sort',
                ),
                IconButton(
                  onPressed: () =>
                      AdActionService.runWithInterstitial(_loadVideos),
                  icon: const Icon(Icons.refresh),
                  color: palette.textPrimary,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text('Search: $_searchQuery'),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    _searchQuery = '';
                    _applyLocalFilters();
                  },
                ),
              ),
            ],
            Expanded(
              child: _loading
                  ? const _VideosLoadingView()
                  : _permissionDenied
                  ? _PermissionDeniedView(onOpenSettings: PhotoManager.openSetting)
                  : _videos.isEmpty
                  ? _EmptyView(
                      onRefresh: () => AdActionService.runWithInterstitialAsync(
                        _loadVideos,
                      ),
                      hasSearchQuery: _searchQuery.isNotEmpty,
                      totalInLibrary: _allVideos.length,
                    )
                  : RefreshIndicator(
                      onRefresh: () => AdActionService.runWithInterstitialAsync(
                        _loadVideos,
                      ),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 12, bottom: 24),
                        itemCount: _videos.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final video = _videos[index];
                          final durationText = _formatDuration(video.duration);
                          final dateText = _formatDate(video.createDateTime);
                          return Dismissible(
                            key: ValueKey(video.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            confirmDismiss: (_) {
                              return AdActionService.runWithInterstitialAsync(
                                () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  if (!await _confirmDelete(video)) {
                                    return false;
                                  }
                                  if (!mounted) return false;
                                  final deleted =
                                      await _library.deleteVideo(video);
                                  if (!mounted) return false;
                                  if (deleted) {
                                    _removeVideoLocally(video);
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Recording deleted.'),
                                      ),
                                    );
                                    return true;
                                  }
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not delete recording.',
                                      ),
                                    ),
                                  );
                                  return false;
                                },
                              );
                            },
                            child: _VideoListTile(
                              video: video,
                              durationText: durationText,
                              dateText: dateText,
                              onPlay: () => _openVideo(video),
                              onShare: () => AdActionService.runWithInterstitial(
                                () => _shareVideo(video),
                              ),
                              onDelete: () =>
                                  _deleteVideoWithConfirmation(video),
                              onMore: () => _showVideoOverflow(video),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: palette.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Photos access required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Allow Photos access to view your screen recordings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onOpenSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

class _VideosLoadingView extends StatelessWidget {
  const _VideosLoadingView();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading recordings…',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reading from your Photos library',
            style: TextStyle(
              fontSize: 14,
              color: palette.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.onRefresh,
    required this.hasSearchQuery,
    required this.totalInLibrary,
  });

  final Future<void> Function() onRefresh;
  final bool hasSearchQuery;
  final int totalInLibrary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final title = hasSearchQuery
        ? 'No matching recordings'
        : 'No screen recordings yet';
    final subtitle = hasSearchQuery
        ? 'Try a different search or clear the filter.'
        : 'Record from the Record tab. Videos saved to Photos appear here after you refresh.';

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: palette.peachLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearchQuery ? Icons.search_off_rounded : Icons.videocam_rounded,
                color: AppColors.primaryOrange,
                size: 52,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: palette.textSecondary,
                height: 1.4,
              ),
            ),
            if (!hasSearchQuery && totalInLibrary == 0) ...[
              const SizedBox(height: 16),
              Text(
                'Tip: After a broadcast, reopen the app so the clip can import to Photos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: palette.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  const _VideoThumbnail({
    required this.video,
    required this.durationText,
  });

  final AssetEntity video;
  final String durationText;

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  static const _size = ThumbnailSize(240, 136);
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final bytes = await widget.video.thumbnailDataWithSize(_size);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 104,
        height: 58,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_loading)
              ColoredBox(
                color: palette.peachLight,
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              )
            else if (_bytes != null)
              Image.memory(
                _bytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            else
              ColoredBox(
                color: palette.peachLight,
                child: const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.primaryOrange,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.durationText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _VideoListTile extends StatelessWidget {
  const _VideoListTile({
    required this.video,
    required this.durationText,
    required this.dateText,
    required this.onPlay,
    required this.onShare,
    required this.onDelete,
    required this.onMore,
  });

  final AssetEntity video;
  final String durationText;
  final String dateText;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: palette.cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onPlay,
                borderRadius: BorderRadius.circular(10),
                child: _VideoThumbnail(
                  video: video,
                  durationText: durationText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title ?? 'Screen Recording',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _VideoActionButton(
                          icon: Icons.play_circle_outline,
                          label: 'Play',
                          color: AppColors.primaryOrange,
                          onPressed: onPlay,
                        ),
                        _VideoActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onPressed: onShare,
                        ),
                        _VideoActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          color: Colors.red.shade700,
                          onPressed: onDelete,
                        ),
                        IconButton(
                          onPressed: onMore,
                          icon: const Icon(Icons.more_vert, size: 22),
                          color: palette.textSecondary,
                          tooltip: 'More',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoActionButton extends StatelessWidget {
  const _VideoActionButton({
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
    final iconColor = color ?? context.palette.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: iconColor),
        label: Text(
          label,
          style: TextStyle(fontSize: 12, color: iconColor),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
