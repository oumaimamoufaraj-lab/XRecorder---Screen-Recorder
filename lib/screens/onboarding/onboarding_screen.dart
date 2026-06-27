import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_design.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/feature_check_item.dart';
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
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentPage + 1}/${onboardingPages.length}',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: palette.textSecondary),
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
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppDesign.radiusSm),
                            gradient: LinearGradient(colors: data.colors),
                          ),
                          child: Icon(data.icon, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          data.title,
                          style: AppDesign.displayTitle(palette.textPrimary),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          data.description,
                          style: AppDesign.subtitle(palette.textSecondary),
                        ),
                        const SizedBox(height: 28),
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
                children: [
                  for (var i = 0; i < onboardingPages.length; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: i < onboardingPages.length - 1 ? 6 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? AppColors.primaryOrange
                              : palette.indicatorInactive,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: page.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                    ),
                  ),
                  child: Text(
                    isLastPage ? 'Get started' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
