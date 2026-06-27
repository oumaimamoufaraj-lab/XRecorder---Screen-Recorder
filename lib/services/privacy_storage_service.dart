import 'package:shared_preferences/shared_preferences.dart';

import '../models/privacy_video_state.dart';

/// Persists per-clip privacy state on device (blur regions, scan scores, status).
class PrivacyStorageService {
  PrivacyStorageService._();
  static final PrivacyStorageService instance = PrivacyStorageService._();

  static const _keyPrefix = 'privacy_clip_';

  Future<PrivacyVideoState> load(String assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$assetId');
    return PrivacyVideoState.fromJsonString(raw) ??
        PrivacyVideoState.unreviewed(assetId);
  }

  Future<Map<String, PrivacyVideoState>> loadMany(Iterable<String> assetIds) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, PrivacyVideoState>{};
    for (final id in assetIds) {
      final raw = prefs.getString('$_keyPrefix$id');
      result[id] = PrivacyVideoState.fromJsonString(raw) ??
          PrivacyVideoState.unreviewed(id);
    }
    return result;
  }

  Future<void> save(PrivacyVideoState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix${state.assetId}', state.toJsonString());
  }

  Future<int> countNeedingReview(Iterable<String> assetIds) async {
    final states = await loadMany(assetIds);
    return states.values.where((s) => s.needsReview).length;
  }

  Future<int> countProtected(Iterable<String> assetIds) async {
    final states = await loadMany(assetIds);
    return states.values
        .where(
          (s) =>
              s.status == PrivacyClipStatus.protected ||
              s.status == PrivacyClipStatus.safeToShare,
        )
        .length;
  }
}
