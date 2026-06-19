/// App-wide identity, links, and store metadata.
abstract final class AppConfig {
  static const String appDisplayName = 'NowRecorder - Screen Recorder';
  static const String appName = 'NowRecorder';
  static const String packageName = 'com.xrecorder.screenVideo';

  static const String privacyPolicyUrl =
      'https://sites.google.com/view/screen-recorder---xrecorder/home';

  static const String supportUrl =
      'https://sites.google.com/view/xrecorder---screen-recorder/home';

  /// Set after the app is live on the App Store (numeric ID only).
  static const String? appStoreId = null;

  static bool get showRateApp =>
      appStoreId != null && appStoreId!.isNotEmpty;

  static String? get appStoreReviewUrl => showRateApp
      ? 'https://apps.apple.com/app/id$appStoreId?action=write-review'
      : null;

  static const String appVersion = '1.0.5';

  /// AdMob application ID (must match Info.plist / AndroidManifest).
  /// Replace with your production ID from the AdMob console.
  static const String admobAppId = 'ca-app-pub-3940256099942544~1458002511';
}
