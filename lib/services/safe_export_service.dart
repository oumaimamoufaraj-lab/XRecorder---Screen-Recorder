import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/blur_region.dart';

/// Exports a redacted copy of a video with static blur regions baked in.
class SafeExportService {
  SafeExportService._();
  static final SafeExportService instance = SafeExportService._();

  Future<File?> exportRedactedCopy({
    required File sourceFile,
    required List<BlurRegion> regions,
    required int videoWidth,
    required int videoHeight,
  }) async {
    if (regions.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/safe_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final filter = _buildFilterChain(regions, videoWidth, videoHeight);
    final command =
        '-y -i "${sourceFile.path}" -filter_complex "$filter" -map "[outv]" -map 0:a? -c:a copy "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) return null;

    final output = File(outputPath);
    if (!output.existsSync()) return null;
    return output;
  }

  Future<bool> saveToPhotos(File file, {String title = 'Safe Recording'}) async {
    try {
      await PhotoManager.editor.saveVideo(
        file,
        title: title,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String _buildFilterChain(
    List<BlurRegion> regions,
    int videoWidth,
    int videoHeight,
  ) {
    final buffer = StringBuffer();
    var currentLabel = '[0:v]';

    for (var i = 0; i < regions.length; i++) {
      final region = regions[i];
      final x = (region.left * videoWidth).round().clamp(0, videoWidth - 1);
      final y = (region.top * videoHeight).round().clamp(0, videoHeight - 1);
      final w = (region.width * videoWidth).round().clamp(1, videoWidth - x);
      final h = (region.height * videoHeight).round().clamp(1, videoHeight - y);

      final baseLabel = '[base$i]';
      final cropLabel = '[crop$i]';
      final blurLabel = '[blur$i]';
      final outLabel = i == regions.length - 1 ? '[outv]' : '[tmp$i]';

      buffer.write('$currentLabel split=2$baseLabel$cropLabel;');
      buffer.write(
        '$cropLabel crop=$w:$h:$x:$y,boxblur=luma_radius=12:luma_power=2$blurLabel;',
      );
      buffer.write('$baseLabel$blurLabel overlay=$x:$y$outLabel;');

      currentLabel = outLabel;
    }

    return buffer.toString();
  }
}
