import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/developer_settings_service.dart';
import '../../theme/app_colors.dart';

/// Opens app settings. Returns the updated developer-mode flag when changed.
Future<bool?> showAppSettingsSheet(
  BuildContext context, {
  required bool developerModeEnabled,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => _AppSettingsSheet(
      initialDeveloperMode: developerModeEnabled,
    ),
  );
}

class _AppSettingsSheet extends StatefulWidget {
  const _AppSettingsSheet({required this.initialDeveloperMode});

  final bool initialDeveloperMode;

  @override
  State<_AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends State<_AppSettingsSheet> {
  final DeveloperSettingsService _settings = DeveloperSettingsService();
  late bool _developerMode = widget.initialDeveloperMode;

  Future<void> _onDeveloperModeChanged(bool value) async {
    setState(() => _developerMode = value);
    await _settings.setDeveloperModeEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Developer mode'),
              subtitle: Text(
                kDebugMode
                    ? 'Debug build: broadcast audio tools are always visible on the Record tab.'
                    : 'Shows broadcast audio debug tools on the Record tab for testing.',
                style: const TextStyle(fontSize: 13),
              ),
              value: kDebugMode ? true : _developerMode,
              onChanged: kDebugMode ? null : _onDeveloperModeChanged,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                'Developer mode is always on in debug builds.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context, _developerMode),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
