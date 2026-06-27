import 'package:flutter/material.dart';

enum RecordingPreset {
  standard,
  tutorial,
  support,
  personal,
}

extension RecordingPresetDetails on RecordingPreset {
  String get label => switch (this) {
        RecordingPreset.standard => 'Standard',
        RecordingPreset.tutorial => 'Tutorial',
        RecordingPreset.support => 'Support',
        RecordingPreset.personal => 'Personal',
      };

  String get hint => switch (this) {
        RecordingPreset.standard => 'Record normally, protect before sharing',
        RecordingPreset.tutorial =>
          'Great for guides — scan for notifications after recording',
        RecordingPreset.support =>
          'Bug reports — blur emails and account info before sharing',
        RecordingPreset.personal =>
          'Chats and messages — use Privacy Studio before sharing',
      };

  IconData get icon => switch (this) {
        RecordingPreset.standard => Icons.videocam_outlined,
        RecordingPreset.tutorial => Icons.school_outlined,
        RecordingPreset.support => Icons.support_agent_outlined,
        RecordingPreset.personal => Icons.lock_person_outlined,
      };
}
