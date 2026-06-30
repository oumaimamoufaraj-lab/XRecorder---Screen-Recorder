/// App-wide identity, links, and store metadata.
abstract final class AppConfig {
  static const String appDisplayName = 'ShieldRec - Screen Recorder';
  static const String appName = 'ShieldRec';
  static const String appTagline = 'Capture screen. Shield what you share.';

  /// App Store subtitle (max 30 characters). Also in docs/app_store_resubmission.md
  static const String appStoreSubtitle = 'Blur & scan before you share';

  static const String packageName = 'com.xrecorder.screenVideo';
  static const String broadcastExtensionBundleId =
      'com.xrecorder.screenVideo.BroadcastExtension';
  static const String broadcastSetupUiBundleId =
      'com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI';
  static const String appGroupId = 'group.com.xrecorder.screenvideo.shared';

  /// Update page titles on these sites to match [appDisplayName] before resubmitting.
  static const String privacyPolicyUrl =
      'https://sites.google.com/view/screen-recorder---xrecorder/home';

  static const String supportUrl =
      'https://sites.google.com/view/xrecorder---screen-recorder/home';

  /// Set after the app is live on the App Store (numeric ID only).
  static const String? appStoreId = null;

  static bool get showRateApp => appStoreId != null && appStoreId!.isNotEmpty;

  static String? get appStoreReviewUrl => showRateApp
      ? 'https://apps.apple.com/app/id$appStoreId?action=write-review'
      : null;

  static const String appVersion = '1.1.0';
}
