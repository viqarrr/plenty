import 'package:flutter/foundation.dart';
import 'package:plenty/features/daily_care/data/care_repository.dart';
import 'package:plenty/features/daily_care/data/daily_care_repository.dart';
import 'package:plenty/features/daily_care/domain/models/daily_care_state.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository.dart';
import 'package:plenty/features/garden/data/repositories/streak_repository.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

/// Lightweight ChangeNotifier controller for Daily Care routine screen.
class DailyCareController extends ChangeNotifier {
  final DailyCareRepository _repository;
  DailyCareState _state = const DailyCareState(isLoading: true);
  bool _isDisposed = false;

  DailyCareController({
    DailyCareRepository? repository,
    PlantRepository? plantRepo,
    CareRepository? careRepo,
    StreakRepository? streakRepo,
  })  : _repository = repository ??
            DailyCareRepository(
              plantRepo: plantRepo,
              careRepo: careRepo,
              streakRepo: streakRepo,
            ) {
    loadTodayCare();
  }

  DailyCareState get state => _state;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _update(DailyCareState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> loadTodayCare() async {
    _update(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      final loaded = await _repository.loadDailyCareData();
      _update(loaded);
    } catch (e) {
      _update(_state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> completeHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    await _repository.completeHeightTask(
      plant: plant,
      heightCm: heightCm,
      note: note,
      photoPath: photoPath,
    );
    await loadTodayCare();
  }

  Future<void> updateHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    await _repository.updateHeightTask(
      plant: plant,
      heightCm: heightCm,
      note: note,
      photoPath: photoPath,
    );
    await loadTodayCare();
  }

  Future<void> completeRoutineTask({
    required PlantModel plant,
    required String taskType,
  }) async {
    await _repository.completeRoutineTask(plant: plant, taskType: taskType);
    await loadTodayCare();
  }

  Future<void> completeCyclicTask(DueScheduleItem item) async {
    await completeRoutineTask(plant: item.plant, taskType: item.taskType);
  }
}
