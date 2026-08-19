import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/presentation/auth/auth_selection.dart';
import 'package:plenty/presentation/home/home_screen.dart';
import 'package:plenty/presentation/onboarding/add_first_plant_cta_screen.dart';
import 'package:plenty/presentation/onboarding/onboarding_controller.dart';
import 'package:plenty/presentation/onboarding/widgets/environment_step.dart';
import 'package:plenty/presentation/onboarding/widgets/experience_step.dart';
import 'package:plenty/presentation/onboarding/widgets/time_commitment_step.dart';

/// 3-step onboarding preferences flow connected to [OnboardingController].
///
/// Each step persists the user's answer to SQLite via [UserRepository].
/// After step 3, navigates to [AddFirstPlantCtaScreen] where the user
/// can choose to add their first plant or skip to Home.
class PreferencesFlowScreen extends ConsumerStatefulWidget {
  const PreferencesFlowScreen({super.key});

  @override
  ConsumerState<PreferencesFlowScreen> createState() =>
      _PreferencesFlowScreenState();
}

class _PreferencesFlowScreenState extends ConsumerState<PreferencesFlowScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const int _totalSteps = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Advances to the next page, or finishes if on the last step.
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
    final controller = ref.read(onboardingControllerProvider.notifier);
    await controller.completeOnboarding();
    PreferenceHandler.setOnboard(true);

    if (!mounted) return;

    context.pushAndRemoveAll(
      Scaffold(
        backgroundColor: AppColors.canvasDefault,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AuthSelection(),
            // child: AddFirstPlantCtaScreen(
            //   onAddFirstPlant: () {
            //     context.pushReplacement(
            //       const AddPlantFlowScreen(
            //         entryPoint: AddPlantEntryPoint.onboarding,
            //       ),
            //     );
            //   },
            //   onSkip: () {
            //     context.pushAndRemoveAll(const HomeScreen());
            //   },
            // ),
          ),
        ),
      ),
    );
  }

  Future<void> _skipOnboarding() async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    await controller.completeOnboarding();
    PreferenceHandler.setOnboard(true);

    if (!mounted) return;
    context.pushAndRemoveAll(const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

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
                    // Step 1: Experience Level
                    ExperienceStep(
                      selectedExperience: onboardingState.experienceLevel,
                      onSelected: (val) {
                        controller.setExperienceLevel(val);
                        _nextPage();
                      },
                    ),
                    // Step 2: Daily Time Commitment
                    TimeCommitmentStep(
                      timeCommitment: onboardingState.dailyTimeMinutes,
                      onChanged: (val) {
                        controller.setDailyTimeMinutes(val);
                      },
                    ),
                    // Step 3: Environment Safety (Pets & Kids)
                    EnvironmentStep(
                      hasPets: onboardingState.hasPets,
                      hasKids: onboardingState.hasKids,
                      onPetsChanged: (val) {
                        controller.setEnvironmentSafety(hasPets: val);
                      },
                      onKidsChanged: (val) {
                        controller.setEnvironmentSafety(hasKids: val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_currentIndex > 0)
                CustomButton(
                  text: _currentIndex == _totalSteps - 1 ? 'Selesai' : 'Lanjut',
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
  }
}
