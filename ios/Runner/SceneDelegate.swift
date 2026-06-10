import Flutter
import UIKit
import ReplayKit
import Photos

class SceneDelegate: FlutterSceneDelegate {
  private let replayKitChannelName = "xrecorder/replaykit"
  private let replayKitExtensionBundleIdKey = "ReplayKitBroadcastExtensionBundleId"
  private let appGroupId = "group.com.xrecorder.screenvideo.shared"
  private let broadcastStatusKey = "replaykit_broadcast_status"
  private let lastSavedPathKey = "replaykit_last_saved_path"
  private let shouldRefreshVideosKey = "replaykit_should_refresh_videos"
  private let lastErrorKey = "replaykit_last_error"
  private let photosChannelName = "xrecorder/photos"
  private var replayKitChannel: FlutterMethodChannel?
  private var photosChannel: FlutterMethodChannel?
  private var inAppRecordingActive = false
  private var isImportingBroadcastVideo = false

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    configureReplayKitChannelIfNeeded()
    configurePhotosChannelIfNeeded()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    configureReplayKitChannelIfNeeded()
    configurePhotosChannelIfNeeded()
    importPendingBroadcastVideoIfNeeded { _ in }
  }

  private func configureReplayKitChannelIfNeeded() {
    if replayKitChannel != nil { return }
    guard let flutterController = window?.rootViewController as? FlutterViewController else { return }

    let channel = FlutterMethodChannel(
      name: replayKitChannelName,
      binaryMessenger: flutterController.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "showBroadcastPicker":
        self.showBroadcastPicker(result: result)
      case "isReplayKitAvailable":
        result(self.isReplayKitRuntimeAvailable())
      case "isSimulator":
        #if targetEnvironment(simulator)
        result(true)
        #else
        result(false)
        #endif
      case "getBroadcastStatus":
        result(self.getBroadcastStatus())
      case "getBroadcastInfo":
        result(self.getBroadcastInfo())
      case "importPendingBroadcastRecording":
        self.importPendingBroadcastVideoIfNeeded { imported in
          DispatchQueue.main.async {
            result(imported)
          }
        }
      case "consumeVideosRefreshFlag":
        result(self.consumeVideosRefreshFlag())
      case "setBroadcastStatus":
        if let args = call.arguments as? [String: Any],
           let status = args["status"] as? String {
          self.setBroadcastStatus(status)
          result(true)
        } else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing status argument",
              details: nil
            )
          )
        }
      case "isScreenRecordingActive":
        result(self.isAnyRecordingActive())
      case "isBroadcastRecordingActive":
        result(self.isBroadcastRecordingActive())
      case "startScreenRecording":
        self.startScreenRecording(result: result)
      case "stopScreenRecording":
        self.stopScreenRecording(result: result)
      case "setBroadcastAudioMode":
        if let args = call.arguments as? [String: Any],
           let mode = args["mode"] as? String {
          BroadcastAudioDebugReader.setBroadcastAudioMode(mode)
          result(true)
        } else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing mode argument (micOnly | appAudioOnly)",
              details: nil
            )
          )
        }
      case "getBroadcastAudioDebugReport":
        let path = (call.arguments as? [String: Any])?["mp4Path"] as? String
        result(BroadcastAudioDebugReader.reportDictionary(revalidateMp4AtPath: path))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    replayKitChannel = channel
  }

  private func configurePhotosChannelIfNeeded() {
    if photosChannel != nil { return }
    guard let flutterController = window?.rootViewController as? FlutterViewController else { return }

    let channel = FlutterMethodChannel(
      name: photosChannelName,
      binaryMessenger: flutterController.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "openPhotosApp":
        self.openPhotosApp(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    photosChannel = channel
  }

  private func openPhotosApp(result: @escaping FlutterResult) {
    guard let url = URL(string: "photos-redirect://") else {
      result(false)
      return
    }
    if UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, options: [:]) { success in
        DispatchQueue.main.async {
          result(success)
        }
      }
    } else {
      result(false)
    }
  }

  private func isReplayKitRuntimeAvailable() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    return RPScreenRecorder.shared().isAvailable
    #endif
  }

  private func isBroadcastRecordingActive() -> Bool {
    switch getBroadcastStatus() {
    case "recording", "paused", "saving", "requested":
      return true
    default:
      return false
    }
  }

  private func isAnyRecordingActive() -> Bool {
    inAppRecordingActive || isBroadcastRecordingActive()
  }

  private func startScreenRecording(result: @escaping FlutterResult) {
    #if targetEnvironment(simulator)
    result(
      FlutterError(
        code: "SIMULATOR",
        message: "Screen recording is not supported on the iOS Simulator. Use a physical iPhone.",
        details: nil
      )
    )
    return
    #endif

    if isBroadcastRecordingActive() {
      result(
        FlutterError(
          code: "BROADCAST_ACTIVE",
          message: "Stop the broadcast recording before starting in-app recording.",
          details: nil
        )
      )
      return
    }

    let recorder = RPScreenRecorder.shared()
    guard recorder.isAvailable else {
      result(
        FlutterError(
          code: "UNAVAILABLE",
          message: "Screen recorder is not available on this device.",
          details: nil
        )
      )
      return
    }

    recorder.isMicrophoneEnabled = true
    recorder.startRecording { [weak self] error in
      DispatchQueue.main.async {
        guard let self else { return }
        if let error {
          result(
            FlutterError(
              code: "START_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }
        self.inAppRecordingActive = true
        result(true)
      }
    }
  }

  private func stopScreenRecording(result: @escaping FlutterResult) {
    guard #available(iOS 14.0, *) else {
      result(
        FlutterError(
          code: "IOS_VERSION",
          message: "Stopping and saving recordings requires iOS 14 or later.",
          details: nil
        )
      )
      return
    }

    guard inAppRecordingActive else {
      result(
        FlutterError(
          code: "NOT_RECORDING",
          message: "No in-app recording session is active.",
          details: nil
        )
      )
      return
    }

    let outputURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("xrecorder-\(Int(Date().timeIntervalSince1970)).mp4")

    RPScreenRecorder.shared().stopRecording(withOutput: outputURL) { [weak self] error in
      guard let self else { return }
      self.inAppRecordingActive = false

      if let error {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "STOP_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
        return
      }

      self.saveVideoToPhotos(outputURL: outputURL) { saveError in
        DispatchQueue.main.async {
          if let saveError {
            result(
              FlutterError(
                code: "SAVE_FAILED",
                message: saveError.localizedDescription,
                details: nil
              )
            )
          } else {
            result(outputURL.path)
          }
        }
      }
    }
  }

  private func saveVideoToPhotos(outputURL: URL, completion: @escaping (Error?) -> Void) {
    guard #available(iOS 14.0, *) else {
      completion(
        NSError(
          domain: "XRecorder",
          code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Saving videos requires iOS 14 or later."]
        )
      )
      return
    }

    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else {
        completion(
          NSError(
            domain: "XRecorder",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Photos permission denied."]
          )
        )
        return
      }

      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
      }, completionHandler: { success, error in
        try? FileManager.default.removeItem(at: outputURL)
        if success {
          completion(nil)
        } else {
          completion(error)
        }
      })
    }
  }

  private func showBroadcastPicker(result: @escaping FlutterResult) {
    if inAppRecordingActive {
      result(
        FlutterError(
          code: "IN_APP_ACTIVE",
          message: "Stop in-app recording before starting a full-device broadcast.",
          details: nil
        )
      )
      return
    }

    guard #available(iOS 12.0, *) else {
      result(
        FlutterError(
          code: "UNSUPPORTED_IOS",
          message: "ReplayKit broadcast requires iOS 12.0+.",
          details: nil
        )
      )
      return
    }

    #if targetEnvironment(simulator)
    result(
      FlutterError(
        code: "SIMULATOR",
        message: "Broadcast recording requires a physical iPhone.",
        details: nil
      )
    )
    return
    #endif

    DispatchQueue.main.async {
      guard let window = self.window else {
        result(
          FlutterError(
            code: "NO_ACTIVE_WINDOW",
            message: "No active window found for ReplayKit picker.",
            details: nil
          )
        )
        return
      }

      let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
      picker.showsMicrophoneButton = true
      picker.preferredExtension = Bundle.main.object(
        forInfoDictionaryKey: self.replayKitExtensionBundleIdKey
      ) as? String
      picker.alpha = 0.01
      window.addSubview(picker)
      picker.layoutIfNeeded()

      if let button = self.findBroadcastButton(in: picker) {
        button.sendActions(for: .touchUpInside)
        self.setBroadcastStatus("requested")
        result(true)
      } else {
        picker.removeFromSuperview()
        result(
          FlutterError(
            code: "PICKER_BUTTON_NOT_FOUND",
            message: "Could not open the iOS broadcast picker UI.",
            details: nil
          )
        )
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        picker.removeFromSuperview()
      }
    }
  }

  private func findBroadcastButton(in view: UIView) -> UIButton? {
    if let button = view as? UIButton { return button }
    for subview in view.subviews {
      if let button = findBroadcastButton(in: subview) { return button }
    }
    return nil
  }

  private func sharedDefaults() -> UserDefaults? {
    UserDefaults(suiteName: appGroupId)
  }

  private func getBroadcastStatus() -> String {
    guard let sharedDefaults = sharedDefaults() else { return "idle" }
    return sharedDefaults.string(forKey: broadcastStatusKey) ?? "idle"
  }

  private func getBroadcastInfo() -> [String: Any] {
    guard let sharedDefaults = sharedDefaults() else {
      return [
        "status": "idle",
        "shouldRefreshVideos": false,
        "lastSavedPath": "",
        "lastError": "",
      ]
    }
    return [
      "status": sharedDefaults.string(forKey: broadcastStatusKey) ?? "idle",
      "shouldRefreshVideos": sharedDefaults.bool(forKey: shouldRefreshVideosKey),
      "lastSavedPath": sharedDefaults.string(forKey: lastSavedPathKey) ?? "",
      "lastError": sharedDefaults.string(forKey: lastErrorKey) ?? "",
    ]
  }

  private func consumeVideosRefreshFlag() -> Bool {
    guard let sharedDefaults = sharedDefaults() else { return false }
    let shouldRefresh = sharedDefaults.bool(forKey: shouldRefreshVideosKey)
    if shouldRefresh {
      sharedDefaults.set(false, forKey: shouldRefreshVideosKey)
      sharedDefaults.synchronize()
    }
    return shouldRefresh
  }

  private func setBroadcastStatus(_ status: String) {
    guard let sharedDefaults = sharedDefaults() else { return }
    sharedDefaults.set(status, forKey: broadcastStatusKey)
    sharedDefaults.synchronize()
  }

  private func importPendingBroadcastVideoIfNeeded(completion: ((Bool) -> Void)? = nil) {
    guard let sharedDefaults = sharedDefaults() else {
      completion?(false)
      return
    }

    let status = sharedDefaults.string(forKey: broadcastStatusKey) ?? "idle"
    guard status == "saved_to_container", !isImportingBroadcastVideo else {
      completion?(false)
      return
    }

    let path = sharedDefaults.string(forKey: lastSavedPathKey) ?? ""
    guard !path.isEmpty else {
      completion?(false)
      return
    }

    let fileURL = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      sharedDefaults.set("error", forKey: broadcastStatusKey)
      sharedDefaults.set("Pending recording file was not found.", forKey: lastErrorKey)
      sharedDefaults.synchronize()
      completion?(false)
      return
    }

    isImportingBroadcastVideo = true
    saveVideoToPhotos(outputURL: fileURL) { error in
      if let error {
        sharedDefaults.set("error", forKey: self.broadcastStatusKey)
        sharedDefaults.set(error.localizedDescription, forKey: self.lastErrorKey)
        sharedDefaults.synchronize()
        self.isImportingBroadcastVideo = false
        completion?(false)
        return
      }

      try? FileManager.default.removeItem(at: fileURL)
      sharedDefaults.set("saved", forKey: self.broadcastStatusKey)
      sharedDefaults.removeObject(forKey: self.lastErrorKey)
      sharedDefaults.set(true, forKey: self.shouldRefreshVideosKey)
      sharedDefaults.synchronize()
      _ = BroadcastAudioDebugReader.reportDictionary(revalidateMp4AtPath: fileURL.path)
      self.isImportingBroadcastVideo = false
      completion?(true)
    }
  }
}
