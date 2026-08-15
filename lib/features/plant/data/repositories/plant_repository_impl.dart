import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/utils/result.dart';
import 'package:plenty/features/plant/data/datasources/plant_local_datasource.dart';
import 'package:plenty/features/plant/data/models/plant_model.dart';
import 'package:plenty/features/plant/domain/entities/care_task_entity.dart';
import 'package:plenty/features/plant/domain/entities/plant_entity.dart';
import 'package:plenty/features/plant/domain/repositories/plant_repository.dart';

/// Concrete implementation of [PlantRepository].
class PlantRepositoryImpl implements PlantRepository {
  final PlantLocalDataSource _dataSource;

  PlantRepositoryImpl([PlantLocalDataSource? dataSource])
      : _dataSource = dataSource ?? PlantLocalDataSourceImpl();

  @override
  Future<Result<List<PlantEntity>>> getUserPlants() async {
    try {
      final models = await _dataSource.getUserPlants();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<PlantEntity>>> getCatalogPlants() async {
    try {
      final models = await _dataSource.getCatalogPlants();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> addUserPlant(PlantEntity plant) async {
    try {
      final currentModels = await _dataSource.getUserPlants();
      final updatedList = List<PlantModel>.from(currentModels)
        ..removeWhere((p) => p.id == plant.id)
        ..add(PlantModel.fromEntity(plant));
      await _dataSource.saveUserPlants(updatedList);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> removeUserPlant(String plantId) async {
    try {
      final currentModels = await _dataSource.getUserPlants();
      final updatedList = List<PlantModel>.from(currentModels)
        ..removeWhere((p) => p.id == plantId);
      await _dataSource.saveUserPlants(updatedList);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updatePlant(PlantEntity plant) async {
    try {
      final currentModels = await _dataSource.getUserPlants();
      final index = currentModels.indexWhere((p) => p.id == plant.id);
      if (index != -1) {
        currentModels[index] = PlantModel.fromEntity(plant);
        await _dataSource.saveUserPlants(currentModels);
        return const Success(null);
      }
      return const Error(NotFoundFailure('Tanaman tidak ditemukan'));
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> completeTask(CareTaskEntity task) async {
    try {
      final plant = task.plant;
      final updatedPlant = switch (task.type) {
        TaskType.watering => plant.copyWith(nextWaterDate: 'Siram 7 hari lagi'),
        TaskType.cleaning => plant.copyWith(lastCleanedDate: 'Bersih'),
      };
      await updatePlant(updatedPlant);
      await incrementStreak();
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> getProfileName() async {
    try {
      final name = await _dataSource.getProfileName();
      return Success(name);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> setProfileName(String name) async {
    try {
      await _dataSource.setProfileName(name);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<int>> getStreakCount() async {
    try {
      final count = await _dataSource.getStreakCount();
      return Success(count);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<int>> incrementStreak() async {
    try {
      final current = await _dataSource.getStreakCount();
      final newStreak = current + 1;
      await _dataSource.setStreakCount(newStreak);
      return Success(newStreak);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }
}
