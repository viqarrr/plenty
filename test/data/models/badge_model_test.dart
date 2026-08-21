import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/features/garden/domain/models/badge_model.dart';

void main() {
  group('BadgeModel Serialization', () {
    test('fromMap and toMap serialize and deserialize correctly', () {
      final map = {
        'id': 'FIRST_PLANT',
        'title': 'Tunas Pertama 🌱',
        'description': 'Menambahkan tanaman pertamamu',
        'icon_asset_path': 'assets/images/badges/badge_first_plant.png',
      };

      final model = BadgeModel.fromMap(map);

      expect(model.id, 'FIRST_PLANT');
      expect(model.title, 'Tunas Pertama 🌱');
      expect(model.description, 'Menambahkan tanaman pertamamu');
      expect(model.iconAssetPath, 'assets/images/badges/badge_first_plant.png');
      expect(model.toMap(), equals(map));
    });
  });

  group('UserBadgeModel Serialization', () {
    test('fromMap and toMap handle date parsing correctly', () {
      final map = {
        'id': 'ub_12345',
        'user_id': 1,
        'badge_id': 'FIRST_PLANT',
        'unlocked_at': '2026-08-19T08:00:00.000Z',
      };

      final model = UserBadgeModel.fromMap(map);

      expect(model.id, 'ub_12345');
      expect(model.userId, '1');
      expect(model.badgeId, 'FIRST_PLANT');
      expect(model.unlockedAt, DateTime.parse('2026-08-19T08:00:00.000Z'));
      expect(model.toMap(), equals(map));
    });
  });
}
