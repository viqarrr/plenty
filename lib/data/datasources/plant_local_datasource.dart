import 'dart:convert';

import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/models/plant_model.dart';

/// Local DataSource managing Plant catalog and user-stored plant collections.
abstract interface class PlantLocalDataSource {
  Future<List<PlantModel>> getUserPlants();
  Future<void> saveUserPlants(List<PlantModel> plants);
  Future<List<PlantModel>> getCatalogPlants();
  Future<String> getProfileName();
  Future<int> getStreakCount();
  Future<void> setStreakCount(int count);
}

class PlantLocalDataSourceImpl implements PlantLocalDataSource {
  static final List<PlantModel> defaultCatalog = [
    PlantModel(
      id: 'cat_1',
      userId: 'usr_default',
      nickname: 'Fiddle Leaf Fig',
      commonName: 'Fiddle Leaf Fig',
      isIndoor: true,
      sunlightCondition: 'Sinar Tidak Langsung',
      potSize: 'Ada Lubang Drainase',
      windowDistance: 'Dekat Jendela (1-1.5 meter)',
      defaultWateringInterval: 7,
      adoptedAt: DateTime.now(),
    ),
    PlantModel(
      id: 'cat_2',
      userId: 'usr_default',
      nickname: 'Snake Plant',
      commonName: 'Snake Plant',
      isIndoor: true,
      sunlightCondition: 'Pencahayaan Rendah',
      potSize: 'Ada Lubang Drainase',
      windowDistance: 'Jauh dari Jendela (2 meter +)',
      defaultWateringInterval: 14,
      adoptedAt: DateTime.now(),
    ),
  ];

  static final List<PlantModel> initialSeedPlants = [
    PlantModel(
      id: 'default_1',
      userId: 'usr_default',
      nickname: 'Monstera',
      commonName: 'Monstera Deliciosa',
      isIndoor: true,
      sunlightCondition: 'Sinar Tidak Langsung',
      windowDistance: 'Dekat Jendela',
      defaultWateringInterval: 7,
      adoptedAt: DateTime.now(),
    ),
    PlantModel(
      id: 'default_2',
      userId: 'usr_default',
      nickname: 'Snake Plant',
      commonName: 'Dracaena trifasciata',
      isIndoor: true,
      sunlightCondition: 'Pencahayaan Rendah',
      windowDistance: 'Jauh dari Jendela',
      defaultWateringInterval: 14,
      adoptedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<PlantModel>> getUserPlants() async {
    final jsonString = PreferenceHandler.getUserPlantsJson();
    if (jsonString == null) {
      return initialSeedPlants;
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) => PlantModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return initialSeedPlants;
    }
  }

  @override
  Future<void> saveUserPlants(List<PlantModel> plants) async {
    final jsonList = plants.map((p) => p.toJson()).toList();
    await PreferenceHandler.saveUserPlantsJson(jsonEncode(jsonList));
  }

  @override
  Future<List<PlantModel>> getCatalogPlants() async {
    return defaultCatalog;
  }

  @override
  Future<String> getProfileName() async {
    final user = await PreferenceHandler.getUser();
    return user?.displayName ?? 'Plant Parent';
  }

  @override
  Future<int> getStreakCount() async {
    return PreferenceHandler.streakCount;
  }

  @override
  Future<void> setStreakCount(int count) async {
    await PreferenceHandler.setStreakCount(count);
  }
}
