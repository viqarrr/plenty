import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/data/repositories/plant_repository.dart';

enum AddPlantEntryPoint { onboarding, emptyState, fabHome }

class AddPlantFlowState {
  final int currentStep; // 0: Select Species, 1: Species Preview, 2: Name & Photo, 3: Environment, 4: Area, 5: Light, 6: Time Capsule
  final PlantCatalogModel? selectedSpecies;
  final String plantName;
  final String? customPhotoPath;
  final String growthStage;
  final double initialHeightCm;
  final bool isIndoor;
  final String potSize;
  final String selectedRoom;
  final String selectedLight;
  final DateTime plantedDate;
  final String? timeCapsuleMessage;
  final bool enableTimeCapsule;
  final bool isLoading;
  final String? errorMessage;
  final AddPlantEntryPoint entryPoint;

  const AddPlantFlowState({
    this.currentStep = 0,
    this.selectedSpecies,
    this.plantName = '',
    this.customPhotoPath,
    this.growthStage = 'mature',
    this.initialHeightCm = 25.0,
    this.isIndoor = true,
    this.potSize = 'Ada Lubang Drainase',
    this.selectedRoom = 'Ruang Tamu',
    this.selectedLight = 'Sinar Tidak Langsung Terang',
    required this.plantedDate,
    this.timeCapsuleMessage,
    this.enableTimeCapsule = false,
    this.isLoading = false,
    this.errorMessage,
    this.entryPoint = AddPlantEntryPoint.fabHome,
  });

  /// Helper factory for initial state
  factory AddPlantFlowState.initial(AddPlantEntryPoint entryPoint) =>
      AddPlantFlowState(
        plantedDate: DateTime.now(),
        entryPoint: entryPoint,
      );

  /// Environment string format ('Indoor' or 'Outdoor')
  String get environment => isIndoor ? 'Indoor' : 'Outdoor';

  /// Returns current step index relative to wizard (0 to 5) when in wizard steps (2 to 7)
  int get wizardStepIndex => (currentStep - 2).clamp(0, 5);

  bool get isCurrentStepValid {
    switch (currentStep) {
      case 0:
        return selectedSpecies != null;
      case 1:
        return true;
      case 2:
        return plantName.trim().isNotEmpty;
      case 3:
        return growthStage.isNotEmpty;
      case 4:
        return potSize.isNotEmpty;
      case 5:
        return selectedRoom.trim().isNotEmpty;
      case 6:
        return selectedLight.trim().isNotEmpty;
      case 7:
        return true;
      default:
        return true;
    }
  }

  TimeCapsuleDraft? get timeCapsuleDraft {
    if (!enableTimeCapsule ||
        timeCapsuleMessage == null ||
        timeCapsuleMessage!.trim().isEmpty) {
      return null;
    }
    return TimeCapsuleDraft(
      message: timeCapsuleMessage!.trim(),
      photoPath: customPhotoPath ?? selectedSpecies?.imageUrl,
      durationMonths: 1,
    );
  }

  AddPlantFlowState copyWith({
    int? currentStep,
    PlantCatalogModel? selectedSpecies,
    String? plantName,
    String? customPhotoPath,
    String? growthStage,
    double? initialHeightCm,
    bool? isIndoor,
    String? potSize,
    String? selectedRoom,
    String? selectedLight,
    DateTime? plantedDate,
    String? timeCapsuleMessage,
    bool? enableTimeCapsule,
    bool? isLoading,
    String? errorMessage,
    AddPlantEntryPoint? entryPoint,
    bool clearCustomPhoto = false,
  }) {
    return AddPlantFlowState(
      currentStep: currentStep ?? this.currentStep,
      selectedSpecies: selectedSpecies ?? this.selectedSpecies,
      plantName: plantName ?? this.plantName,
      customPhotoPath: clearCustomPhoto
          ? null
          : (customPhotoPath ?? this.customPhotoPath),
      growthStage: growthStage ?? this.growthStage,
      initialHeightCm: initialHeightCm ?? this.initialHeightCm,
      isIndoor: isIndoor ?? this.isIndoor,
      potSize: potSize ?? this.potSize,
      selectedRoom: selectedRoom ?? this.selectedRoom,
      selectedLight: selectedLight ?? this.selectedLight,
      plantedDate: plantedDate ?? this.plantedDate,
      timeCapsuleMessage: timeCapsuleMessage ?? this.timeCapsuleMessage,
      enableTimeCapsule: enableTimeCapsule ?? this.enableTimeCapsule,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      entryPoint: entryPoint ?? this.entryPoint,
    );
  }
}

class AddPlantFlowController extends StateNotifier<AddPlantFlowState> {
  final PlantRepository _plantRepo;
  final String userId;

  AddPlantFlowController({
    PlantRepository? plantRepo,
    AddPlantEntryPoint entryPoint = AddPlantEntryPoint.fabHome,
    this.userId = 'usr_default',
  })  : _plantRepo = plantRepo ?? PlantRepository(),
        super(AddPlantFlowState.initial(entryPoint));

  void setSpecies(PlantCatalogModel species) {
    state = state.copyWith(
      selectedSpecies: species,
      plantName: species.commonName,
      customPhotoPath: species.imageUrl,
      selectedLight: species.sunlightLevel ?? state.selectedLight,
      currentStep: 1,
    );
  }

  void proceedFromPreviewToWizard() {
    state = state.copyWith(currentStep: 2);
  }

  void setPlantName(String name) {
    state = state.copyWith(plantName: name);
  }

  void setGrowthStage(String stage) {
    state = state.copyWith(
      growthStage: stage,
      initialHeightCm: stage == 'seed' && state.initialHeightCm == 25.0
          ? 2.0
          : (stage == 'mature' && state.initialHeightCm == 2.0 ? 25.0 : state.initialHeightCm),
    );
  }

  void setInitialHeight(double height) {
    state = state.copyWith(initialHeightCm: height);
  }

  void setPhotoPath(String? path) {
    if (path == null) {
      state = state.copyWith(clearCustomPhoto: true);
    } else {
      state = state.copyWith(customPhotoPath: path);
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

  void nextStep() {
    if (state.currentStep < 7 && state.isCurrentStepValid) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 7) {
      state = state.copyWith(currentStep: step);
    }
  }

  Future<AddPlantResult> confirmAndSave() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await PreferenceHandler.getUser();
      final effectiveUserId = (userId != 'usr_default' && userId.isNotEmpty)
          ? userId
          : ((user?.id != null && user!.id! > 0)
              ? user.id.toString()
              : (userId.isNotEmpty ? userId : '1'));

      final name = state.plantName.trim().isNotEmpty
          ? state.plantName.trim()
          : (state.selectedSpecies?.commonName ?? 'Tanaman Baru');

      final customPhoto = state.customPhotoPath;
      final coverPhoto = customPhoto ??
          state.selectedSpecies?.imageUrl ??
          state.selectedSpecies?.localImagePath;

      final result = await _plantRepo.addPlant(
        userId: effectiveUserId,
        species: state.selectedSpecies,
        catalogId: state.selectedSpecies?.id,
        nickname: name,
        isIndoor: state.isIndoor,
        sunlightCondition: state.selectedLight,
        potSize: state.potSize,
        windowDistance: state.selectedRoom,
        initialHeightCm: state.initialHeightCm,
        growthStage: state.growthStage,
        coverPhotoPath: coverPhoto,
        customPhotoPath: customPhoto,
        timeCapsule: state.timeCapsuleDraft,
        defaultWateringInterval:
            state.selectedSpecies?.defaultWateringInterval ?? 4,
      );

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final addPlantFlowControllerProvider = StateNotifierProvider.autoDispose
    .family<AddPlantFlowController, AddPlantFlowState, AddPlantEntryPoint>(
  (ref, entryPoint) {
    return AddPlantFlowController(entryPoint: entryPoint);
  },
);
