import AVFoundation
import Foundation

/// Reads broadcast audio debug values written by the extension (App Group).
enum BroadcastAudioDebugReader {
  private static let appGroupId = "group.com.xrecorder.screenvideo.shared"

  private enum Key {
    static let audioMode = "replaykit_broadcast_audio_mode"
    static let receivedAudioApp = "replaykit_debug_received_audio_app"
    static let receivedAudioMic = "replaykit_debug_received_audio_mic"
    static let audioAppBufferCount = "replaykit_debug_audio_app_buffer_count"
    static let audioMicBufferCount = "replaykit_debug_audio_mic_buffer_count"
    static let audioAppendSuccessCount = "replaykit_debug_audio_append_success_count"
    static let audioAppendFailedCount = "replaykit_debug_audio_append_failed_count"
    static let audioAppendNotReadyCount = "replaykit_debug_audio_append_not_ready_count"
    static let writerFinalStatus = "replaykit_debug_writer_final_status"
    static let writerError = "replaykit_debug_writer_error"
    static let mp4HasAudioTrack = "replaykit_debug_mp4_has_audio_track"
    static let audioTrackConfigured = "replaykit_debug_audio_track_configured"
    static let sessionStarted = "replaykit_debug_session_started"
    static let videoFrameCount = "replaykit_debug_video_frame_count"
    static let lastMp4Path = "replaykit_debug_last_mp4_path"
  }

  static func setBroadcastAudioMode(_ mode: String) {
    guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
    defaults.set(mode, forKey: Key.audioMode)
    defaults.synchronize()
  }

  static func reportDictionary(revalidateMp4AtPath path: String? = nil) -> [String: Any] {
    guard let defaults = UserDefaults(suiteName: appGroupId) else { return [:] }

    var mp4HasAudio = defaults.bool(forKey: Key.mp4HasAudioTrack)
    let mp4Path = path ?? defaults.string(forKey: Key.lastMp4Path) ?? ""
    if !mp4Path.isEmpty, FileManager.default.fileExists(atPath: mp4Path) {
      let asset = AVURLAsset(url: URL(fileURLWithPath: mp4Path))
      mp4HasAudio = !asset.tracks(withMediaType: .audio).isEmpty
      defaults.set(mp4HasAudio, forKey: Key.mp4HasAudioTrack)
      defaults.synchronize()
    }

    return [
      "audioMode": defaults.string(forKey: Key.audioMode) ?? "micOnly",
      "receivedAudioApp": defaults.bool(forKey: Key.receivedAudioApp),
      "receivedAudioMic": defaults.bool(forKey: Key.receivedAudioMic),
      "audioAppBufferCount": defaults.integer(forKey: Key.audioAppBufferCount),
      "audioMicBufferCount": defaults.integer(forKey: Key.audioMicBufferCount),
      "audioAppendSuccessCount": defaults.integer(forKey: Key.audioAppendSuccessCount),
      "audioAppendFailedCount": defaults.integer(forKey: Key.audioAppendFailedCount),
      "audioAppendNotReadyCount": defaults.integer(forKey: Key.audioAppendNotReadyCount),
      "writerFinalStatus": defaults.string(forKey: Key.writerFinalStatus) ?? "",
      "writerError": defaults.string(forKey: Key.writerError) ?? "",
      "mp4HasAudioTrack": mp4HasAudio,
      "audioTrackConfigured": defaults.bool(forKey: Key.audioTrackConfigured),
      "sessionStarted": defaults.bool(forKey: Key.sessionStarted),
      "videoFrameCount": defaults.integer(forKey: Key.videoFrameCount),
      "lastMp4Path": mp4Path,
    ]
  }
}
