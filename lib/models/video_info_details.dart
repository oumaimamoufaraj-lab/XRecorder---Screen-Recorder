import 'package:photo_manager/photo_manager.dart';

class VideoInfoDetails {
  const VideoInfoDetails({
    required this.asset,
    required this.title,
    required this.durationSeconds,
    required this.createdAt,
    this.fileSizeBytes,
    this.resolutionText,
    this.formatText,
  });

  final AssetEntity asset;
  final String title;
  final int durationSeconds;
  final DateTime createdAt;
  final int? fileSizeBytes;
  final String? resolutionText;
  final String? formatText;

  String get durationLabel {
    final d = Duration(seconds: durationSeconds);
    String two(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    }
    return '${d.inMinutes}:${two(d.inSeconds.remainder(60))}';
  }

  String get createdLabel {
    final local = createdAt.toLocal();
    return '${local.month}/${local.day}/${local.year} · '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String get fileSizeLabel {
    final bytes = fileSizeBytes;
    if (bytes == null) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
