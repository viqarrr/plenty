import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/profile/domain/models/badge_item.dart';

/// Contract interface for Badge Repository.
abstract interface class IBadgeRepository {
  /// Fetches all badges joined with user achievement status for [userId].
  Future<Result<List<BadgeItem>>> getBadges({int? userId});

  /// Fetches only unlocked badges for [userId].
  Future<Result<List<BadgeItem>>> getUnlockedBadges({int? userId});

  /// Fetches the count of unlocked badges for [userId].
  Future<Result<int>> getUnlockedBadgeCount({int? userId});

  /// Helper returning total count of badges unlocked by user.
  Future<Result<int>> getUserBadgeCount([dynamic userId]);

  /// Fetches a single badge by its [badgeId] for [userId].
  Future<Result<BadgeItem?>> getBadgeById(String badgeId, {int? userId});

  /// Awards a badge to user and updates SQLite tables.
  Future<Result<bool>> awardBadge({
    required dynamic userId,
    required String badgeId,
  });
}
