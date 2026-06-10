/// Shared recording instructions (Settings help, Record tab copy).
abstract final class RecordingHelpContent {
  static const String iosSteps =
      '• Tap Start Recording to open Apple’s broadcast picker.\n\n'
      '• Select XRecorder, turn Microphone ON, then tap Start Broadcast.\n\n'
      '• Stop recording using the red status bar or Control Center.\n\n'
      '• Reopen XRecorder to import and save the clip to Photos.';

  static const String iosHowToStart =
      'Tap Start Recording, select XRecorder in Apple’s broadcast picker, turn Microphone ON, '
      'then tap Start Broadcast. After you stop, reopen XRecorder to save the clip to Photos.';

  static const String iosHowToStop =
      'While broadcasting, stop using the red status bar or Screen Broadcast in Control Center. '
      'Then reopen XRecorder to import and save to Photos.';

  static const String simulatorNote =
      'The iOS Simulator cannot access ReplayKit. Install on a physical iPhone to record.';
}
