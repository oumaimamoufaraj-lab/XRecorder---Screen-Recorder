import AVFoundation
import Foundation

/// App Group keys shared with the main app (Runner reads the same strings).
enum BroadcastAudioDebugKeys {
  static let appGroupId = "group.com.xrecorder.screenVideo"
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

enum BroadcastAudioMode: String {
  case micOnly
  case appAudioOnly
}

final class BroadcastAudioDebugReporter {
  static let shared = BroadcastAudioDebugReporter()

  private var defaults: UserDefaults? {
    UserDefaults(suiteName: BroadcastAudioDebugKeys.appGroupId)
  }

  private(set) var mode: BroadcastAudioMode = .micOnly
  private(set) var receivedAudioApp = false
  private(set) var receivedAudioMic = false
  private(set) var audioAppBufferCount = 0
  private(set) var audioMicBufferCount = 0
  private(set) var audioAppendSuccessCount = 0
  private(set) var audioAppendFailedCount = 0
  private(set) var audioAppendNotReadyCount = 0
  private(set) var audioTrackConfigured = false
  private(set) var sessionStarted = false
  private(set) var videoFrameCount = 0

  private init() {}

  func resetForNewBroadcast() {
    mode = readModeFromAppGroup()
    receivedAudioApp = false
    receivedAudioMic = false
    audioAppBufferCount = 0
    audioMicBufferCount = 0
    audioAppendSuccessCount = 0
    audioAppendFailedCount = 0
    audioAppendNotReadyCount = 0
    audioTrackConfigured = false
    sessionStarted = false
    videoFrameCount = 0
    persistSnapshot(
      writerStatus: "not_started",
      writerError: "",
      mp4HasAudioTrack: false,
      mp4Path: ""
    )
  }

  func readModeFromAppGroup() -> BroadcastAudioMode {
    guard let raw = defaults?.string(forKey: BroadcastAudioDebugKeys.audioMode),
          let mode = BroadcastAudioMode(rawValue: raw) else {
      return .micOnly
    }
    return mode
  }

  func recordVideoFrame() {
    videoFrameCount += 1
    defaults?.set(videoFrameCount, forKey: BroadcastAudioDebugKeys.videoFrameCount)
    defaults?.synchronize()
  }

  func recordAppAudioBufferReceived() {
    receivedAudioApp = true
    audioAppBufferCount += 1
    defaults?.set(true, forKey: BroadcastAudioDebugKeys.receivedAudioApp)
    defaults?.set(audioAppBufferCount, forKey: BroadcastAudioDebugKeys.audioAppBufferCount)
    defaults?.synchronize()
  }

  func recordMicAudioBufferReceived() {
    receivedAudioMic = true
    audioMicBufferCount += 1
    defaults?.set(true, forKey: BroadcastAudioDebugKeys.receivedAudioMic)
    defaults?.set(audioMicBufferCount, forKey: BroadcastAudioDebugKeys.audioMicBufferCount)
    defaults?.synchronize()
  }

  func recordAudioTrackConfigured() {
    audioTrackConfigured = true
    defaults?.set(true, forKey: BroadcastAudioDebugKeys.audioTrackConfigured)
    defaults?.synchronize()
  }

  func recordSessionStarted() {
    sessionStarted = true
    defaults?.set(true, forKey: BroadcastAudioDebugKeys.sessionStarted)
    defaults?.synchronize()
  }

  func recordAudioAppendSuccess() {
    audioAppendSuccessCount += 1
    defaults?.set(audioAppendSuccessCount, forKey: BroadcastAudioDebugKeys.audioAppendSuccessCount)
    defaults?.synchronize()
  }

  func recordAudioAppendFailed() {
    audioAppendFailedCount += 1
    defaults?.set(audioAppendFailedCount, forKey: BroadcastAudioDebugKeys.audioAppendFailedCount)
    defaults?.synchronize()
  }

  func recordAudioAppendNotReady() {
    audioAppendNotReadyCount += 1
    defaults?.set(audioAppendNotReadyCount, forKey: BroadcastAudioDebugKeys.audioAppendNotReadyCount)
    defaults?.synchronize()
  }

  func finalizeReport(writer: AVAssetWriter?, outputURL: URL?) {
    let status = writerStatusString(writer)
    let error = writer?.error?.localizedDescription ?? ""
    let path = outputURL?.path ?? ""
    let hasAudio = Self.mp4ContainsAudioTrack(at: outputURL)
    persistSnapshot(
      writerStatus: status,
      writerError: error,
      mp4HasAudioTrack: hasAudio,
      mp4Path: path
    )
  }

  private func writerStatusString(_ writer: AVAssetWriter?) -> String {
    guard let writer else { return "no_writer" }
    switch writer.status {
    case .unknown: return "unknown"
    case .writing: return "writing"
    case .completed: return "completed"
    case .failed: return "failed"
    case .cancelled: return "cancelled"
    @unknown default: return "unknown_default"
    }
  }

  static func mp4ContainsAudioTrack(at url: URL?) -> Bool {
    guard let url, FileManager.default.fileExists(atPath: url.path) else { return false }
    let asset = AVURLAsset(url: url)
    return !asset.tracks(withMediaType: .audio).isEmpty
  }

  private func persistSnapshot(
    writerStatus: String,
    writerError: String,
    mp4HasAudioTrack: Bool,
    mp4Path: String
  ) {
    guard let defaults else { return }
    defaults.set(mode.rawValue, forKey: BroadcastAudioDebugKeys.audioMode)
    defaults.set(receivedAudioApp, forKey: BroadcastAudioDebugKeys.receivedAudioApp)
    defaults.set(receivedAudioMic, forKey: BroadcastAudioDebugKeys.receivedAudioMic)
    defaults.set(audioAppBufferCount, forKey: BroadcastAudioDebugKeys.audioAppBufferCount)
    defaults.set(audioMicBufferCount, forKey: BroadcastAudioDebugKeys.audioMicBufferCount)
    defaults.set(audioAppendSuccessCount, forKey: BroadcastAudioDebugKeys.audioAppendSuccessCount)
    defaults.set(audioAppendFailedCount, forKey: BroadcastAudioDebugKeys.audioAppendFailedCount)
    defaults.set(audioAppendNotReadyCount, forKey: BroadcastAudioDebugKeys.audioAppendNotReadyCount)
    defaults.set(writerStatus, forKey: BroadcastAudioDebugKeys.writerFinalStatus)
    defaults.set(writerError, forKey: BroadcastAudioDebugKeys.writerError)
    defaults.set(mp4HasAudioTrack, forKey: BroadcastAudioDebugKeys.mp4HasAudioTrack)
    defaults.set(audioTrackConfigured, forKey: BroadcastAudioDebugKeys.audioTrackConfigured)
    defaults.set(sessionStarted, forKey: BroadcastAudioDebugKeys.sessionStarted)
    defaults.set(videoFrameCount, forKey: BroadcastAudioDebugKeys.videoFrameCount)
    defaults.set(mp4Path, forKey: BroadcastAudioDebugKeys.lastMp4Path)
    defaults.synchronize()
  }

  static func dictionaryFromAppGroup() -> [String: Any] {
    guard let defaults = UserDefaults(suiteName: BroadcastAudioDebugKeys.appGroupId) else {
      return [:]
    }
    return [
      "audioMode": defaults.string(forKey: BroadcastAudioDebugKeys.audioMode) ?? "micOnly",
      "receivedAudioApp": defaults.bool(forKey: BroadcastAudioDebugKeys.receivedAudioApp),
      "receivedAudioMic": defaults.bool(forKey: BroadcastAudioDebugKeys.receivedAudioMic),
      "audioAppBufferCount": defaults.integer(forKey: BroadcastAudioDebugKeys.audioAppBufferCount),
      "audioMicBufferCount": defaults.integer(forKey: BroadcastAudioDebugKeys.audioMicBufferCount),
      "audioAppendSuccessCount": defaults.integer(forKey: BroadcastAudioDebugKeys.audioAppendSuccessCount),
      "audioAppendFailedCount": defaults.integer(forKey: BroadcastAudioDebugKeys.audioAppendFailedCount),
      "audioAppendNotReadyCount": defaults.integer(forKey: BroadcastAudioDebugKeys.audioAppendNotReadyCount),
      "writerFinalStatus": defaults.string(forKey: BroadcastAudioDebugKeys.writerFinalStatus) ?? "",
      "writerError": defaults.string(forKey: BroadcastAudioDebugKeys.writerError) ?? "",
      "mp4HasAudioTrack": defaults.bool(forKey: BroadcastAudioDebugKeys.mp4HasAudioTrack),
      "audioTrackConfigured": defaults.bool(forKey: BroadcastAudioDebugKeys.audioTrackConfigured),
      "sessionStarted": defaults.bool(forKey: BroadcastAudioDebugKeys.sessionStarted),
      "videoFrameCount": defaults.integer(forKey: BroadcastAudioDebugKeys.videoFrameCount),
      "lastMp4Path": defaults.string(forKey: BroadcastAudioDebugKeys.lastMp4Path) ?? "",
    ]
  }
}
