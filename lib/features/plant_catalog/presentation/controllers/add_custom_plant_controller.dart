import 'package:flutter/foundation.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/features/plant_catalog/presentation/controllers/add_custom_plant_state.dart';

/// Controller managing state, validation, step transitions, and submission for the Add Custom Plant flow.
class AddCustomPlantController extends ChangeNotifier {
  final IPlantRepository _plantRepo;
  final String userId;

  AddCustomPlantState _state = AddCustomPlantState.initial();
  AddCustomPlantState get state => _state;

  bool _isDisposed = false;

  AddCustomPlantController({
    IPlantRepository? plantRepo,
    this.userId = 'usr_default',
  })  : _plantRepo = plantRepo ?? Injector.plantRepository;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _updateState(AddCustomPlantState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  void setStep(int step) {
    if (step >= 0 && step <= 5) {
      _updateState(_state.copyWith(currentStep: step));
    }
  }

  void nextStep() {
    if (_state.currentStep < 5 && _state.isCurrentStepValid) {
      _updateState(_state.copyWith(currentStep: _state.currentStep + 1));
    }
  }

  void previousStep() {
    if (_state.currentStep > 0) {
      _updateState(_state.copyWith(currentStep: _state.currentStep - 1));
    }
  }

  void setPlantName(String name) {
    _updateState(_state.copyWith(plantName: name));
  }

  void setGrowthStage(String stage) {
    _updateState(
      _state.copyWith(
        growthStage: stage,
        plantedDate: stage == 'seed' ? DateTime.now() : _state.plantedDate,
        initialHeightCm: stage == 'seed' && _state.initialHeightCm == 25.0
            ? 2.0
            : (stage == 'mature' && _state.initialHeightCm == 2.0 ? 25.0 : _state.initialHeightCm),
      ),
    );
  }

  void setInitialHeight(double height) {
    _updateState(_state.copyWith(initialHeightCm: height));
  }

  void setImagePath(String? path) {
    if (path == null) {
      _updateState(_state.copyWith(clearImagePath: true));
    } else {
      _updateState(_state.copyWith(imagePath: path));
    }
  }

  void setEnvironment(String environment) {
    _updateState(_state.copyWith(isIndoor: environment == 'Indoor'));
  }

  void setDrainage(String drainage) {
    _updateState(_state.copyWith(potSize: drainage));
  }

  void setRoom(String room) {
    _updateState(_state.copyWith(selectedRoom: room));
  }

  void setLight(String light) {
    _updateState(_state.copyWith(selectedLight: light));
  }

  void setPlantedDate(DateTime date) {
    _updateState(_state.copyWith(plantedDate: date));
  }

  void setTimeCapsuleMessage(String message) {
    _updateState(_state.copyWith(timeCapsuleMessage: message));
  }

  void toggleTimeCapsule(bool enable) {
    _updateState(_state.copyWith(enableTimeCapsule: enable));
  }

  Future<bool> submitCustomPlant() async {
    if (!_state.isCurrentStepValid) return false;

    _updateState(_state.copyWith(isSubmitting: true, errorMessage: null));

    final result = await _plantRepo.addPlant(
      userId: userId,
      nickname: _state.plantName.trim(),
      isIndoor: _state.isIndoor,
      sunlightCondition: _state.selectedLight,
      potSize: _state.potSize,
      site: _state.selectedRoom,
      windowDistance: _state.selectedRoom,
      initialHeightCm: _state.initialHeightCm,
      growthStage: _state.growthStage,
      adoptedAt: _state.plantedDate,
      coverPhotoPath: _state.imagePath,
      customPhotoPath: _state.imagePath,
      timeCapsule: _state.timeCapsuleDraft,
      defaultWateringInterval: 4,
    );

    switch (result) {
      case Success():
        _updateState(_state.copyWith(isSubmitting: false, isSuccess: true));
        return true;
      case Error(:final failure):
        _updateState(
          _state.copyWith(
            isSubmitting: false,
            errorMessage: 'Gagal menambahkan tanaman kustom: ${failure.message}',
          ),
        );
        return false;
    }
  }
}
