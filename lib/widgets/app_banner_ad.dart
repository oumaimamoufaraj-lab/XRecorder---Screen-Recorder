import 'package:flutter/material.dart';
import '../ulil/global.dart';

/// Bottom banner ad slot (uses [gAds] config from [main]).
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key});

  static const Key adKey = ValueKey('app_bottom_banner');

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  bool _requested = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (!gAdsReady || _requested) return;
    _requested = true;
    gAds.bannerInstance.loadBannerAd(() {
      if (mounted) setState(() => _loaded = true);
    }, AppBannerAd.adKey);
  }

  @override
  void dispose() {
    if (gAdsReady) {
      gAds.bannerInstance.disposeBanner(AppBannerAd.adKey);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!gAdsReady || !_loaded) return const SizedBox.shrink();

    final adWidget = gAds.bannerInstance.getBannerAdWidget(AppBannerAd.adKey);

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.white,
        elevation: 4,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: Center(child: adWidget),
        ),
      ),
    );
  }
}
