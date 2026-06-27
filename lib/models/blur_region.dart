import 'dart:convert';

/// Normalized rectangle (0–1) relative to the video frame.
class BlurRegion {
  const BlurRegion({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final String id;
  final double left;
  final double top;
  final double width;
  final double height;

  BlurRegion copyWith({
    String? id,
    double? left,
    double? top,
    double? width,
    double? height,
  }) {
    return BlurRegion(
      id: id ?? this.id,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      };

  factory BlurRegion.fromJson(Map<String, dynamic> json) {
    return BlurRegion(
      id: json['id'] as String,
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  static List<BlurRegion> listFromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => BlurRegion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJsonString(List<BlurRegion> regions) {
    return jsonEncode(regions.map((r) => r.toJson()).toList());
  }
}
