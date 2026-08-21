import 'package:flutter/foundation.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository.dart';
import 'package:plenty/features/plant_catalog/domain/models/plant_catalog_model.dart';

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

class AddPlantFlowController extends ChangeNotifier {
  final PlantRepository _plantRepo;
  final String userId;

  late AddPlantFlowState _state;
  AddPlantFlowState get state => _state;

  bool _isDisposed = false;

  AddPlantFlowController({
    PlantRepository? plantRepo,
    AddPlantEntryPoint entryPoint = AddPlantEntryPoint.fabHome,
    this.userId = 'usr_default',
  })  : _plantRepo = plantRepo ?? PlantRepository(),
        _state = AddPlantFlowState.initial(entryPoint);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _updateState(AddPlantFlowState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  void setSpecies(PlantCatalogModel species) {
    _updateState(
      _state.copyWith(
        selectedSpecies: species,
        plantName: species.commonName,
        customPhotoPath: species.imageUrl,
        selectedLight: species.sunlightLevel ?? _state.selectedLight,
        currentStep: 1,
      ),
    );
  }

  void proceedFromPreviewToWizard() {
    _updateState(_state.copyWith(currentStep: 2));
  }

  void setPlantName(String name) {
    _updateState(_state.copyWith(plantName: name));
  }

  void setGrowthStage(String stage) {
    _updateState(
      _state.copyWith(
        growthStage: stage,
        initialHeightCm: stage == 'seed' && _state.initialHeightCm == 25.0
            ? 2.0
            : (stage == 'mature' && _state.initialHeightCm == 2.0 ? 25.0 : _state.initialHeightCm),
      ),
    );
  }

  void setInitialHeight(double height) {
    _updateState(_state.copyWith(initialHeightCm: height));
  }

  void setPhotoPath(String? path) {
    if (path == null) {
      _updateState(_state.copyWith(clearCustomPhoto: true));
    } else {
      _updateState(_state.copyWith(customPhotoPath: path));
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

  void nextStep() {
    if (_state.currentStep < 7 && _state.isCurrentStepValid) {
      _updateState(_state.copyWith(currentStep: _state.currentStep + 1));
    }
  }

  void previousStep() {
    if (_state.currentStep > 0) {
      _updateState(_state.copyWith(currentStep: _state.currentStep - 1));
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 7) {
      _updateState(_state.copyWith(currentStep: step));
    }
  }

  Future<AddPlantResult> confirmAndSave() async {
    _updateState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = await PreferenceHandler.getUser();
      final effectiveUserId = (userId != 'usr_default' && userId.isNotEmpty)
          ? userId
          : ((user?.id != null && user!.id! > 0)
              ? user.id.toString()
              : (userId.isNotEmpty ? userId : '1'));

      final name = _state.plantName.trim().isNotEmpty
          ? _state.plantName.trim()
          : (_state.selectedSpecies?.commonName ?? 'Tanaman Baru');

      final customPhoto = _state.customPhotoPath;
      final coverPhoto = customPhoto ??
          _state.selectedSpecies?.imageUrl ??
          _state.selectedSpecies?.localImagePath;

      final result = await _plantRepo.addPlant(
        userId: effectiveUserId,
        species: _state.selectedSpecies,
        catalogId: _state.selectedSpecies?.id,
        nickname: name,
        isIndoor: _state.isIndoor,
        sunlightCondition: _state.selectedLight,
        potSize: _state.potSize,
        site: _state.selectedRoom,
        windowDistance: _state.selectedRoom,
        initialHeightCm: _state.initialHeightCm,
        growthStage: _state.growthStage,
        coverPhotoPath: coverPhoto,
        customPhotoPath: customPhoto,
        timeCapsule: _state.timeCapsuleDraft,
        defaultWateringInterval:
            _state.selectedSpecies?.defaultWateringInterval ?? 4,
      );

      _updateState(_state.copyWith(isLoading: false));
      return result;
    } catch (e) {
      _updateState(_state.copyWith(isLoading: false, errorMessage: e.toString()));
      rethrow;
    }
  }
}
