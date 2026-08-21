import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

void main() {
  group('PlantModel Serialization Tests', () {
    final testAdoptedAt = DateTime(2026, 8, 18, 10, 30);

    final testMap = <String, dynamic>{
      'id': 'plant_123',
      'user_id': 456,
      'catalog_id': 'cat_monstera',
      'nickname': 'Monsty',
      'is_indoor': 1,
      'sunlight_condition': 'Sinar Tidak Langsung',
      'pot_size': 'Pot Keramik 20cm',
      'window_distance': 'Dekat Jendela (1-1.5 meter)',
      'initial_height_cm': 35.5,
      'adopted_at': testAdoptedAt.toIso8601String(),
      'cover_photo_path': 'assets/images/monstera.png',
      'health_status': 'healthy',
      'level': 2,
      'xp': 140,
      'is_archived': 0,
    };

    test('PlantModel.fromMap correctly parses all section 1.5 fields', () {
      final plant = PlantModel.fromMap(testMap);

      expect(plant.id, 'plant_123');
      expect(plant.userId, '456');
      expect(plant.catalogId, 'cat_monstera');
      expect(plant.nickname, 'Monsty');
      expect(plant.isIndoor, isTrue);
      expect(plant.sunlightCondition, 'Sinar Tidak Langsung');
      expect(plant.potSize, 'Pot Keramik 20cm');
      expect(plant.site, 'Dekat Jendela (1-1.5 meter)');
      expect(plant.siteName, 'Dekat Jendela (1-1.5 meter)');
      expect(plant.windowDistance, 'Dekat Jendela (1-1.5 meter)');
      expect(plant.initialHeightCm, 35.5);
      expect(plant.adoptedAt, testAdoptedAt);
      expect(plant.coverPhotoPath, 'assets/images/monstera.png');
      expect(plant.healthStatus, 'healthy');
      expect(plant.level, 2);
      expect(plant.xp, 140);
      expect(plant.isArchived, isFalse);
    });

    test('PlantModel.toMap serializes all properties according to SQLite schema', () {
      final plant = PlantModel.fromMap(testMap);
      final serialized = plant.toMap();

      expect(serialized['id'], 'plant_123');
      expect(serialized['user_id'], 456);
      expect(serialized['catalog_id'], 'cat_monstera');
      expect(serialized['nickname'], 'Monsty');
      expect(serialized['is_indoor'], 1);
      expect(serialized['sunlight_condition'], 'Sinar Tidak Langsung');
      expect(serialized['pot_size'], 'Pot Keramik 20cm');
      expect(serialized['site'], 'Dekat Jendela (1-1.5 meter)');
      expect(serialized['window_distance'], 'Dekat Jendela (1-1.5 meter)');
      expect(serialized['initial_height_cm'], 35.5);
      expect(serialized['adopted_at'], testAdoptedAt.toIso8601String());
      expect(serialized['cover_photo_path'], 'assets/images/monstera.png');
      expect(serialized['health_status'], 'healthy');
      expect(serialized['level'], 2);
      expect(serialized['xp'], 140);
      expect(serialized['is_archived'], 0);
    });
  });
}
