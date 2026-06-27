import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:photo_manager/photo_manager.dart';

import 'photos_permission_service.dart';
import 'replaykit_service.dart';

class RecordingResult {
  const RecordingResult({
    required this.success,
    this.filePath,
    this.error,
  });

  final bool success;
  final String? filePath;
  final String? error;
}

class RecordingService {
  final ReplayKitService _replayKitService = ReplayKitService();
  bool _appOnlyRecording = false;

  bool get isRecording => _appOnlyRecording;

  Future<bool> requestMediaPermissions() async {
    PhotosPermissionService.unlockLibraryBrowse();
    return PhotosPermissionService.requestAccess();
  }

  /// iOS: opens Apple's broadcast picker for full-device recording.
  /// Android: starts screen recording plugin.
  Future<RecordingResult> startFullDeviceRecording() async {
    try {
      if (Platform.isIOS) {
        final isSimulator = await _replayKitService.isSimulator();
        if (isSimulator) {
          return const RecordingResult(
            success: false,
            error:
                'Full-device recording does not work on the iOS Simulator. Use a physical iPhone.',
          );
        }

        if (_appOnlyRecording) {
          return const RecordingResult(
            success: false,
            error: 'Stop in-app recording before starting a broadcast.',
          );
        }

        final hasAccess = await requestMediaPermissions();
        if (!hasAccess) {
          return const RecordingResult(
            success: false,
            error: 'Photos permission is required to save recordings.',
          );
        }

        await _replayKitService.setBroadcastStatus('requested');
        await _replayKitService.showBroadcastPicker();
        return const RecordingResult(success: true);
      }

      return start();
    } on PlatformException catch (e) {
      return RecordingResult(
        success: false,
        error: e.message ?? e.toString(),
      );
    } catch (e) {
      return RecordingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// iOS: in-app only capture via RPScreenRecorder (optional fallback).
  Future<RecordingResult> startAppOnlyRecording() async {
    try {
      if (!Platform.isIOS) {
        return start();
      }

      final isSimulator = await _replayKitService.isSimulator();
      if (isSimulator) {
        return const RecordingResult(
          success: false,
          error:
              'In-app recording does not work on the iOS Simulator. Use a physical iPhone.',
        );
      }

      if (await _replayKitService.isBroadcastRecordingActive()) {
        return const RecordingResult(
          success: false,
          error: 'Stop the broadcast before starting in-app recording.',
        );
      }

      final hasAccess = await requestMediaPermissions();
      if (!hasAccess) {
        return const RecordingResult(
          success: false,
          error: 'Photos permission is required to save recordings.',
        );
      }

      await _replayKitService.startAppOnlyRecording();
      _appOnlyRecording = true;
      return const RecordingResult(success: true);
    } on PlatformException catch (e) {
      _appOnlyRecording = false;
      return RecordingResult(
        success: false,
        error: e.message ?? e.toString(),
      );
    } catch (e) {
      _appOnlyRecording = false;
      return RecordingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<RecordingResult> start() async {
    try {
      if (Platform.isIOS) {
        return startFullDeviceRecording();
      }

      final hasAccess = await requestMediaPermissions();
      if (!hasAccess) {
        return const RecordingResult(
          success: false,
          error: 'Media permission is required to save recordings.',
        );
      }

      await FlutterScreenRecording.startRecordScreen('NowRecorder');
      _appOnlyRecording = true;
      return const RecordingResult(success: true);
    } on PlatformException catch (e) {
      _appOnlyRecording = false;
      return RecordingResult(
        success: false,
        error: e.message ?? e.toString(),
      );
    } catch (e) {
      _appOnlyRecording = false;
      return RecordingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<RecordingResult> stopAppOnlyRecording() async {
    try {
      if (!Platform.isIOS) {
        return stop();
      }

      if (!_appOnlyRecording) {
        return const RecordingResult(
          success: false,
          error: 'No in-app recording session is active.',
        );
      }

      final path = await _replayKitService.stopAppOnlyRecording();
      _appOnlyRecording = false;
      return RecordingResult(
        success: true,
        filePath: path,
      );
    } on PlatformException catch (e) {
      _appOnlyRecording = false;
      return RecordingResult(
        success: false,
        error: e.message ?? e.toString(),
      );
    } catch (e) {
      _appOnlyRecording = false;
      return RecordingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<RecordingResult> stop() async {
    try {
      if (Platform.isIOS) {
        return stopAppOnlyRecording();
      }

      final outputPath = await FlutterScreenRecording.stopRecordScreen;
      _appOnlyRecording = false;

      if (outputPath.isEmpty) {
        return const RecordingResult(
          success: false,
          error: 'Recording stopped but no output file was returned.',
        );
      }

      final videoFile = File(outputPath);
      if (!videoFile.existsSync()) {
        return RecordingResult(
          success: false,
          filePath: outputPath,
          error: 'Output file was not found on disk.',
        );
      }

      await PhotoManager.editor.saveVideo(videoFile, title: 'NowRecorder');

      return RecordingResult(
        success: true,
        filePath: outputPath,
      );
    } on PlatformException catch (e) {
      _appOnlyRecording = false;
      return RecordingResult(
        success: false,
        error: e.message ?? e.toString(),
      );
    } catch (e) {
      _appOnlyRecording = false;
      return RecordingResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}
