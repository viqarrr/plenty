import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/add_custom_plant_state.dart';

final addCustomPlantControllerProvider = StateNotifierProvider.autoDispose<
    AddCustomPlantController, AddCustomPlantState>((ref) {
  return AddCustomPlantController(plantRepo: PlantRepository());
});

/// Controller managing state, validation, step transitions, and submission for the Add Custom Plant flow.
class AddCustomPlantController extends StateNotifier<AddCustomPlantState> {
  final PlantRepository _plantRepo;
  final String userId;

  AddCustomPlantController({
    PlantRepository? plantRepo,
    this.userId = 'usr_default',
  })  : _plantRepo = plantRepo ?? PlantRepository(),
        super(AddCustomPlantState.initial());

  void setStep(int step) {
    if (step >= 0 && step <= 4) {
      state = state.copyWith(currentStep: step);
    }
  }

  void nextStep() {
    if (state.currentStep < 4 && state.isCurrentStepValid) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setPlantName(String name) {
    state = state.copyWith(plantName: name);
  }

  void setImagePath(String? path) {
    if (path == null) {
      state = state.copyWith(clearImagePath: true);
    } else {
      state = state.copyWith(imagePath: path);
    }
  }

  void setEnvironment(String environment) {
    state = state.copyWith(isIndoor: environment == 'Indoor');
  }

  void setDrainage(String drainage) {
    state = state.copyWith(potSize: drainage);
  }

  void setRoom(String room) {
    state = state.copyWith(selectedRoom: room);
  }

  void setLight(String light) {
    state = state.copyWith(selectedLight: light);
  }

  void setPlantedDate(DateTime date) {
    state = state.copyWith(plantedDate: date);
  }

  void setTimeCapsuleMessage(String message) {
    state = state.copyWith(timeCapsuleMessage: message);
  }

  void toggleTimeCapsule(bool enable) {
    state = state.copyWith(enableTimeCapsule: enable);
  }

  Future<bool> submitCustomPlant() async {
    if (!state.isCurrentStepValid) return false;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      await _plantRepo.addPlant(
        userId: userId,
        nickname: state.plantName.trim(),
        isIndoor: state.isIndoor,
        sunlightCondition: state.selectedLight,
        potSize: state.potSize,
        windowDistance: state.selectedRoom,
        initialHeightCm: 25.0,
        coverPhotoPath: state.imagePath,
        timeCapsule: state.timeCapsuleDraft,
        defaultWateringInterval: 4,
      );

      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Gagal menambahkan tanaman kustom: $e',
      );
      return false;
    }
  }
}
