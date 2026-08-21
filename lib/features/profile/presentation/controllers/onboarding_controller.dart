import 'package:flutter/foundation.dart';
import 'package:plenty/features/profile/data/repositories/user_repository.dart';
import 'package:plenty/features/profile/domain/models/user_preference_model.dart';

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

class OnboardingController extends ChangeNotifier {
  final UserRepository _userRepo;
  final String? userId;

  OnboardingState _state = const OnboardingState();
  OnboardingState get state => _state;

  bool _isDisposed = false;

  OnboardingController({UserRepository? userRepo, this.userId})
    : _userRepo = userRepo ?? UserRepository();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _updateState(OnboardingState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> setExperienceLevel(String level) async {
    _updateState(_state.copyWith(experienceLevel: level, currentStep: 1));
    await _persistCurrentState();
  }

  Future<void> setDailyTimeMinutes(double minutes) async {
    _updateState(_state.copyWith(dailyTimeMinutes: minutes, currentStep: 2));
    await _persistCurrentState();
  }

  Future<void> setEnvironmentSafety({bool? hasPets, bool? hasKids}) async {
    _updateState(
      _state.copyWith(
        hasPets: hasPets ?? _state.hasPets,
        hasKids: hasKids ?? _state.hasKids,
        currentStep: 3,
      ),
    );
    await _persistCurrentState();
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      _updateState(_state.copyWith(currentStep: step));
    }
  }

  Future<void> completeOnboarding() async {
    _updateState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _userRepo.saveOnboardingPrefs(
        userId: userId,
        experienceLevel: _state.experienceLevel,
        dailyTimeMinutes: _state.dailyTimeMinutes,
        hasPets: _state.hasPets,
        hasKids: _state.hasKids,
        hasCompletedOnboarding: true,
      );
      _updateState(_state.copyWith(isLoading: false, isCompleted: true));
    } catch (e) {
      _updateState(_state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _persistCurrentState() async {
    try {
      await _userRepo.saveOnboardingPrefs(
        userId: userId,
        experienceLevel: _state.experienceLevel,
        dailyTimeMinutes: _state.dailyTimeMinutes,
        hasPets: _state.hasPets,
        hasKids: _state.hasKids,
        hasCompletedOnboarding: false,
      );
    } catch (_) {}
  }
}
