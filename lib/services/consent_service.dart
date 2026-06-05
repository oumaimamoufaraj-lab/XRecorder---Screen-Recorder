import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP (User Messaging Platform) consent flow for AdMob CMP compliance.
abstract final class ConsentService {
  static const _testDeviceId = '79738754EC81FA5F64972928128B2FFF';

  /// Requests consent info on every launch and shows the form when required.
  static Future<bool> gatherConsentIfNeeded() async {
    await _requestConsentInfoUpdate();
    await _loadAndShowConsentFormIfRequired();
    return ConsentInformation.instance.canRequestAds();
  }

  static Future<bool> canRequestAds() =>
      ConsentInformation.instance.canRequestAds();

  static Future<bool> isPrivacyOptionsRequired() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  static Future<void> showPrivacyOptionsForm() {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  static Future<void> _requestConsentInfoUpdate() {
    final completer = Completer<void>();
    final params = ConsentRequestParameters(
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
              testIdentifiers: const [_testDeviceId],
            )
          : null,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        if (!completer.isCompleted) completer.complete();
      },
      (FormError error) {
        if (kDebugMode) {
          debugPrint('UMP consent info update failed: ${error.message}');
        }
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  static Future<void> _loadAndShowConsentFormIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null && kDebugMode) {
        debugPrint('UMP consent form error: ${error.message}');
      }
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }
}
