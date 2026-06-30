import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/privacy_video_state.dart';
import '../../services/photos_launcher_service.dart';
import '../../services/privacy_share_guard.dart';
import '../../services/privacy_storage_service.dart';
import '../../services/video_library_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/privacy_status_badge.dart';
import '../../widgets/vault_screen_header.dart';
import '../privacy/privacy_studio_screen.dart';
import 'video_player_screen.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => VideosScreenState();
}

class VideosScreenState extends State<VideosScreen> {
  final VideoLibraryService _library = VideoLibraryService();
  final PhotosLauncherService _photosLauncher = PhotosLauncherService();
  final PrivacyStorageService _privacyStorage = PrivacyStorageService.instance;
  bool _loading = false;
  bool _neverLoaded = true;
  bool _permissionDenied = false;
  List<AssetEntity> _videos = const [];
  List<AssetEntity> _allVideos = const [];
  Map<String, PrivacyVideoState> _privacyStates = {};
  String _searchQuery = '';
  VideoSortMode _sortMode = VideoSortMode.newest;

  @override
  void initState() {
    super.initState();
  }

  Future<void> reloadVideos({bool requestPermission = false}) {
    _neverLoaded = false;
    return _loadVideos(requestPermission: requestPermission);
  }

  Future<void> _loadVideos({bool requestPermission = false}) async {
    setState(() => _loading = true);

    try {
      final hasPermission = requestPermission
          ? await _library.requestPermission()
          : await _library.hasPermission();
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
      final states = await _privacyStorage.loadMany(entities.map((e) => e.id));
      if (!mounted) return;
      setState(() {
        _permissionDenied = false;
        _allVideos = entities;
        _videos = _applyFilters(entities);
        _privacyStates = states;
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

  Future<void> _openPrivacyStudio(AssetEntity video) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrivacyStudioScreen(video: video),
      ),
    );
    await _loadVideos();
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
    if (!await PrivacyShareGuard.confirmBeforeShare(context, video: video)) {
      return;
    }
    final file = await video.file;
    if (!mounted) return;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read video file for sharing.')),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'ShieldRec video'),
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
    if (!await _confirmDelete(video) || !mounted) return;
    await _deleteVideo(video);
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

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
    }
    return '${d.inMinutes}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        VaultScreenHeader(
          title: 'Clips',
          subtitle: _videos.isEmpty
              ? 'Your recordings appear here'
              : '${_videos.length} clip${_videos.length == 1 ? '' : 's'}',
          trailing: [
            VaultIconAction(
              icon: Icons.search,
              tooltip: 'Search',
              onPressed: _openSearch,
            ),
            const SizedBox(width: 6),
            VaultIconAction(
              icon: Icons.sort,
              tooltip: 'Sort',
              onPressed: _openSort,
            ),
            const SizedBox(width: 6),
            VaultIconAction(
              icon: Icons.refresh,
              tooltip: 'Refresh',
              onPressed: () => reloadVideos(requestPermission: true),
            ),
          ],
        ),
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
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
          ),
        Expanded(
          child: _neverLoaded
              ? const _ClipsIdleView()
              : _loading
              ? const _VideosLoadingView()
              : _permissionDenied
              ? _PermissionDeniedView(onOpenSettings: PhotoManager.openSetting)
              : _videos.isEmpty
              ? _EmptyView(
                  onRefresh: () => _loadVideos(requestPermission: true),
                  hasSearchQuery: _searchQuery.isNotEmpty,
                  totalInLibrary: _allVideos.length,
                )
              : RefreshIndicator(
                  onRefresh: () => _loadVideos(requestPermission: true),
                  color: palette.accent,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      final state = _privacyStates[video.id] ??
                          PrivacyVideoState.unreviewed(video.id);
                      return _ClipGridTile(
                        video: video,
                        durationText: _formatDuration(video.duration),
                        privacyState: state,
                        onTap: () => _showClipActions(video, state),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showClipActions(AssetEntity video, PrivacyVideoState state) {
    final palette = context.palette;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(video.title ?? 'Recording'),
                subtitle: PrivacyStatusBadge(state: state),
              ),
              ListTile(
                leading: Icon(Icons.shield_outlined, color: palette.accent),
                title: const Text('Open Shield Studio'),
                onTap: () {
                  Navigator.pop(context);
                  _openPrivacyStudio(video);
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Play'),
                onTap: () {
                  Navigator.pop(context);
                  _openVideo(video);
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('Safe Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareVideo(video);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Open in Photos'),
                onTap: () {
                  Navigator.pop(context);
                  _openInPhotos(video);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
                title: Text('Delete', style: TextStyle(color: Colors.red.shade700)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteVideoWithConfirmation(video);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClipGridTile extends StatelessWidget {
  const _ClipGridTile({
    required this.video,
    required this.durationText,
    required this.privacyState,
    required this.onTap,
  });

  final AssetEntity video;
  final String durationText;
  final PrivacyVideoState privacyState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _VideoThumbnail(
                video: video,
                durationText: durationText,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title ?? 'Recording',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PrivacyStatusBadge(state: privacyState, compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClipsIdleView extends StatelessWidget {
  const _ClipsIdleView();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: palette.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Your recordings appear here',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record from Capture or pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary),
          ),
        ],
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
    return Stack(
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
    );
  }
}
