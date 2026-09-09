import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/daily_care/domain/models/daily_care_state.dart';
import 'package:plenty/features/daily_care/domain/repositories/daily_care_repository.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';

/// Lightweight ChangeNotifier controller for Daily Care routine screen,
/// exposing both state and a reactive stateStream for StreamBuilder.
class DailyCareController extends ChangeNotifier {
  final IDailyCareRepository _repository;
  DailyCareState _state = const DailyCareState(isLoading: true);
  bool _isDisposed = false;
  final StreamController<DailyCareState> _stateController =
      StreamController<DailyCareState>.broadcast();

  DailyCareController({IDailyCareRepository? repository})
      : _repository = repository ?? Injector.dailyCareRepository {
    loadTodayCare();
  }

  DailyCareState get state => _state;
  Stream<DailyCareState> get stateStream => _stateController.stream;

  @override
  void dispose() {
    _isDisposed = true;
    _stateController.close();
    super.dispose();
  }

  void _update(DailyCareState newState) {
    if (_isDisposed) return;
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
    notifyListeners();
  }

  Future<void> loadTodayCare({bool silent = false}) async {
    if (!silent && _state.totalTasksCount == 0) {
      _update(_state.copyWith(isLoading: true, errorMessage: null));
    }
    final result = await _repository.loadDailyCareData();
    switch (result) {
      case Success(:final data):
        _update(data);
      case Error(:final failure):
        _update(
          _state.copyWith(isLoading: false, errorMessage: failure.message),
        );
    }
  }

  Future<void> completeHeightTask({
    required PlantModel plant,
    required double heightCm,
    String? note,
    String? photoPath,
  }) async {
    // 1. Optimistic update: mark height task completed immediately
    final updatedLogs = _state.heightLogs.map((item) {
      if (item.plant.id == plant.id) {
        return item.copyWith(
          isCompletedToday: true,
          loggedHeightToday: heightCm,
          loggedNoteToday: note,
          loggedPhotoPathToday: photoPath,
        );
      }
      return item;
    }).toList();

    _update(_state.copyWith(heightLogs: updatedLogs, isLoading: false));

    // 2. Background database & remote persistence without reloading the screen
    final result = await _repository.completeHeightTask(
      plant: plant,
      heightCm: heightCm,
      note: note,
      photoPath: photoPath,
    );
    switch (result) {
      case Success():
        await loadTodayCare(silent: true);
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
    final updatedLogs = _state.heightLogs.map((item) {
      if (item.plant.id == plant.id) {
        return item.copyWith(
          isCompletedToday: true,
          loggedHeightToday: heightCm,
          loggedNoteToday: note,
          loggedPhotoPathToday: photoPath,
        );
      }
      return item;
    }).toList();

    _update(_state.copyWith(heightLogs: updatedLogs, isLoading: false));

    final result = await _repository.updateHeightTask(
      plant: plant,
      heightCm: heightCm,
      note: note,
      photoPath: photoPath,
    );
    switch (result) {
      case Success():
        await loadTodayCare(silent: true);
      case Error(:final failure):
        _update(_state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> completeRoutineTask({
    required PlantModel plant,
    required String taskType,
    String? notes,
  }) async {
    // 1. Optimistic update: mark cyclic task completed immediately with strikethrough
    final updatedSchedules = _state.dueSchedules.map((item) {
      if (item.plant.id == plant.id && item.taskType == taskType) {
        return item.copyWith(isCompletedToday: true);
      }
      return item;
    }).toList();

    final allDone = updatedSchedules.every((s) => s.isCompletedToday) &&
        _state.heightLogs.every((h) => h.isCompletedToday);

    _update(
      _state.copyWith(
        dueSchedules: updatedSchedules,
        streakCount: (allDone && !_state.isAllCompleted)
            ? (_state.streakCount + 1)
            : _state.streakCount,
        isLoading: false,
      ),
    );

    // 2. Background database & remote persistence without reloading the screen
    final result = await _repository.completeRoutineTask(
      plant: plant,
      taskType: taskType,
      notes: notes,
    );
    switch (result) {
      case Success():
        await loadTodayCare(silent: true);
      case Error(:final failure):
        _update(_state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> completeCyclicTask(DueScheduleItem item) async {
    await completeRoutineTask(plant: item.plant, taskType: item.taskType);
  }
}
