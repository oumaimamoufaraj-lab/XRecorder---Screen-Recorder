class BroadcastAudioDebugReport {
  const BroadcastAudioDebugReport({
    required this.audioMode,
    required this.receivedAudioApp,
    required this.receivedAudioMic,
    required this.audioAppBufferCount,
    required this.audioMicBufferCount,
    required this.audioAppendSuccessCount,
    required this.audioAppendFailedCount,
    required this.audioAppendNotReadyCount,
    required this.writerFinalStatus,
    required this.writerError,
    required this.mp4HasAudioTrack,
    required this.audioTrackConfigured,
    required this.sessionStarted,
    required this.videoFrameCount,
    required this.lastMp4Path,
  });

  final String audioMode;
  final bool receivedAudioApp;
  final bool receivedAudioMic;
  final int audioAppBufferCount;
  final int audioMicBufferCount;
  final int audioAppendSuccessCount;
  final int audioAppendFailedCount;
  final int audioAppendNotReadyCount;
  final String writerFinalStatus;
  final String writerError;
  final bool mp4HasAudioTrack;
  final bool audioTrackConfigured;
  final bool sessionStarted;
  final int videoFrameCount;
  final String lastMp4Path;

  factory BroadcastAudioDebugReport.fromMap(Map<Object?, Object?> map) {
    return BroadcastAudioDebugReport(
      audioMode: map['audioMode']?.toString() ?? 'micOnly',
      receivedAudioApp: map['receivedAudioApp'] == true,
      receivedAudioMic: map['receivedAudioMic'] == true,
      audioAppBufferCount: _asInt(map['audioAppBufferCount']),
      audioMicBufferCount: _asInt(map['audioMicBufferCount']),
      audioAppendSuccessCount: _asInt(map['audioAppendSuccessCount']),
      audioAppendFailedCount: _asInt(map['audioAppendFailedCount']),
      audioAppendNotReadyCount: _asInt(map['audioAppendNotReadyCount']),
      writerFinalStatus: map['writerFinalStatus']?.toString() ?? '',
      writerError: map['writerError']?.toString() ?? '',
      mp4HasAudioTrack: map['mp4HasAudioTrack'] == true,
      audioTrackConfigured: map['audioTrackConfigured'] == true,
      sessionStarted: map['sessionStarted'] == true,
      videoFrameCount: _asInt(map['videoFrameCount']),
      lastMp4Path: map['lastMp4Path']?.toString() ?? '',
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  String get summaryText {
    return '''
Broadcast audio debug report
────────────────────────────
Test mode: $audioMode

ReplayKit buffers received:
  audioApp: ${receivedAudioApp ? 'YES' : 'NO'} (count: $audioAppBufferCount)
  audioMic: ${receivedAudioMic ? 'YES' : 'NO'} (count: $audioMicBufferCount)

AVAssetWriter:
  audio track configured: ${audioTrackConfigured ? 'YES' : 'NO'}
  session started: ${sessionStarted ? 'YES' : 'NO'}
  append success: $audioAppendSuccessCount
  append failed: $audioAppendFailedCount
  append not ready (dropped): $audioAppendNotReadyCount
  final status: $writerFinalStatus
  error: ${writerError.isEmpty ? '(none)' : writerError}

Output file:
  video frames: $videoFrameCount
  MP4 has audio track: ${mp4HasAudioTrack ? 'YES' : 'NO'}
  path: ${lastMp4Path.isEmpty ? '(none)' : lastMp4Path}
''';
  }

  String get diagnosisHint {
    if (!receivedAudioApp && !receivedAudioMic) {
      return 'ReplayKit sent NO audio buffers to the extension.';
    }
    if (audioMode == 'appAudioOnly' && !receivedAudioApp) {
      return 'appAudioOnly mode but no audioApp buffers (turn Microphone OFF; play sound from another app).';
    }
    if (audioMode == 'micOnly' && !receivedAudioMic) {
      return 'micOnly mode but no audioMic buffers (turn Microphone ON in Apple broadcast sheet).';
    }
    if ((receivedAudioApp || receivedAudioMic) && !audioTrackConfigured) {
      return 'Audio buffers arrived but AVAssetWriter rejected audio track setup.';
    }
    if (audioTrackConfigured && audioAppendSuccessCount == 0) {
      return 'Audio track exists but no samples were appended (check not-ready/failed counts).';
    }
    if (audioAppendSuccessCount > 0 && !mp4HasAudioTrack) {
      return 'Samples appended but MP4 has no audio track (writer finalize issue).';
    }
    if (audioAppendSuccessCount > 0 && mp4HasAudioTrack) {
      return 'Audio track present in MP4 — if playback is bad, format/codec mismatch is likely.';
    }
    return 'See counts above.';
  }
}

enum BroadcastAudioTestMode {
  appAudioOnly('appAudioOnly'),
  micOnly('micOnly');

  const BroadcastAudioTestMode(this.value);
  final String value;
}
