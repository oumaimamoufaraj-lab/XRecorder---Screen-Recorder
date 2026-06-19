import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../services/ad_action_service.dart';
import '../../services/consent_service.dart';
import '../../services/replaykit_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/recording_help_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ReplayKitService _replayKit = ReplayKitService();
  bool _isSimulator = false;
  bool _showPrivacyChoices = false;

  @override
  void initState() {
    super.initState();
    _loadSimulatorFlag();
    _loadPrivacyChoicesFlag();
  }

  Future<void> _loadSimulatorFlag() async {
    if (!Platform.isIOS) return;
    final isSimulator = await _replayKit.isSimulator();
    if (mounted) setState(() => _isSimulator = isSimulator);
  }

  Future<void> _loadPrivacyChoicesFlag() async {
    final required = await ConsentService.isPrivacyOptionsRequired();
    if (mounted) setState(() => _showPrivacyChoices = required);
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
            'NowRecorder saves screen recordings to your device Photos library. '
            'Recordings stay on your device unless you choose to share them.\n\n'
            'The app requests Photos access to save and list your recordings, and '
            'microphone access when you turn the microphone on during a broadcast.\n\n'
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
    final supportTiles = <Widget>[
      if (AppConfig.showRateApp)
        _SettingsTile(
          icon: Icons.star_outline_rounded,
          iconColor: const Color(0xFFFFB300),
          title: 'Rate App',
          subtitle: 'Enjoying NowRecorder? Leave a review',
          onTap: () => _openUrl(AppConfig.appStoreReviewUrl!),
        ),
      _SettingsTile(
        icon: Icons.support_agent_outlined,
        iconColor: AppColors.purple,
        title: 'Contact Support',
        subtitle: 'Help and support page',
        onTap: () => _openUrl(AppConfig.supportUrl),
      ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'App',
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                iconColor: AppColors.teal,
                title: 'Help / How to record',
                subtitle: 'Broadcast picker, microphone, and saving',
                onTap: () => AdActionService.runWithInterstitial(() {
                  showRecordingHelpDialog(
                    context,
                    isSimulator: _isSimulator,
                  );
                }),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.linkBlue,
                title: 'Privacy Policy',
                onTap: _showPrivacyPolicy,
              ),
              if (_showPrivacyChoices)
                _SettingsTile(
                  icon: Icons.ads_click_outlined,
                  iconColor: AppColors.teal,
                  title: 'Ad privacy choices',
                  subtitle: 'Manage consent for personalized ads',
                  onTap: () => ConsentService.showPrivacyOptionsForm(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Support',
            children: supportTiles,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppConfig.appDisplayName} · v${AppConfig.appVersion}',
              style: TextStyle(
                fontSize: 13,
                color: palette.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: palette.textSecondary.withValues(alpha: 0.85),
            ),
          ),
        ),
        Material(
          color: palette.card,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: palette.divider,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primaryOrange).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? AppColors.primaryOrange),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: palette.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 13, color: palette.textSecondary),
            )
          : null,
      trailing: onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: palette.textSecondary.withValues(alpha: 0.5),
                )
          : null,
    );
  }
}
