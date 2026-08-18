import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/data/repositories/plant_repository.dart';

enum AddPlantEntryPoint { onboarding, emptyState, fabHome }

class AddPlantFlowState {
  final int currentStep;
  final PlantCatalogModel? selectedSpecies;
  final bool isIndoor;
  final String sunlightCondition;
  final String potSize;
  final String windowDistance;
  final String nickname;
  final double initialHeightCm;
  final TimeCapsuleDraft? timeCapsuleDraft;
  final bool isLoading;
  final String? errorMessage;
  final AddPlantEntryPoint entryPoint;

  const AddPlantFlowState({
    this.currentStep = 0,
    this.selectedSpecies,
    this.isIndoor = true,
    this.sunlightCondition = 'Sinar Tidak Langsung',
    this.potSize = 'Ada Lubang Drainase',
    this.windowDistance = 'Dekat Jendela (1-1.5 meter)',
    this.nickname = '',
    this.initialHeightCm = 30.0,
    this.timeCapsuleDraft,
    this.isLoading = false,
    this.errorMessage,
    this.entryPoint = AddPlantEntryPoint.fabHome,
  });

  AddPlantFlowState copyWith({
    int? currentStep,
    PlantCatalogModel? selectedSpecies,
    bool? isIndoor,
    String? sunlightCondition,
    String? potSize,
    String? windowDistance,
    String? nickname,
    double? initialHeightCm,
    TimeCapsuleDraft? timeCapsuleDraft,
    bool clearTimeCapsule = false,
    bool? isLoading,
    String? errorMessage,
    AddPlantEntryPoint? entryPoint,
  }) {
    return AddPlantFlowState(
      currentStep: currentStep ?? this.currentStep,
      selectedSpecies: selectedSpecies ?? this.selectedSpecies,
      isIndoor: isIndoor ?? this.isIndoor,
      sunlightCondition: sunlightCondition ?? this.sunlightCondition,
      potSize: potSize ?? this.potSize,
      windowDistance: windowDistance ?? this.windowDistance,
      nickname: nickname ?? this.nickname,
      initialHeightCm: initialHeightCm ?? this.initialHeightCm,
      timeCapsuleDraft: clearTimeCapsule
          ? null
          : (timeCapsuleDraft ?? this.timeCapsuleDraft),
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
        super(AddPlantFlowState(entryPoint: entryPoint));

  void setSpecies(PlantCatalogModel species) {
    state = state.copyWith(
      selectedSpecies: species,
      nickname: state.nickname.isEmpty ? species.commonName : state.nickname,
      currentStep: 1,
    );
  }

  void setEnvironment({
    required bool isIndoor,
    String? sunlight,
    String? potSize,
    String? windowDistance,
  }) {
    state = state.copyWith(
      isIndoor: isIndoor,
      sunlightCondition: sunlight ?? state.sunlightCondition,
      potSize: potSize ?? state.potSize,
      windowDistance: windowDistance ?? state.windowDistance,
      currentStep: 2,
    );
  }

  void setNicknameAndHeight(String nickname, double? initialHeightCm) {
    state = state.copyWith(
      nickname: nickname.trim(),
      initialHeightCm: initialHeightCm ?? state.initialHeightCm,
    );
  }

  void setTimeCapsule(TimeCapsuleDraft? draft) {
    if (draft == null) {
      state = state.copyWith(clearTimeCapsule: true);
    } else {
      state = state.copyWith(timeCapsuleDraft: draft);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      state = state.copyWith(currentStep: step);
    }
  }

  Future<AddPlantResult> confirmAndSave() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final name = state.nickname.isNotEmpty
          ? state.nickname
          : (state.selectedSpecies?.commonName ?? 'Tanaman Baru');

      final result = await _plantRepo.addPlant(
        userId: userId,
        species: state.selectedSpecies,
        catalogId: state.selectedSpecies?.id,
        nickname: name,
        isIndoor: state.isIndoor,
        sunlightCondition: state.sunlightCondition,
        potSize: state.potSize,
        windowDistance: state.windowDistance,
        initialHeightCm: state.initialHeightCm,
        coverPhotoPath: state.selectedSpecies?.localImagePath,
        timeCapsule: state.timeCapsuleDraft,
        defaultWateringInterval:
            state.selectedSpecies?.defaultWateringInterval ?? 3,
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
