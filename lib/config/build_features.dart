import 'package:flutter/foundation.dart';

/// Compile-time flags for developer-only UI (never enabled in App Store release builds).
class BuildFeatures {
  BuildFeatures._();

  /// Broadcast audio debug panel and reports — debug builds only for v1.0.
  static bool get showBroadcastAudioDebugTools => kDebugMode;
}
