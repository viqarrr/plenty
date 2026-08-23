import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/domain/models/badge_item.dart';

void main() {
  group('BadgeItem Model Tests', () {
    test('BadgeItem initializes and supports copyWith correctly', () {
      const item = BadgeItem(
        id: 'first_plant',
        title: 'Adopsi Pertama',
        desc: 'Menanam tanaman pertama',
        iconName: 'eco',
        isUnlocked: true,
        level: 1,
        progress: 1,
        total: 1,
        bgColorHex: '#EBF7F1',
        accentColorHex: '#2D6A4F',
      );

      expect(item.id, 'first_plant');
      expect(item.title, 'Adopsi Pertama');
      expect(item.isUnlocked, isTrue);

      final modified = item.copyWith(isUnlocked: false, progress: 0);
      expect(modified.isUnlocked, isFalse);
      expect(modified.progress, 0);
    });
  });
}
