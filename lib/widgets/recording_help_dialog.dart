import 'package:flutter/material.dart';

import '../config/recording_help_content.dart';

Future<void> showRecordingHelpDialog(
  BuildContext context, {
  required bool isSimulator,
}) {
  final content = isSimulator
      ? RecordingHelpContent.simulatorNote
      : RecordingHelpContent.iosSteps;

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('How to record'),
      content: SingleChildScrollView(child: Text(content)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
