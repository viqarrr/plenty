import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/onboarding/domain/models/user_preference_model.dart';

/// Contract interface for User Repository.
abstract interface class IUserRepository {
  /// Saves or updates the onboarding preferences for a user.
  Future<Result<void>> saveOnboardingPrefs({
    String? userId,
    required String experienceLevel,
    double dailyTimeMinutes,
    bool hasPets,
    bool hasKids,
    bool hasCompletedOnboarding,
  });

  /// Sets the onboarding completed flag.
  Future<Result<void>> setOnboardingCompleted([String? userId]);

  /// Checks if the user has completed the onboarding flow.
  Future<Result<bool>> hasCompletedOnboarding([String? userId]);

  /// Retrieves user preferences for the active or given user.
  Future<Result<UserPreferenceModel?>> getUserPreferences([String? userId]);

  /// Retrieves user profile UserModel from SQLite users table.
  Future<Result<UserModel?>> getUserProfile([String? userId]);

  /// Updates profile attributes in SQLite and active session.
  Future<Result<void>> updateUserProfile({
    String? userId,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  });

  /// Changes the user's account password with verification and hashing.
  Future<Result<void>> updatePassword({
    String? userId,
    required String currentPassword,
    required String newPassword,
  });
}
