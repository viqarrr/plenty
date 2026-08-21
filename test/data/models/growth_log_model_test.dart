import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/features/garden/domain/models/growth_log_model.dart';

void main() {
  group('GrowthLogModel Serialization Tests', () {
    final testDate = DateTime(2026, 8, 18, 14, 0);

    test('GrowthLogModel handles nullable photo_path gracefully', () {
      final mapWithoutPhoto = <String, dynamic>{
        'id': 'growth_1',
        'user_plant_id': 'plant_123',
        'photo_path': null,
        'height_cm': 42.0,
        'leaf_count': 7,
        'note': 'Daily height monitor',
        'source': 'daily_task',
        'logged_at': testDate.toIso8601String(),
      };

      final log = GrowthLogModel.fromMap(mapWithoutPhoto);

      expect(log.id, 'growth_1');
      expect(log.userPlantId, 'plant_123');
      expect(log.photoPath, isNull);
      expect(log.heightCm, 42.0);
      expect(log.leafCount, 7);
      expect(log.note, 'Daily height monitor');
      expect(log.source, 'daily_task');
      expect(log.loggedAt, testDate);

      final serialized = log.toMap();
      expect(serialized['photo_path'], isNull);
      expect(serialized['source'], 'daily_task');
    });

    test('GrowthLogModel handles initial source and photo_path', () {
      final mapWithPhoto = <String, dynamic>{
        'id': 'growth_init_1',
        'user_plant_id': 'plant_123',
        'photo_path': 'assets/images/initial_plant.png',
        'height_cm': 30.0,
        'leaf_count': null,
        'note': 'Initial adoption',
        'source': 'initial',
        'logged_at': testDate.toIso8601String(),
      };

      final log = GrowthLogModel.fromMap(mapWithPhoto);

      expect(log.photoPath, 'assets/images/initial_plant.png');
      expect(log.source, 'initial');
      expect(log.heightCm, 30.0);
    });
  });
}
