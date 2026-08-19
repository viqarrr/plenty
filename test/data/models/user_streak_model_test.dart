import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/data/models/user_streak_model.dart';

void main() {
  group('UserStreakModel Serialization & Tier Logic', () {
    test('calculateTier computes correct milestones', () {
      expect(UserStreakModel.calculateTier(0), 1);
      expect(UserStreakModel.calculateTier(2), 1);
      expect(UserStreakModel.calculateTier(3), 2);
      expect(UserStreakModel.calculateTier(4), 2);
      expect(UserStreakModel.calculateTier(5), 3);
      expect(UserStreakModel.calculateTier(6), 3);
      expect(UserStreakModel.calculateTier(7), 4);
      expect(UserStreakModel.calculateTier(13), 4);
      expect(UserStreakModel.calculateTier(14), 5);
      expect(UserStreakModel.calculateTier(21), 6);
      expect(UserStreakModel.calculateTier(30), 7);
      expect(UserStreakModel.calculateTier(100), 7);
    });

    test('fromMap and toMap serialize accurately', () {
      final map = {
        'user_id': 1,
        'current_streak': 7,
        'longest_streak': 14,
        'current_tier': 4,
        'last_streak_date': '2026-08-19',
        'freeze_tokens_available': 1,
        'freeze_used_on': null,
      };

      final model = UserStreakModel.fromMap(map);

      expect(model.userId, '1');
      expect(model.currentStreak, 7);
      expect(model.longestStreak, 14);
      expect(model.currentTier, 4);
      expect(model.tierName, 'Tangan Hijau');
      expect(model.toMap(), equals(map));
    });
  });
}
