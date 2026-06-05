import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:multiads/multiads.dart';

import '../ulil/global.dart';
import 'consent_service.dart';

/// Fetches remote ad config and initializes ads only after UMP consent allows it.
abstract final class AdsBootstrapService {
  static const _configUrl =
      'https://drive.google.com/uc?export=download&id=1r5_RHL2Pm9ESw2628WTXAOQ_-U5GinRk';

  static String? _configJson;

  static Future<void> prefetchConfig() async {
    try {
      final response = await http.get(Uri.parse(_configUrl));
      if (response.statusCode == 200) {
        _configJson = response.body;
      }
    } catch (_) {
      // Remote config unavailable; app still launches without ads.
    }
  }

  static Future<void> initializeAfterConsent() async {
    if (_configJson == null) return;

    await ConsentService.gatherConsentIfNeeded();
    if (!await ConsentService.canRequestAds()) return;

    try {
      gAds = MultiAds(
        _configJson!,
        config: MultiAdsConfig(
          admobTestDeviceIds: const ['79738754EC81FA5F64972928128B2FFF'],
          facebookTestingId: 'd1a0df1f-2528-4e41-a4d3-1b401ba14f7d',
          enableLogs: kDebugMode,
        ),
      );
      await gAds.init();
      if (await ConsentService.canRequestAds()) {
        await gAds.loadAds();
        gAdsReady = true;
      }
    } catch (_) {
      // Ads init failed; app continues without ads.
    }
  }
}
