import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/domain/models/streak_model.dart';

/// Contract interface for Streak Repository.
abstract interface class IStreakRepository {
  /// Retrieves streak information for a given user.
  Future<Result<UserStreakModel>> getStreak(String userId);

  /// Evaluates and updates the daily streak based on active care action logs.
  Future<Result<UserStreakModel>> evaluateDailyStreak(String userId);

  /// Retrieves distinct active care log dates for a user.
  Future<Result<List<String>>> getDistinctActiveLogDates(String userId);
}
