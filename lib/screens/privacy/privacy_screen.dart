import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../services/photos_permission_service.dart';
import '../../models/privacy_video_state.dart';
import '../../services/privacy_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/privacy_status_badge.dart';
import '../../widgets/vault_screen_header.dart';
import '../tools/video_info_picker_screen.dart';
import 'privacy_studio_screen.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => PrivacyScreenState();
}

class PrivacyScreenState extends State<PrivacyScreen> {
  final _storage = PrivacyStorageService.instance;
  int _needsReview = 0;
  int _protected = 0;
  List<AssetEntity> _recentClips = const [];
  Map<String, PrivacyVideoState> _states = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> reload() => _loadDashboard();

  Future<void> _loadDashboard() async {
    if (!PhotosPermissionService.canBrowseLibrary) {
      if (mounted) {
        setState(() {
          _needsReview = 0;
          _protected = 0;
          _recentClips = const [];
          _states = {};
          _loading = false;
        });
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final granted = await PhotosPermissionService.isAccessGranted();
      if (!granted) {
        if (mounted) {
          setState(() {
            _needsReview = 0;
            _protected = 0;
            _recentClips = const [];
            _states = {};
            _loading = false;
          });
        }
        return;
      }

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );
      if (paths.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final assets = await paths.first.getAssetListPaged(page: 0, size: 40);
      final ids = assets.map((a) => a.id);
      final states = await _storage.loadMany(ids);
      final needsReview = states.values.where((s) => s.needsReview).length;
      final protected = states.values
          .where(
            (s) =>
                s.status == PrivacyClipStatus.protected ||
                s.status == PrivacyClipStatus.safeToShare,
          )
          .length;

      if (!mounted) return;
      setState(() {
        _recentClips = assets.take(8).toList();
        _states = states;
        _needsReview = needsReview;
        _protected = protected;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openStudio(AssetEntity video) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => PrivacyStudioScreen(video: video),
          ),
        )
        .then((_) => _loadDashboard());
  }

  void _openVideoInfo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VideoInfoPickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: AppColors.privacyTeal,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(
            child: VaultScreenHeader(
              title: 'Shield',
              subtitle: 'Protect sensitive information in your clips',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.privacyNavy,
                      AppColors.privacySurface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDesign.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield, color: AppColors.privacyTeal),
                        SizedBox(width: 10),
                        Text(
                          'On-device protection',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan for sensitive text, blur regions, and export a safe copy — all on your device.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatTile(
                          value: '$_needsReview',
                          label: 'Need review',
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 12),
                        _StatTile(
                          value: '$_protected',
                          label: 'Protected',
                          color: AppColors.splashOrange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_recentClips.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Record a video, then return here to protect it before sharing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.textSecondary),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Recent recordings',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final clip = _recentClips[index];
                      final state = _states[clip.id] ??
                          PrivacyVideoState.unreviewed(clip.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentClipCard(
                          title: clip.title ?? 'Screen Recording',
                          state: state,
                          onProtect: () => _openStudio(clip),
                        ),
                      );
                    },
                    childCount: _recentClips.length,
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _QuickActionTile(
                  title: 'Video Info',
                  subtitle: 'Inspect resolution, duration, and format',
                  icon: Icons.info_outline_rounded,
                  onTap: _openVideoInfo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentClipCard extends StatelessWidget {
  const _RecentClipCard({
    required this.title,
    required this.state,
    required this.onProtect,
  });

  final String title;
  final PrivacyVideoState state;
  final VoidCallback onProtect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onProtect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.privacyTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.blur_on, color: AppColors.privacyTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PrivacyStatusBadge(state: state),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: AppColors.privacyTeal),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: palette.textPrimary)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
