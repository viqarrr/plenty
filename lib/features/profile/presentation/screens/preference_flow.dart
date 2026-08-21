import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/features/auth/presentation/screens/auth_selection_screen.dart';
import 'package:plenty/features/garden/presentation/screens/home_screen.dart';
import 'package:plenty/features/profile/presentation/controllers/onboarding_controller.dart';
import 'package:plenty/features/profile/presentation/widgets/environment_step.dart';
import 'package:plenty/features/profile/presentation/widgets/experience_step.dart';
import 'package:plenty/features/profile/presentation/widgets/time_commitment_step.dart';

/// 3-step onboarding preferences flow connected to [OnboardingController].
class PreferencesFlowScreen extends StatefulWidget {
  final OnboardingController? controller;

  const PreferencesFlowScreen({super.key, this.controller});

  @override
  State<PreferencesFlowScreen> createState() => _PreferencesFlowScreenState();
}

class _PreferencesFlowScreenState extends State<PreferencesFlowScreen> {
  late final OnboardingController _controller;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? OnboardingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    await _controller.completeOnboarding();
    await PreferenceHandler.setOnboard(true);

    if (!mounted) return;

    context.pushAndRemoveAll(AuthSelectionScreen());
  }

  Future<void> _skipOnboarding() async {
    await _controller.completeOnboarding();
    await PreferenceHandler.setOnboard(true);

    if (!mounted) return;
    context.pushAndRemoveAll(const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final onboardingState = _controller.state;
        final canProceed =
            _currentIndex != 0 || onboardingState.experienceLevel.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.canvasDefault,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: _currentIndex > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: _previousPage,
                  )
                : null,
            actions: [
              if (_currentIndex > 0)
                TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Lewati',
                    style: AppTypography.calloutBold.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / _totalSteps,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.forest,
                    backgroundColor: AppColors.borderSubtle,
                  ),
                  const SizedBox(height: 36),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      children: [
                        ExperienceStep(
                          selectedExperience: onboardingState.experienceLevel,
                          onSelected: (val) {
                            _controller.setExperienceLevel(val);
                            _nextPage();
                          },
                        ),
                        TimeCommitmentStep(
                          timeCommitment: onboardingState.dailyTimeMinutes,
                          onChanged: (val) {
                            _controller.setDailyTimeMinutes(val);
                          },
                        ),
                        EnvironmentStep(
                          hasPets: onboardingState.hasPets,
                          hasKids: onboardingState.hasKids,
                          onPetsChanged: (val) {
                            _controller.setEnvironmentSafety(hasPets: val);
                          },
                          onKidsChanged: (val) {
                            _controller.setEnvironmentSafety(hasKids: val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_currentIndex > 0)
                    CustomButton(
                      text: _currentIndex == _totalSteps - 1
                          ? 'Selesai'
                          : 'Lanjut',
                      height: 54,
                      borderRadius: BorderRadius.circular(30),
                      isLoading: onboardingState.isLoading,
                      onPressed: canProceed ? _nextPage : null,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
