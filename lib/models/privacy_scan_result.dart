enum PrivacyFindingType { email, phone, other }

class PrivacyFinding {
  const PrivacyFinding({
    required this.type,
    required this.label,
    required this.timeFraction,
  });

  final PrivacyFindingType type;
  final String label;
  final double timeFraction;

  String get typeLabel => switch (type) {
        PrivacyFindingType.email => 'Email',
        PrivacyFindingType.phone => 'Phone number',
        PrivacyFindingType.other => 'Sensitive text',
      };

  String get timeLabel {
    final pct = (timeFraction * 100).round();
    return '$pct% into video';
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'label': label,
        'timeFraction': timeFraction,
      };

  factory PrivacyFinding.fromJson(Map<String, dynamic> json) {
    return PrivacyFinding(
      type: PrivacyFindingType.values.byName(json['type'] as String),
      label: json['label'] as String,
      timeFraction: (json['timeFraction'] as num).toDouble(),
    );
  }
}

class PrivacyScanResult {
  const PrivacyScanResult({
    required this.score,
    required this.findings,
  });

  final int score;
  final List<PrivacyFinding> findings;

  bool get hasFindings => findings.isNotEmpty;

  String get scoreLabel => switch (score) {
        >= 85 => 'Low risk',
        >= 60 => 'Review recommended',
        _ => 'High risk — protect before sharing',
      };
}
