import 'dart:io';

import 'package:flutter/services.dart';

import '../models/broadcast_audio_debug_report.dart';

class BroadcastInfo {
  const BroadcastInfo({
    required this.status,
    required this.shouldRefreshVideos,
    this.lastSavedPath,
    this.lastError,
  });

  final String status;
  final bool shouldRefreshVideos;
  final String? lastSavedPath;
  final String? lastError;

  bool get isBroadcastActive {
    return status == 'recording' ||
        status == 'paused' ||
        status == 'saving' ||
        status == 'requested';
  }
}

class ReplayKitService {
  static const MethodChannel _channel = MethodChannel('xrecorder/replaykit');

  Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    try {
      final available = await _channel.invokeMethod<bool>('isReplayKitAvailable');
      return available ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isSimulator() async {
    if (!Platform.isIOS) return false;
    try {
      final value = await _channel.invokeMethod<bool>('isSimulator');
      return value ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> isScreenRecordingActive() async {
    if (!Platform.isIOS) return false;
    try {
      final active = await _channel.invokeMethod<bool>('isScreenRecordingActive');
      return active ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> isBroadcastRecordingActive() async {
    final info = await getBroadcastInfo();
    return info.isBroadcastActive;
  }

  Future<void> startAppOnlyRecording() async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod('startScreenRecording');
  }

  Future<String?> stopAppOnlyRecording() async {
    if (!Platform.isIOS) return null;
    final path = await _channel.invokeMethod<String>('stopScreenRecording');
    return path;
  }

  Future<void> showBroadcastPicker() async {
    if (!Platform.isIOS) return;
    await _channel.invokeMethod('showBroadcastPicker');
  }

  Future<String> getBroadcastStatus() async {
    if (!Platform.isIOS) return 'idle';
    try {
      final status = await _channel.invokeMethod<String>('getBroadcastStatus');
      return status ?? 'idle';
    } on MissingPluginException {
      return 'idle';
    } on PlatformException {
      return 'idle';
    }
  }

  Future<BroadcastInfo> getBroadcastInfo() async {
    if (!Platform.isIOS) {
      return const BroadcastInfo(status: 'idle', shouldRefreshVideos: false);
    }
    try {
      final raw = await _channel.invokeMethod<Object?>('getBroadcastInfo');
      if (raw is! Map) {
        return const BroadcastInfo(status: 'idle', shouldRefreshVideos: false);
      }
      final map = Map<Object?, Object?>.from(raw);
      final status = map['status']?.toString() ?? 'idle';
      final shouldRefresh = map['shouldRefreshVideos'] == true;
      final path = map['lastSavedPath']?.toString();
      final error = map['lastError']?.toString();
      return BroadcastInfo(
        status: status,
        shouldRefreshVideos: shouldRefresh,
        lastSavedPath: path != null && path.isNotEmpty ? path : null,
        lastError: error != null && error.isNotEmpty ? error : null,
      );
    } on MissingPluginException {
      return const BroadcastInfo(status: 'idle', shouldRefreshVideos: false);
    } on PlatformException {
      return const BroadcastInfo(status: 'idle', shouldRefreshVideos: false);
    }
  }

  Future<bool> importPendingBroadcastRecording() async {
    if (!Platform.isIOS) return false;
    try {
      final imported = await _channel.invokeMethod<bool>('importPendingBroadcastRecording');
      return imported ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> consumeVideosRefreshFlag() async {
    if (!Platform.isIOS) return false;
    try {
      final value = await _channel.invokeMethod<bool>('consumeVideosRefreshFlag');
      return value ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> setBroadcastStatus(String status) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('setBroadcastStatus', {'status': status});
    } on MissingPluginException {
      // No-op fallback.
    }
  }

  Future<void> setBroadcastAudioMode(BroadcastAudioTestMode mode) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('setBroadcastAudioMode', {'mode': mode.value});
    } on MissingPluginException {
      // No-op fallback.
    }
  }

  Future<BroadcastAudioDebugReport> getBroadcastAudioDebugReport({String? mp4Path}) async {
    if (!Platform.isIOS) {
      return BroadcastAudioDebugReport.fromMap(const {});
    }
    try {
      final raw = await _channel.invokeMethod<Object?>(
        'getBroadcastAudioDebugReport',
        mp4Path != null ? {'mp4Path': mp4Path} : null,
      );
      if (raw is Map) {
        return BroadcastAudioDebugReport.fromMap(Map<Object?, Object?>.from(raw));
      }
    } on MissingPluginException {
      // Fall through.
    } on PlatformException {
      // Fall through.
    }
    return BroadcastAudioDebugReport.fromMap(const {});
  }
}
