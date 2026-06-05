import 'package:flutter/material.dart';

import '../../services/ad_action_service.dart';
import '../../services/app_open_ad_manager.dart';
import '../../widgets/app_banner_ad.dart';
import '../../widgets/app_bottom_nav.dart';
import '../record/record_screen.dart';
import '../settings/settings_screen.dart';
import '../tools/tools_screen.dart';
import '../videos/videos_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppTab _currentTab = AppTab.record;
  final GlobalKey<VideosScreenState> _videosKey = GlobalKey<VideosScreenState>();

  void _refreshVideos() {
    _videosKey.currentState?.reloadVideos();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppOpenAdManager.instance.tryShowOnColdStart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentTab.index,
              children: [
                RecordScreen(onRecordingSaved: _refreshVideos),
                VideosScreen(key: _videosKey),
                const ToolsScreen(),
                const SettingsScreen(),
              ],
            ),
          ),
          const AppBannerAd(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentTab: _currentTab,
        onTabSelected: (tab) {
          if (tab == _currentTab) return;
          void selectTab() {
            setState(() => _currentTab = tab);
            if (tab == AppTab.videos) {
              _refreshVideos();
            }
          }
          if (tab == AppTab.videos) {
            AdActionService.runWithRewarded(selectTab);
          } else {
            AdActionService.runWithInterstitial(selectTab);
          }
        },
      ),
    );
  }
}
