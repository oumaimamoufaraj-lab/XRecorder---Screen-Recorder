import 'package:flutter/foundation.dart';

/// App-wide recording state for the global indicator overlay.
class RecordingStatusController extends ChangeNotifier {
  bool _isActive = false;
  bool _isRecording = false;
  bool _broadcastActive = false;
  bool _appOnlyRecording = false;
  String _statusLabel = '';

  bool get isActive => _isActive;
  bool get isRecording => _isRecording;
  bool get broadcastActive => _broadcastActive;
  bool get appOnlyRecording => _appOnlyRecording;
  String get statusLabel => _statusLabel;

  void update({
    required bool isActive,
    required bool isRecording,
    required bool broadcastActive,
    required bool appOnlyRecording,
    required String statusLabel,
  }) {
    if (_isActive == isActive &&
        _isRecording == isRecording &&
        _broadcastActive == broadcastActive &&
        _appOnlyRecording == appOnlyRecording &&
        _statusLabel == statusLabel) {
      return;
    }
    _isActive = isActive;
    _isRecording = isRecording;
    _broadcastActive = broadcastActive;
    _appOnlyRecording = appOnlyRecording;
    _statusLabel = statusLabel;
    notifyListeners();
  }

  void clear() {
    update(
      isActive: false,
      isRecording: false,
      broadcastActive: false,
      appOnlyRecording: false,
      statusLabel: '',
    );
  }
}

final recordingStatusController = RecordingStatusController();
