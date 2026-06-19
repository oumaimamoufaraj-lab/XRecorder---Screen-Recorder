import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import '../services/theme_preference_service.dart';
import '../theme/app_colors.dart';
import '../theme/context_extensions.dart';

Future<void> showAppearanceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _AppearanceSheet(
      controller: ThemeScope.of(context),
    ),
  );
}

class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selected = controller.preference;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        color: AppColors.primaryOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose how NowRecorder looks on your device',
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ThemeOptionTile(
                  icon: Icons.light_mode_outlined,
                  title: 'Light',
                  subtitle: 'Bright background, easy to read in daylight',
                  isSelected: selected == AppThemePreference.light,
                  onTap: () => controller.setPreference(AppThemePreference.light),
                ),
                const SizedBox(height: 8),
                _ThemeOptionTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark',
                  subtitle: 'Dimmed colors, comfortable at night',
                  isSelected: selected == AppThemePreference.dark,
                  onTap: () => controller.setPreference(AppThemePreference.dark),
                ),
                const SizedBox(height: 8),
                _ThemeOptionTile(
                  icon: Icons.brightness_auto_outlined,
                  title: 'System',
                  subtitle: 'Match your iPhone appearance setting',
                  isSelected: selected == AppThemePreference.system,
                  onTap: () => controller.setPreference(AppThemePreference.system),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: isSelected
          ? AppColors.primaryOrange.withValues(alpha: 0.1)
          : palette.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryOrange.withValues(alpha: 0.45)
                  : palette.divider,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryOrange.withValues(alpha: 0.15)
                      : palette.orangeTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primaryOrange
                      : palette.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryOrange,
                  size: 24,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: palette.textSecondary.withValues(alpha: 0.35),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
