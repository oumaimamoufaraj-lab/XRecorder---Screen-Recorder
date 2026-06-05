import AVFoundation
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
  private let appGroupId = "group.com.xrecorder.screenVideo"
  private let statusKey = "replaykit_broadcast_status"
  private let lastSavedPathKey = "replaykit_last_saved_path"
  private let shouldRefreshVideosKey = "replaykit_should_refresh_videos"
  private let lastErrorKey = "replaykit_last_error"

  private let videoWriter = BroadcastVideoWriter()

  private func sharedDefaults() -> UserDefaults? {
    UserDefaults(suiteName: appGroupId)
  }

  private func updateShared(status: String, path: String? = nil, error: String? = nil, refresh: Bool = false) {
    guard let defaults = sharedDefaults() else { return }
    defaults.set(status, forKey: statusKey)
    if let path {
      defaults.set(path, forKey: lastSavedPathKey)
    }
    if let error {
      defaults.set(error, forKey: lastErrorKey)
    } else {
      defaults.removeObject(forKey: lastErrorKey)
    }
    if refresh {
      defaults.set(true, forKey: shouldRefreshVideosKey)
    }
    defaults.synchronize()
  }

  override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
    guard let containerURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupId
    ) else {
      updateShared(status: "error", error: "App Group container unavailable.")
      return
    }

    do {
      BroadcastAudioDebugReporter.shared.resetForNewBroadcast()
      _ = try videoWriter.prepareOutputFile(in: containerURL)
      updateShared(status: "recording")
    } catch {
      updateShared(status: "error", error: error.localizedDescription)
      finishBroadcastWithError(error)
    }
  }

  override func broadcastPaused() {
    updateShared(status: "paused")
  }

  override func broadcastResumed() {
    updateShared(status: "recording")
  }

  override func broadcastFinished() {
    updateShared(status: "saving")

    let semaphore = DispatchSemaphore(value: 0)
    var finishResult: Result<URL, Error>?

    videoWriter.finish { result in
      finishResult = result
      semaphore.signal()
    }

    _ = semaphore.wait(timeout: .now() + 12)

    guard let result = finishResult else {
      updateShared(status: "error", error: "Timed out while finalizing the recording.")
      return
    }

    switch result {
    case .success(let fileURL):
      persistRecording(at: fileURL)
    case .failure(let error):
      updateShared(status: "error", error: error.localizedDescription)
    }
  }

  override func processSampleBuffer(
    _ sampleBuffer: CMSampleBuffer,
    with sampleBufferType: RPSampleBufferType
  ) {
    videoWriter.append(sampleBuffer, type: sampleBufferType)
  }

  private func persistRecording(at fileURL: URL) {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: fileURL.path) else {
      updateShared(status: "error", error: "Recording file was not found after encoding.")
      return
    }

    guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
          let fileSize = attributes[.size] as? NSNumber,
          fileSize.int64Value > 1024 else {
      updateShared(status: "error", error: "Recording file is empty.")
      return
    }

    // Always keep the MP4 in the App Group; the main app imports it to Photos.
    updateShared(status: "saved_to_container", path: fileURL.path, refresh: true)
  }
}
