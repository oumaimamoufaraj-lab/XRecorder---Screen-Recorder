import 'package:flutter/material.dart';

import '../../services/ad_action_service.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/feature_check_item.dart';
import '../../widgets/gradient_icon_box.dart';
import '../../widgets/page_indicator.dart';
import '../home/main_shell.dart';
import 'onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  Future<void> _finish() async {
    await widget.onComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  void _next() {
    if (_currentPage < onboardingPages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = onboardingPages[_currentPage];
    final isLastPage = _currentPage == onboardingPages.length - 1;

    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const Spacer(),
                  PageIndicator(
                    count: onboardingPages.length,
                    currentIndex: _currentPage,
                    activeColor: page.accentColor,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        AdActionService.runWithInterstitial(_finish),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingPages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final data = onboardingPages[index];
                  final isFirstPage = index == 0;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        if (isFirstPage)
                          const BrandLogo(size: 110, radius: 28)
                        else
                          GradientIconBox(
                            icon: data.icon,
                            colors: data.colors,
                            size: 110,
                            iconSize: 48,
                          ),
                        const SizedBox(height: 36),
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ...data.features.map(
                          (feature) => FeatureCheckItem(
                            label: feature,
                            accentColor: data.accentColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.textSecondary,
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  ElevatedButton.icon(
                    onPressed: _next,
                    icon: Icon(
                      isLastPage ? Icons.rocket_launch : Icons.arrow_forward,
                      size: 18,
                    ),
                    label: Text(isLastPage ? 'Get Started' : 'Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: page.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: page.accentColor.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
