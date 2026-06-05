import AVFoundation
import CoreMedia

enum BroadcastAudioTrack {
  /// Creates an AAC audio input that matches the ReplayKit sample format.
  static func makeWriterInput(
    sampleBuffer: CMSampleBuffer,
    assetWriter: AVAssetWriter
  ) -> AVAssetWriterInput? {
    guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
      return nil
    }

    let outputSettings = aacOutputSettings(for: formatDescription)
    let input = AVAssetWriterInput(
      mediaType: .audio,
      outputSettings: outputSettings,
      sourceFormatHint: formatDescription
    )
    input.expectsMediaDataInRealTime = true

    guard assetWriter.canAdd(input) else { return nil }
    assetWriter.add(input)
    return input
  }

  private static func aacOutputSettings(for formatDescription: CMFormatDescription) -> [String: Any] {
    if let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
      let asbd = streamDescription.pointee
      let sampleRate = asbd.mSampleRate > 0 ? asbd.mSampleRate : 48_000
      let channels = max(Int(asbd.mChannelsPerFrame), 1)
      return [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: channels,
        AVEncoderBitRateKey: max(64_000, min(192_000, Int(sampleRate) * channels * 8)),
      ]
    }

    return [
      AVFormatIDKey: kAudioFormatMPEG4AAC,
      AVSampleRateKey: 48_000,
      AVNumberOfChannelsKey: 2,
      AVEncoderBitRateKey: 128_000,
    ]
  }
}
