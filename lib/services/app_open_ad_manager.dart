import 'dart:io';

import 'package:flutter/foundation.dart';

import '../ulil/global.dart';
import 'replaykit_service.dart';

/// Shows App Open ads on launch/resume without interrupting recording or import.
class AppOpenAdManager {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  final ReplayKitService _replayKit = ReplayKitService();

  static const Duration _minInterval = Duration(minutes: 5);
  static const Duration _launchResumeGrace = Duration(seconds: 6);

  bool _coldStartHandled = false;
  bool _isShowing = false;
  DateTime? _lastShownAt;
  DateTime? _launchedAt;

  /// Call once when the main app shell is first shown.
  Future<void> tryShowOnColdStart() async {
    if (_coldStartHandled) return;
    _coldStartHandled = true;
    _launchedAt = DateTime.now();
    await _tryShow();
  }

  /// Call when the app returns to the foreground.
  Future<void> tryShowOnResume() async {
    if (_launchedAt != null &&
        DateTime.now().difference(_launchedAt!) < _launchResumeGrace) {
      return;
    }
    await _tryShow();
  }

  Future<void> _tryShow() async {
    if (!gAdsReady) return;
    if (_isShowing || isInterShowed || isAppOpenShowing) return;
    if (_lastShownAt != null &&
        DateTime.now().difference(_lastShownAt!) < _minInterval) {
      return;
    }
    if (await _shouldBlockForRecording()) return;

    _isShowing = true;
    isAppOpenShowing = true;
    try {
      if (kDebugMode) {
        debugPrint('AppOpenAdManager: showing app open ad');
      }
      gAds.openAdsInstance.showAdIfAvailableOpenAds();
      _lastShownAt = DateTime.now();
    } finally {
      _isShowing = false;
      // AdMob presents asynchronously; keep the guard briefly.
      Future<void>.delayed(const Duration(seconds: 2), () {
        isAppOpenShowing = false;
      });
    }
  }

  Future<bool> _shouldBlockForRecording() async {
    if (!Platform.isIOS) return false;

    if (await _replayKit.isScreenRecordingActive()) {
      return true;
    }

    final info = await _replayKit.getBroadcastInfo();
    if (info.isBroadcastActive) {
      return true;
    }

    // Avoid covering the import/save flow right after a broadcast ends.
    switch (info.status) {
      case 'saving':
      case 'saved_to_container':
      case 'saved':
        return true;
      default:
        break;
    }

    if (info.shouldRefreshVideos) {
      return true;
    }

    return false;
  }
}
