import 'package:flutter/material.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.features,
    required this.icon,
    required this.colors,
    required this.accentColor,
  });

  final String title;
  final String description;
  final List<String> features;
  final IconData icon;
  final List<Color> colors;
  final Color accentColor;
}

const onboardingPages = [
  OnboardingPageData(
    title: 'Welcome to XRecorder',
    description:
        'Record your screen with one tap, then manage clips in your Videos library.',
    features: [
      'Full-device screen recording',
      'Saved to Photos automatically',
      'Play, share, and organize',
    ],
    icon: Icons.videocam_rounded,
    colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
    accentColor: Color(0xFFFF5722),
  ),
  OnboardingPageData(
    title: 'Screen Recording',
    description:
        'Start Recording opens Apple’s broadcast picker. Turn the microphone on in Apple’s sheet for audio.',
    features: [
      'Apple broadcast picker',
      'Microphone for audio',
      'Optional in-app recording',
    ],
    icon: Icons.fiber_manual_record_rounded,
    colors: [Color(0xFF80CBC4), Color(0xFF4DB6AC)],
    accentColor: Color(0xFF4DB6AC),
  ),
  OnboardingPageData(
    title: 'Videos & Tools',
    description:
        'Browse recordings in Videos. Use Video Info to inspect a clip. More tools will arrive in future updates.',
    features: [
      'Thumbnails and quick actions',
      'Video Info details',
      'Pull to refresh',
    ],
    icon: Icons.video_library_rounded,
    colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
    accentColor: Color(0xFFF57C00),
  ),
];
