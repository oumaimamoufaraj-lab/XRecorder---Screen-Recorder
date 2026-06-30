import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../services/replaykit_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_design.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/appearance_sheet.dart';
import '../../widgets/recording_help_dialog.dart';
import '../../widgets/vault_screen_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ReplayKitService _replayKit = ReplayKitService();
  bool _isSimulator = false;

  @override
  void initState() {
    super.initState();
    _loadSimulatorFlag();
  }

  Future<void> _loadSimulatorFlag() async {
    if (!Platform.isIOS) return;
    final isSimulator = await _replayKit.isSimulator();
    if (mounted) setState(() => _isSimulator = isSimulator);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      _showMessage('Could not open link.');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'ShieldRec saves screen recordings to your device Photos library. '
            'Recordings stay on your device unless you choose to share them.\n\n'
            'Shield Studio scans for emails and phone numbers on-device, lets you '
            'add blur regions, and can export a redacted copy — no account required '
            'and no video content is uploaded to our servers.\n\n'
            'Photos access is requested on Home and Clips to show your recordings, '
            'and when you start recording. '
            'Microphone access is optional during a broadcast.\n\n'
            'Read the full privacy policy on our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openUrl(AppConfig.privacyPolicyUrl);
            },
            child: const Text('Open website'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        VaultScreenHeader(
          title: 'Menu',
          subtitle: 'Preferences & support',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryOrange, AppColors.splashOrange],
              ),
              borderRadius: BorderRadius.circular(AppDesign.radiusLg),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  ),
                  child: const Icon(Icons.enhanced_encryption, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConfig.appDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'v${AppConfig.appVersion} · On-device only',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _MenuTile(
          icon: Icons.dark_mode_outlined,
          title: 'Appearance',
          subtitle: 'Light or dark theme',
          onTap: () => showAppearanceSheet(context),
        ),
        _MenuTile(
          icon: Icons.help_outline_rounded,
          title: 'Recording guide',
          onTap: () => showRecordingHelpDialog(context, isSimulator: _isSimulator),
        ),
        _MenuTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy policy',
          onTap: _showPrivacyPolicy,
        ),
        if (AppConfig.showRateApp)
          _MenuTile(
            icon: Icons.star_outline_rounded,
            title: 'Rate the app',
            onTap: () => _openUrl(AppConfig.appStoreReviewUrl!),
          ),
        _MenuTile(
          icon: Icons.support_agent_outlined,
          title: 'Contact support',
          onTap: () => _openUrl(AppConfig.supportUrl),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'All recordings and privacy scans stay on your device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Material(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            ),
            child: Icon(icon, color: palette.accent, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, color: palette.textPrimary),
          ),
          subtitle: subtitle != null
              ? Text(subtitle!, style: TextStyle(color: palette.textSecondary))
              : null,
          trailing: Icon(Icons.chevron_right, color: palette.textSecondary),
        ),
      ),
    );
  }
}
