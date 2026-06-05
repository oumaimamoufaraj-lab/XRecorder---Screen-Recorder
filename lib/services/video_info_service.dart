import 'package:photo_manager/photo_manager.dart';

import '../models/video_info_details.dart';

class VideoInfoService {
  Future<VideoInfoDetails> loadDetails(AssetEntity video) async {
    final mime = await video.mimeTypeAsync;
    final file = await video.file;

    int? fileSizeBytes;
    String? formatText = mime;

    if (file != null) {
      try {
        fileSizeBytes = await file.length();
      } catch (_) {
        // Keep size unknown.
      }
      formatText ??= _formatFromPath(file.path);
    }

    final w = video.orientatedWidth;
    final h = video.orientatedHeight;
    final String? resolutionText =
        w > 0 && h > 0 ? '$w × $h' : null;

    return VideoInfoDetails(
      asset: video,
      title: video.title ?? 'Screen Recording',
      durationSeconds: video.duration,
      createdAt: video.createDateTime,
      fileSizeBytes: fileSizeBytes,
      resolutionText: resolutionText,
      formatText: formatText ?? 'Video',
    );
  }

  String? _formatFromPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot >= path.length - 1) return null;
    return path.substring(dot + 1).toUpperCase();
  }
}
