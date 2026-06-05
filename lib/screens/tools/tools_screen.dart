import 'package:flutter/material.dart';

import '../../services/ad_action_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/context_extensions.dart';
import 'video_info_picker_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const _comingSoonTools = [
    _ToolItem(
      title: 'Rename Video',
      subtitle: 'Change the title shown in your library',
      icon: Icons.drive_file_rename_outline_rounded,
      colors: [Color(0xFF81C784), Color(0xFF388E3C)],
    ),
    _ToolItem(
      title: 'Compress Video',
      subtitle: 'Reduce file size while keeping quality',
      icon: Icons.compress_rounded,
      colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
    ),
    _ToolItem(
      title: 'Trim Video',
      subtitle: 'Cut the start or end of a recording',
      icon: Icons.content_cut_rounded,
      colors: [Color(0xFFBA68C8), Color(0xFF7B1FA2)],
    ),
    _ToolItem(
      title: 'Extract Audio',
      subtitle: 'Save the soundtrack as an audio file',
      icon: Icons.audiotrack_rounded,
      colors: [Color(0xFF4DB6AC), Color(0xFF00796B)],
    ),
  ];

  static const _videoInfoTool = _ToolItem(
    title: 'Video Info',
    subtitle: 'Resolution, duration, file size, and format',
    icon: Icons.info_outline_rounded,
    colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
  );

  void _openVideoInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VideoInfoPickerScreen()),
    );
  }

  void _showComingSoon(BuildContext context, String toolName) {
    final palette = context.palette;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.peachLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.primaryOrange,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                toolName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming soon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$toolName is not available yet. '
                'Use Video Info or the Videos tab to work with your recordings today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: palette.textSecondary.withValues(alpha: 0.95),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('OK'),
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
    final palette = context.palette;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tools',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Video utilities for your recordings',
                    style: TextStyle(
                      fontSize: 15,
                      color: palette.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withValues(alpha: 0.12),
                          palette.peachLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.build_circle_outlined,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Video Info is available now. Other utilities will be added later.',
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.textPrimary.withValues(alpha: 0.85),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ToolCard(
                  tool: _videoInfoTool,
                  badge: null,
                  onTap: () => AdActionService.runWithRewarded(
                    () => _openVideoInfo(context),
                  ),
                ),
                const SizedBox(height: 10),
                for (final tool in _comingSoonTools) ...[
                  _ToolCard(
                    tool: tool,
                    badge: 'Soon',
                    onTap: () => _showComingSoon(context, tool.title),
                  ),
                  if (tool != _comingSoonTools.last) const SizedBox(height: 10),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItem {
  const _ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    required this.onTap,
    this.badge,
  });

  final _ToolItem tool;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: tool.colors,
                  ),
                ),
                child: Icon(tool.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tool.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.peachLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: palette.textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
