/// Shared recording instructions (Settings help, Record tab copy).
abstract final class RecordingHelpContent {
  static const String iosSteps =
      '• Start Recording uses Apple’s broadcast picker.\n\n'
      '• Turn Microphone ON in Apple’s broadcast sheet for audio.\n\n'
      '• Stop recording using the red status bar or Control Center.\n\n'
      '• Reopen the app to import/save the recording.';

  static const String iosHowToStart =
      'Tap Start Recording to open Apple’s broadcast picker. Turn Microphone ON for audio. '
      'After you stop the broadcast, reopen XRecorder to save the clip to Photos.';

  static const String iosHowToStop =
      'While broadcasting, stop using the red status bar or Screen Broadcast in Control Center. '
      'Then reopen XRecorder to import and save to Photos.';

  static const String simulatorNote =
      'The iOS Simulator cannot access ReplayKit. Install on a physical iPhone to record.';
}
