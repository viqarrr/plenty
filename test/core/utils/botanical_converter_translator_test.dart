import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/utils/botanical_translator.dart';
import 'package:plenty/core/utils/botanical_unit_converter.dart';
import 'package:plenty/features/plant_catalog/domain/models/plant_catalog_model.dart';

void main() {
  group('BotanicalUnitConverter Unit Tests', () {
    test('Converts feet range to metric meters', () {
      expect(
        BotanicalUnitConverter.convertToMetric('8.0 - 10.0 feet'),
        'Tinggi 2,4 - 3 Meter',
      );
      expect(
        BotanicalUnitConverter.convertToMetric('6 feet'),
        'Tinggi 1,8 Meter',
      );
    });

    test('Converts inches range to metric cm', () {
      expect(
        BotanicalUnitConverter.convertToMetric('12 - 24 inches'),
        'Tinggi 30 - 61 cm',
      );
      expect(
        BotanicalUnitConverter.convertToMetric('20 inches'),
        'Tinggi 51 cm',
      );
    });

    test('Preserves already metric dimensions or defaults cleanly', () {
      expect(
        BotanicalUnitConverter.convertToMetric('Tinggi 2,5 - 3 Meter'),
        'Tinggi 2,5 - 3 Meter',
      );
      expect(
        BotanicalUnitConverter.convertToMetric(null),
        'Tinggi 1 - 2 Meter',
      );
    });
  });

  group('BotanicalTranslator Unit Tests', () {
    test('Translates cycle correctly', () {
      expect(BotanicalTranslator.translateCycle('Perennial'), 'Perenial (Abadi)');
      expect(BotanicalTranslator.translateCycle('Annual'), 'Semusim (Annual)');
      expect(BotanicalTranslator.translateCycle(null), 'Perenial (Abadi)');
    });

    test('Translates growth rate correctly', () {
      expect(BotanicalTranslator.translateGrowthRate('High'), 'Cepat');
      expect(BotanicalTranslator.translateGrowthRate('Medium'), 'Sedang');
      expect(BotanicalTranslator.translateGrowthRate('Slow'), 'Lambat');
      expect(BotanicalTranslator.translateGrowthRate(null), 'Sedang');
    });

    test('Translates flowering season correctly', () {
      expect(
        BotanicalTranslator.translateFloweringSeason('Spring, Summer'),
        'Musim Semi, Musim Panas',
      );
      expect(
        BotanicalTranslator.translateFloweringSeason(null, commonName: 'Monstera'),
        'Jarang di Dalam Ruangan',
      );
      expect(
        BotanicalTranslator.translateFloweringSeason(null, commonName: 'Peace Lily'),
        'Musim Semi & Panas',
      );
    });
  });

  group('PlantCatalogModel Integration', () {
    test('Model serializes and deserializes botanical fields accurately', () {
      final plant = PlantCatalogModel(
        id: 'cat_test',
        commonName: 'Test Monstera',
        scientificName: 'Monstera deliciosa',
        family: 'Araceae',
        defaultWateringInterval: 7,
        dimension: '8.0 - 10.0 feet',
        growthRate: 'Medium',
        cycle: 'Perennial',
        pruningMonth: 'March to May',
        floweringSeason: 'Rare',
        description: 'Deskripsi lengkap botani.',
        origin: 'Meksiko',
        isToxicToPets: true,
        cachedAt: DateTime(2026, 1, 1),
      );

      final map = plant.toMap();
      expect(map['dimension'], '8.0 - 10.0 feet');
      expect(map['is_toxic'], 1);
      expect(map['growth_rate'], 'Medium');

      final fromMapPlant = PlantCatalogModel.fromMap(map);
      expect(fromMapPlant.dimensionDisplay, 'Tinggi 2,4 - 3 Meter');
      expect(fromMapPlant.growthRateDisplay, 'Sedang');
      expect(fromMapPlant.cycleDisplay, 'Perenial (Abadi)');
      expect(fromMapPlant.isToxic, true);
    });
  });
}
