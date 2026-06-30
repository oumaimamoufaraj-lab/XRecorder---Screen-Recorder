import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../controllers/theme_controller.dart';
import '../../services/theme_preference_service.dart';
import '../../config/app_config.dart';
import '../../services/photos_permission_service.dart';
import '../../models/privacy_video_state.dart';
import '../../services/privacy_storage_service.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/vault_screen_header.dart';
import '../privacy/privacy_studio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onGoToCapture,
    required this.onGoToClips,
    required this.onGoToShield,
  });

  final VoidCallback onGoToCapture;
  final VoidCallback onGoToClips;
  final VoidCallback onGoToShield;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _storage = PrivacyStorageService.instance;
  int _clipCount = 0;
  int _needsReview = 0;
  int _protected = 0;
  List<AssetEntity> _recent = const [];
  Map<String, PrivacyVideoState> _states = {};
  bool _loading = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    try {
      final granted = await PhotosPermissionService.requestAccess();
      if (!granted) {
        if (mounted) {
          setState(() {
            _permissionDenied = true;
            _clipCount = 0;
            _needsReview = 0;
            _protected = 0;
            _recent = const [];
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
      final assets = await paths.first.getAssetListPaged(page: 0, size: 30);
      final states = await _storage.loadMany(assets.map((a) => a.id));
      if (!mounted) return;
      setState(() {
        _permissionDenied = false;
        _clipCount = assets.length;
        _recent = assets.take(6).toList();
        _states = states;
        _needsReview = states.values.where((s) => s.needsReview).length;
        _protected = states.values
            .where(
              (s) =>
                  s.status == PrivacyClipStatus.protected ||
                  s.status == PrivacyClipStatus.safeToShare,
            )
            .length;
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
        .then((_) => reload());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final themeController = ThemeScope.of(context);

    return RefreshIndicator(
      onRefresh: reload,
      color: palette.accent,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: VaultScreenHeader(
              title: AppConfig.appName,
              subtitle: AppConfig.appTagline,
              trailing: [
                ListenableBuilder(
                  listenable: themeController,
                  builder: (context, _) {
                    final dark = Theme.of(context).brightness == Brightness.dark;
                    return VaultIconAction(
                      icon: dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      tooltip: dark ? 'Light mode' : 'Dark mode',
                      onPressed: () => themeController.setPreference(
                        dark
                            ? AppThemePreference.light
                            : AppThemePreference.dark,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      title: 'Capture',
                      subtitle: 'Record your screen',
                      icon: Icons.fiber_manual_record,
                      gradient: const [
                        AppColors.primaryOrange,
                        AppColors.splashOrange,
                      ],
                      onTap: widget.onGoToCapture,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeCard(
                      title: 'Shield',
                      subtitle: 'Blur & safe export',
                      icon: Icons.enhanced_encryption,
                      gradient: const [
                        AppColors.primaryOrangeLight,
                        AppColors.splashOrange,
                      ],
                      onTap: widget.onGoToShield,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _StatsStrip(
                loading: _loading,
                clips: _clipCount,
                review: _needsReview,
                protected: _protected,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Text(
                    'RECENT CLIPS',
                    style: AppDesign.sectionLabel(palette.textSecondary),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onGoToClips,
                    child: const Text('See all'),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recent.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      _permissionDenied
                          ? 'Photos access is needed to show your recent clips.'
                          : 'No clips yet. Tap the red capture button to record.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.textSecondary),
                    ),
                    if (_permissionDenied) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: PhotoManager.openSetting,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Open Settings'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final clip = _recent[index];
                    final state = _states[clip.id] ??
                        PrivacyVideoState.unreviewed(clip.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecentRow(
                        title: clip.title ?? 'Recording',
                        duration: _formatDuration(clip.duration),
                        state: state,
                        onProtect: () => _openStudio(clip),
                        onOpen: widget.onGoToClips,
                      ),
                    );
                  },
                  childCount: _recent.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        child: Ink(
          decoration: AppDesign.heroCardDecoration(gradient: gradient),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.loading,
    required this.clips,
    required this.review,
    required this.protected,
  });

  final bool loading;
  final int clips;
  final int review;
  final int protected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          _Stat(value: loading ? '—' : '$clips', label: 'Clips', palette: palette),
          _divider(palette),
          _Stat(value: loading ? '—' : '$review', label: 'Review', palette: palette),
          _divider(palette),
          _Stat(
            value: loading ? '—' : '$protected',
            label: 'Shielded',
            palette: palette,
          ),
        ],
      ),
    );
  }

  Widget _divider(AppPalette palette) => Container(
        width: 1,
        height: 32,
        color: palette.divider,
      );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.palette,
  });

  final String value;
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.title,
    required this.duration,
    required this.state,
    required this.onProtect,
    required this.onOpen,
  });

  final String title;
  final String duration;
  final PrivacyVideoState state;
  final VoidCallback onProtect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                ),
                child: Icon(Icons.movie_outlined, color: palette.accent),
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
                    Text(
                      '$duration · ${state.statusLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onProtect,
                child: const Text('Shield'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
