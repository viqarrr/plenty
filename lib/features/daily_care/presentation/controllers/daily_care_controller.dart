import 'package:flutter/foundation.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/daily_care/domain/models/daily_care_state.dart';
import 'package:plenty/features/daily_care/domain/repositories/daily_care_repository.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

/// Lightweight ChangeNotifier controller for Daily Care routine screen.
class DailyCareController extends ChangeNotifier {
  final IDailyCareRepository _repository;
  DailyCareState _state = const DailyCareState(isLoading: true);
  bool _isDisposed = false;

  DailyCareController({IDailyCareRepository? repository})
      : _repository = repository ?? Injector.dailyCareRepository {
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
    final result = await _repository.loadDailyCareData();
    switch (result) {
      case Success(:final data):
        _update(data);
      case Error(:final failure):
        _update(_state.copyWith(isLoading: false, errorMessage: failure.message));
    }
  }

  Future<void> completeHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    final result = await _repository.completeHeightTask(
      plant: plant,
      heightCm: heightCm,
      note: note,
      photoPath: photoPath,
    );
    switch (result) {
      case Success():
        await loadTodayCare();
      case Error(:final failure):
        _update(_state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> updateHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    final result = await _repository.updateHeightTask(
      plant: plant,
      heightCm: heightCm,
      note: note,
      photoPath: photoPath,
    );
    switch (result) {
      case Success():
        await loadTodayCare();
      case Error(:final failure):
        _update(_state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> completeRoutineTask({
    required PlantModel plant,
    required String taskType,
    String? notes,
  }) async {
    final result = await _repository.completeRoutineTask(
      plant: plant,
      taskType: taskType,
      notes: notes,
    );
    switch (result) {
      case Success():
        await loadTodayCare();
      case Error(:final failure):
        _update(_state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> completeCyclicTask(DueScheduleItem item) async {
    await completeRoutineTask(plant: item.plant, taskType: item.taskType);
  }
}
