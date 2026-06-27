import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

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
    title: 'Privacy-first recording',
    description:
        'Record your screen on-device — no account, no cloud upload. '
        'Your clips stay in Photos until you choose to share them.',
    features: [
      'Full-device screen recording',
      'Saved locally to Photos',
      'No sign-in required',
    ],
    icon: Icons.shield_outlined,
    colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
    accentColor: AppColors.primaryOrange,
  ),
  OnboardingPageData(
    title: 'Record with confidence',
    description:
        'Start Recording opens Apple’s broadcast picker. Turn the microphone '
        'on in Apple’s sheet when you need audio.',
    features: [
      'Apple broadcast picker',
      'Microphone for audio',
      'Optional in-app recording',
    ],
    icon: Icons.fiber_manual_record_rounded,
    colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
    accentColor: AppColors.splashOrange,
  ),
  OnboardingPageData(
    title: 'Protect in Privacy Studio',
    description:
        'Scan for emails and phone numbers, add blur regions, and export a safe copy — all on your device.',
    features: [
      'Privacy Score scan',
      'Manual blur regions',
      'Safe export to Photos',
    ],
    icon: Icons.verified_user_outlined,
    colors: [Color(0xFFFFAB91), Color(0xFFFF7043)],
    accentColor: AppColors.primaryOrangeLight,
  ),
];
