import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_design.dart';
import '../theme/context_extensions.dart';

enum AppTab { home, capture, clips, shield, menu }

class VaultBottomNav extends StatelessWidget {
  const VaultBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 4 : 12),
      child: Container(
        height: AppDesign.bottomNavHeight,
        decoration: BoxDecoration(
          color: palette.bottomNavBackground,
          borderRadius: BorderRadius.circular(AppDesign.radiusXl),
          border: Border.all(color: palette.divider),
          boxShadow: [
            BoxShadow(
              color: palette.cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _Slot(
              icon: Icons.grid_view_rounded,
              label: 'Home',
              active: currentTab == AppTab.home,
              onTap: () => onTabSelected(AppTab.home),
            ),
            _Slot(
              icon: Icons.photo_library_outlined,
              label: 'Clips',
              active: currentTab == AppTab.clips,
              onTap: () => onTabSelected(AppTab.clips),
            ),
            Expanded(
              child: Center(
                child: _CaptureFab(
                  active: currentTab == AppTab.capture,
                  onTap: () => onTabSelected(AppTab.capture),
                ),
              ),
            ),
            _Slot(
              icon: Icons.enhanced_encryption_outlined,
              label: 'Shield',
              active: currentTab == AppTab.shield,
              onTap: () => onTabSelected(AppTab.shield),
            ),
            _Slot(
              icon: Icons.tune_rounded,
              label: 'Menu',
              active: currentTab == AppTab.menu,
              onTap: () => onTabSelected(AppTab.menu),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = active ? palette.accent : palette.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureFab extends StatelessWidget {
  const _CaptureFab({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Material(
        color: active ? AppColors.splashOrange : AppColors.primaryOrange,
        elevation: active ? 2 : 8,
        shadowColor: AppColors.primaryOrange.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          child: SizedBox(
            width: AppDesign.fabSize,
            height: AppDesign.fabSize,
            child: Icon(
              active ? Icons.videocam : Icons.fiber_manual_record,
              color: Colors.white,
              size: active ? 26 : 28,
            ),
          ),
        ),
      ),
    );
  }
}
