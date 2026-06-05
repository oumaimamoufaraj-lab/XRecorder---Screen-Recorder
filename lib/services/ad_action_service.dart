import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ulil/global.dart';

/// Shows rewarded / interstitial ads before user actions.
class AdActionService {
  AdActionService._();

  static bool get _canShowAd =>
      gAdsReady && !isInterShowed && !isAppOpenShowing;

  static void runWithRewarded(VoidCallback action) {
    unawaited(runWithRewardedAsync(() async => action()));
  }

  static Future<void> runWithRewardedAsync(
    Future<void> Function() action,
  ) async {
    if (!_canShowAd) {
      await action();
      return;
    }

    final completer = Completer<void>();
    gAds.rewardInstance.showRewardAd(() {
      isInterShowed = false;
      action().whenComplete(() {
        if (!completer.isCompleted) completer.complete();
      });
    });
    await completer.future;
  }

  static void runWithInterstitial(VoidCallback action) {
    unawaited(runWithInterstitialAsync(() async {
      action();
      return;
    }));
  }

  static Future<T> runWithInterstitialAsync<T>(
    Future<T> Function() action,
  ) async {
    if (!_canShowAd) {
      return action();
    }

    final completer = Completer<T>();
    gAds.interInstance.showInterstitialAd(() {
      isInterShowed = false;
      action().then((value) {
        if (!completer.isCompleted) completer.complete(value);
      }).catchError((Object e, StackTrace st) {
        if (!completer.isCompleted) completer.completeError(e, st);
      });
    });
    return completer.future;
  }
}
