import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/data/models/user_preference_model.dart';
import 'package:plenty/data/repositories/user_repository.dart';

class OnboardingState {
  final int currentStep;
  final String experienceLevel;
  final double dailyTimeMinutes;
  final bool hasPets;
  final bool hasKids;
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const OnboardingState({
    this.currentStep = 0,
    this.experienceLevel = 'beginner',
    this.dailyTimeMinutes = 15.0,
    this.hasPets = false,
    this.hasKids = false,
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? experienceLevel,
    double? dailyTimeMinutes,
    bool? hasPets,
    bool? hasKids,
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      dailyTimeMinutes: dailyTimeMinutes ?? this.dailyTimeMinutes,
      hasPets: hasPets ?? this.hasPets,
      hasKids: hasKids ?? this.hasKids,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  UserPreferenceModel toPreferenceModel(String userId) => UserPreferenceModel(
    userId: userId,
    experienceLevel: experienceLevel,
    dailyTimeMinutes: dailyTimeMinutes,
    hasPets: hasPets,
    hasKids: hasKids,
    hasCompletedOnboarding: isCompleted,
  );
}

class OnboardingController extends StateNotifier<OnboardingState> {
  final UserRepository _userRepo;
  final String? _userId;

  OnboardingController({UserRepository? userRepo, this._userId})
    : _userRepo = userRepo ?? UserRepository(),
      super(const OnboardingState());

  Future<void> setExperienceLevel(String level) async {
    state = state.copyWith(experienceLevel: level, currentStep: 1);
    await _persistCurrentState();
  }

  Future<void> setDailyTimeMinutes(double minutes) async {
    state = state.copyWith(dailyTimeMinutes: minutes, currentStep: 2);
    await _persistCurrentState();
  }

  Future<void> setEnvironmentSafety({bool? hasPets, bool? hasKids}) async {
    state = state.copyWith(
      hasPets: hasPets ?? state.hasPets,
      hasKids: hasKids ?? state.hasKids,
      currentStep: 3,
    );
    await _persistCurrentState();
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      state = state.copyWith(currentStep: step);
    }
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _userRepo.saveOnboardingPrefs(
        userId: _userId,
        experienceLevel: state.experienceLevel,
        dailyTimeMinutes: state.dailyTimeMinutes,
        hasPets: state.hasPets,
        hasKids: state.hasKids,
        hasCompletedOnboarding: true,
      );
      state = state.copyWith(isLoading: false, isCompleted: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> _persistCurrentState() async {
    try {
      await _userRepo.saveOnboardingPrefs(
        userId: _userId,
        experienceLevel: state.experienceLevel,
        dailyTimeMinutes: state.dailyTimeMinutes,
        hasPets: state.hasPets,
        hasKids: state.hasKids,
        hasCompletedOnboarding: false,
      );
    } catch (_) {}
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
      final userRepo = ref.watch(userRepositoryProvider);
      return OnboardingController(userRepo: userRepo);
    });
