import AVFoundation
import CoreMedia
import ReplayKit

/// Encodes ReplayKit broadcast sample buffers to MP4 (debug instrumentation included).
final class BroadcastVideoWriter {
  private let debug = BroadcastAudioDebugReporter.shared

  private var assetWriter: AVAssetWriter?
  private var videoInput: AVAssetWriterInput?
  private var audioInput: AVAssetWriterInput?

  private var isWriting = false
  private var videoConfigured = false
  private var audioConfigured = false
  private var sessionStartTime: CMTime?
  private var lastVideoTime: CMTime = .invalid
  private(set) var outputURL: URL?

  private var audioMode: BroadcastAudioMode { debug.readModeFromAppGroup() }

  func prepareOutputFile(in containerURL: URL) throws -> URL {
    let recordingsDir = containerURL.appendingPathComponent("Recordings", isDirectory: true)
    try FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

    let fileURL = recordingsDir.appendingPathComponent(
      "broadcast_\(Int(Date().timeIntervalSince1970)).mp4"
    )
    outputURL = fileURL
    return fileURL
  }

  func append(_ sampleBuffer: CMSampleBuffer, type: RPSampleBufferType) {
    guard CMSampleBufferDataIsReady(sampleBuffer) else { return }

    switch type {
    case .video:
      handleVideo(sampleBuffer)
    case .audioApp:
      handleAppAudio(sampleBuffer)
    case .audioMic:
      handleMicAudio(sampleBuffer)
    @unknown default:
      break
    }
  }

  func finish(completion: @escaping (Result<URL, Error>) -> Void) {
    guard let writer = assetWriter, let url = outputURL else {
      debug.finalizeReport(writer: nil, outputURL: nil)
      completion(
        .failure(
          NSError(
            domain: "NowRecorder",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "No video was written (writer not configured)."]
          )
        )
      )
      return
    }

    if !isWriting {
      if videoConfigured, sessionStartTime != nil {
        startWritingSession()
        flushPendingVideoIfNeeded()
      } else {
        writer.cancelWriting()
        debug.finalizeReport(writer: writer, outputURL: url)
        completion(
          .failure(
            NSError(
              domain: "NowRecorder",
              code: 5,
              userInfo: [NSLocalizedDescriptionKey: "No video frames were captured."]
            )
          )
        )
        return
      }
    }

    if lastVideoTime.isValid {
      writer.endSession(atSourceTime: lastVideoTime)
    }

    videoInput?.markAsFinished()
    if debug.audioAppendSuccessCount > 0 {
      audioInput?.markAsFinished()
    }

    writer.finishWriting { [debug] in
      debug.finalizeReport(writer: writer, outputURL: url)
      if writer.status == .completed {
        completion(.success(url))
      } else {
        completion(
          .failure(
            writer.error ?? NSError(
              domain: "NowRecorder",
              code: 6,
              userInfo: [NSLocalizedDescriptionKey: "Failed to finalize MP4 file."]
            )
          )
        )
      }
    }
  }

  // MARK: - Video

  private var pendingVideoBuffers: [CMSampleBuffer] = []
  private let maxPendingVideoBuffers = 90

  private func handleVideo(_ sampleBuffer: CMSampleBuffer) {
    do {
      if !videoConfigured {
        try configureVideo(with: sampleBuffer)
      }
    } catch {
      assetWriter?.cancelWriting()
      return
    }

    guard let writer = assetWriter, writer.status != .failed, let videoInput else { return }

    debug.recordVideoFrame()
    lastVideoTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

    if !isWriting {
      if audioConfigured {
        startWritingSession()
      } else {
        enqueuePendingVideo(sampleBuffer)
        return
      }
    }

    appendVideoBuffer(sampleBuffer, to: videoInput)
  }

  private func configureVideo(with sampleBuffer: CMSampleBuffer) throws {
    guard let outputURL else {
      throw NSError(
        domain: "NowRecorder",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Output URL was not prepared."]
      )
    }
    guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
      throw NSError(
        domain: "NowRecorder",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Missing video format description."]
      )
    }

    let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
    var width = max(Int(dimensions.width), 2)
    var height = max(Int(dimensions.height), 2)
    if width % 2 != 0 { width -= 1 }
    if height % 2 != 0 { height -= 1 }

    let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    let videoSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: 6_000_000,
        AVVideoMaxKeyFrameIntervalKey: 30,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
      ],
    ]
    let videoIn = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    videoIn.expectsMediaDataInRealTime = true

    guard writer.canAdd(videoIn) else {
      throw writer.error ?? NSError(
        domain: "NowRecorder",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "Cannot add video input to writer."]
      )
    }
    writer.add(videoIn)

    assetWriter = writer
    videoInput = videoIn
    videoConfigured = true
    sessionStartTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
  }

  private func enqueuePendingVideo(_ sampleBuffer: CMSampleBuffer) {
    guard pendingVideoBuffers.count < maxPendingVideoBuffers else { return }
    var copy: CMSampleBuffer?
    guard CMSampleBufferCreateCopy(
      allocator: kCFAllocatorDefault,
      sampleBuffer: sampleBuffer,
      sampleBufferOut: &copy
    ) == noErr, let copy else { return }
    pendingVideoBuffers.append(copy)
  }

  private func flushPendingVideoIfNeeded() {
    guard let videoInput else { return }
    for buffer in pendingVideoBuffers {
      appendVideoBuffer(buffer, to: videoInput)
    }
    pendingVideoBuffers.removeAll()
  }

  private func appendVideoBuffer(_ sampleBuffer: CMSampleBuffer, to videoInput: AVAssetWriterInput) {
    guard videoInput.isReadyForMoreMediaData else { return }
    videoInput.append(sampleBuffer)
  }

  // MARK: - Audio (forced single-source modes)

  private func handleAppAudio(_ sampleBuffer: CMSampleBuffer) {
    guard audioMode == .appAudioOnly else { return }
    guard videoConfigured, let writer = assetWriter, writer.status != .failed else { return }

    debug.recordAppAudioBufferReceived()
    configureAudioIfNeeded(with: sampleBuffer)
    guard audioConfigured, let audioInput else { return }

    if !isWriting {
      startWritingSession()
    }
    appendAudioBuffer(sampleBuffer, to: audioInput)
  }

  private func handleMicAudio(_ sampleBuffer: CMSampleBuffer) {
    guard audioMode == .micOnly else { return }
    guard videoConfigured, let writer = assetWriter, writer.status != .failed else { return }

    debug.recordMicAudioBufferReceived()
    configureAudioIfNeeded(with: sampleBuffer)
    guard audioConfigured, let audioInput else { return }

    if !isWriting {
      startWritingSession()
    }
    appendAudioBuffer(sampleBuffer, to: audioInput)
  }

  private func configureAudioIfNeeded(with sampleBuffer: CMSampleBuffer) {
    guard !audioConfigured, let writer = assetWriter, writer.status == .unknown else { return }
    guard let input = BroadcastAudioTrack.makeWriterInput(
      sampleBuffer: sampleBuffer,
      assetWriter: writer
    ) else { return }
    audioInput = input
    audioConfigured = true
    debug.recordAudioTrackConfigured()
  }

  private func appendAudioBuffer(_ sampleBuffer: CMSampleBuffer, to audioInput: AVAssetWriterInput) {
    guard audioInput.isReadyForMoreMediaData else {
      debug.recordAudioAppendNotReady()
      return
    }
    if audioInput.append(sampleBuffer) {
      debug.recordAudioAppendSuccess()
    } else {
      debug.recordAudioAppendFailed()
    }
  }

  // MARK: - Session

  private func startWritingSession() {
    guard !isWriting,
          let writer = assetWriter,
          let sessionStartTime,
          writer.status == .unknown else { return }

    writer.startWriting()
    writer.startSession(atSourceTime: sessionStartTime)
    isWriting = true
    debug.recordSessionStarted()
    flushPendingVideoIfNeeded()
  }
}
