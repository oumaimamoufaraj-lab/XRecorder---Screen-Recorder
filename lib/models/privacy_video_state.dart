import 'dart:convert';

import 'blur_region.dart';
import 'privacy_scan_result.dart';

enum PrivacyClipStatus { unreviewed, scanned, protected, safeToShare }

class PrivacyVideoState {
  const PrivacyVideoState({
    required this.assetId,
    required this.status,
    this.blurRegions = const [],
    this.lastScanScore,
    this.lastScanFindings = const [],
    this.hasSafeExport = false,
  });

  final String assetId;
  final PrivacyClipStatus status;
  final List<BlurRegion> blurRegions;
  final int? lastScanScore;
  final List<PrivacyFinding> lastScanFindings;
  final bool hasSafeExport;

  factory PrivacyVideoState.unreviewed(String assetId) {
    return PrivacyVideoState(assetId: assetId, status: PrivacyClipStatus.unreviewed);
  }

  bool get needsReview =>
      status == PrivacyClipStatus.unreviewed ||
      (lastScanScore != null && lastScanScore! < 85 && blurRegions.isEmpty);

  String get statusLabel => switch (status) {
        PrivacyClipStatus.unreviewed => 'Unreviewed',
        PrivacyClipStatus.scanned => 'Scanned',
        PrivacyClipStatus.protected => 'Protected',
        PrivacyClipStatus.safeToShare => 'Safe to share',
      };

  PrivacyVideoState copyWith({
    PrivacyClipStatus? status,
    List<BlurRegion>? blurRegions,
    int? lastScanScore,
    List<PrivacyFinding>? lastScanFindings,
    bool? hasSafeExport,
  }) {
    return PrivacyVideoState(
      assetId: assetId,
      status: status ?? this.status,
      blurRegions: blurRegions ?? this.blurRegions,
      lastScanScore: lastScanScore ?? this.lastScanScore,
      lastScanFindings: lastScanFindings ?? this.lastScanFindings,
      hasSafeExport: hasSafeExport ?? this.hasSafeExport,
    );
  }

  Map<String, dynamic> toJson() => {
        'assetId': assetId,
        'status': status.name,
        'blurRegions': blurRegions.map((r) => r.toJson()).toList(),
        'lastScanScore': lastScanScore,
        'lastScanFindings':
            lastScanFindings.map((f) => f.toJson()).toList(),
        'hasSafeExport': hasSafeExport,
      };

  factory PrivacyVideoState.fromJson(Map<String, dynamic> json) {
    return PrivacyVideoState(
      assetId: json['assetId'] as String,
      status: PrivacyClipStatus.values.byName(json['status'] as String),
      blurRegions: (json['blurRegions'] as List<dynamic>? ?? [])
          .map((e) => BlurRegion.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastScanScore: json['lastScanScore'] as int?,
      lastScanFindings: (json['lastScanFindings'] as List<dynamic>? ?? [])
          .map((e) => PrivacyFinding.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasSafeExport: json['hasSafeExport'] as bool? ?? false,
    );
  }

  static PrivacyVideoState? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return PrivacyVideoState.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}
