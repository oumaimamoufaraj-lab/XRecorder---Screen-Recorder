import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/privacy_scan_result.dart';

/// On-device OCR scan for emails and phone-like strings in video frames.
class PrivacyScanService {
  PrivacyScanService._();
  static final PrivacyScanService instance = PrivacyScanService._();

  static final _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );
  static final _phoneRegex = RegExp(
    r'(?:\+?\d{1,3}[\s.-]?)?(?:\(?\d{3}\)?[\s.-]?)\d{3}[\s.-]?\d{4}',
  );

  Future<PrivacyScanResult> scanVideo(AssetEntity video) async {
    final file = await video.file;
    if (file == null) {
      return const PrivacyScanResult(score: 100, findings: []);
    }

    final durationMs = video.duration * 1000;
    final sampleFractions = [0.05, 0.25, 0.5, 0.75, 0.95];
    final findings = <PrivacyFinding>[];
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      for (final fraction in sampleFractions) {
        final timeMs = durationMs > 0
            ? (durationMs * fraction).round().clamp(0, durationMs - 1)
            : 0;
        final thumbPath = await VideoThumbnail.thumbnailFile(
          video: file.path,
          imageFormat: ImageFormat.PNG,
          timeMs: timeMs,
          quality: 80,
        );
        if (thumbPath == null) continue;

        final recognized = await recognizer.processImage(
          InputImage.fromFilePath(thumbPath),
        );
        _collectMatches(
          recognized.text,
          fraction,
          findings,
        );
      }
    } finally {
      await recognizer.close();
    }

    final deduped = _dedupeFindings(findings);
    final penalty = deduped.length * 12;
    final score = (100 - penalty).clamp(0, 100);

    return PrivacyScanResult(score: score, findings: deduped);
  }

  void _collectMatches(
    String text,
    double fraction,
    List<PrivacyFinding> findings,
  ) {
    for (final match in _emailRegex.allMatches(text)) {
      findings.add(
        PrivacyFinding(
          type: PrivacyFindingType.email,
          label: match.group(0)!,
          timeFraction: fraction,
        ),
      );
    }
    for (final match in _phoneRegex.allMatches(text)) {
      final value = match.group(0)!.trim();
      if (value.length < 10) continue;
      findings.add(
        PrivacyFinding(
          type: PrivacyFindingType.phone,
          label: value,
          timeFraction: fraction,
        ),
      );
    }
  }

  List<PrivacyFinding> _dedupeFindings(List<PrivacyFinding> input) {
    final seen = <String>{};
    final result = <PrivacyFinding>[];
    for (final finding in input) {
      final key = '${finding.type.name}:${finding.label.toLowerCase()}';
      if (seen.add(key)) result.add(finding);
    }
    return result;
  }
}
