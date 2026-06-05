import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/context_extensions.dart';

enum AppTab { record, videos, tools, settings }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.bottomNavBackground,
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.fiber_manual_record,
                label: 'Record',
                isActive: currentTab == AppTab.record,
                onTap: () => onTabSelected(AppTab.record),
              ),
              _NavItem(
                icon: Icons.video_library_outlined,
                label: 'Videos',
                isActive: currentTab == AppTab.videos,
                onTap: () => onTabSelected(AppTab.videos),
              ),
              _NavItem(
                icon: Icons.build_outlined,
                label: 'Tools',
                isActive: currentTab == AppTab.tools,
                onTap: () => onTabSelected(AppTab.tools),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                isActive: currentTab == AppTab.settings,
                onTap: () => onTabSelected(AppTab.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = isActive ? AppColors.primaryOrange : palette.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 10 : 6,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryOrange.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: isActive && label == 'Record' ? 20 : 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
