import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/models/user_preference_model.dart';
import 'package:plenty/presentation/auth/auth_selection.dart';
import 'package:plenty/presentation/onboarding/widgets/environment_step.dart';
import 'package:plenty/presentation/onboarding/widgets/experience_step.dart';
import 'package:plenty/presentation/onboarding/widgets/time_commitment_step.dart';

class PreferencesFlowScreen extends StatefulWidget {
  const PreferencesFlowScreen({super.key});

  @override
  State<PreferencesFlowScreen> createState() => _PreferencesFlowScreenState();
}

class _PreferencesFlowScreenState extends State<PreferencesFlowScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  UserPreferenceModel _preference = const UserPreferenceModel();

  List<Widget> get _inputPages => [
    ExperienceStep(
      selectedExperience: _preference.experienceLevel,
      onSelected: (val) {
        setState(() {
          _preference = _preference.copyWith(experienceLevel: val);
        });
        _nextPage();
      },
    ),
    TimeCommitmentStep(
      timeCommitment: _preference.dailyTimeMinutes,
      onChanged: (val) {
        setState(() {
          _preference = _preference.copyWith(dailyTimeMinutes: val);
        });
      },
    ),
    EnvironmentStep(
      hasPets: _preference.hasPets,
      hasKids: _preference.hasKids,
      onPetsChanged: (val) {
        setState(() {
          _preference = _preference.copyWith(hasPets: val);
        });
      },
      onKidsChanged: (val) {
        setState(() {
          _preference = _preference.copyWith(hasKids: val);
        });
      },
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _inputPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
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

  Future<void> _finish() async {
    await PreferenceHandler.setOnboard(true);
    if (!mounted) return;
    context.pushAndRemoveAll(const AuthSelection());
  }

  @override
  Widget build(BuildContext context) {
    final canProceed =
        _currentIndex != 0 || _preference.experienceLevel.isNotEmpty;

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
              onPressed: _finish,
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
                value: (_currentIndex + 1) / _inputPages.length,
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
                  children: _inputPages,
                ),
              ),
              const SizedBox(height: 24),
              if (_currentIndex > 0)
                CustomButton(
                  text: _currentIndex == _inputPages.length - 1
                      ? 'Selesai'
                      : 'Lanjut',
                  height: 54,
                  borderRadius: BorderRadius.circular(30),
                  onPressed: canProceed ? _nextPage : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
