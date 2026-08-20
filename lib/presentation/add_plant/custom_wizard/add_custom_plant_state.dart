import 'package:flutter/foundation.dart';
import 'package:plenty/data/models/time_capsule_model.dart';

/// Form state aggregating all steps of the Add Custom Plant Wizard flow.
@immutable
class AddCustomPlantState {
  final int currentStep;
  final String plantName;
  final String? imagePath;
  final String growthStage;
  final double initialHeightCm;
  final bool isIndoor;
  final String potSize;
  final String selectedRoom;
  final String selectedLight;
  final DateTime plantedDate;
  final String? timeCapsuleMessage;
  final bool enableTimeCapsule;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const AddCustomPlantState({
    this.currentStep = 0,
    this.plantName = '',
    this.imagePath,
    this.growthStage = 'mature',
    this.initialHeightCm = 25.0,
    this.isIndoor = true,
    this.potSize = 'Ada Lubang Drainase',
    this.selectedRoom = 'Ruang Tamu',
    this.selectedLight = 'Sinar Tidak Langsung Terang',
    required this.plantedDate,
    this.timeCapsuleMessage,
    this.enableTimeCapsule = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  /// Factory for initial state with today's date
  factory AddCustomPlantState.initial() => AddCustomPlantState(
        plantedDate: DateTime.now(),
      );

  /// Environment string format ('Indoor' or 'Outdoor')
  String get environment => isIndoor ? 'Indoor' : 'Outdoor';

  /// Validates whether the current step satisfies form constraints to proceed
  bool get isCurrentStepValid {
    switch (currentStep) {
      case 0:
        return plantName.trim().isNotEmpty;
      case 1:
        return growthStage.isNotEmpty;
      case 2:
        return potSize.isNotEmpty;
      case 3:
        return selectedRoom.trim().isNotEmpty;
      case 4:
        return selectedLight.trim().isNotEmpty;
      case 5:
        return true;
      default:
        return true;
    }
  }

  /// Converts time capsule input into draft if enabled and not empty
  TimeCapsuleDraft? get timeCapsuleDraft {
    if (!enableTimeCapsule ||
        timeCapsuleMessage == null ||
        timeCapsuleMessage!.trim().isEmpty) {
      return null;
    }
    return TimeCapsuleDraft(
      message: timeCapsuleMessage!.trim(),
      photoPath: imagePath,
      durationMonths: 1,
    );
  }

  AddCustomPlantState copyWith({
    int? currentStep,
    String? plantName,
    String? imagePath,
    String? growthStage,
    double? initialHeightCm,
    bool? isIndoor,
    String? potSize,
    String? selectedRoom,
    String? selectedLight,
    DateTime? plantedDate,
    String? timeCapsuleMessage,
    bool? enableTimeCapsule,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
    bool clearImagePath = false,
  }) {
    return AddCustomPlantState(
      currentStep: currentStep ?? this.currentStep,
      plantName: plantName ?? this.plantName,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      growthStage: growthStage ?? this.growthStage,
      initialHeightCm: initialHeightCm ?? this.initialHeightCm,
      isIndoor: isIndoor ?? this.isIndoor,
      potSize: potSize ?? this.potSize,
      selectedRoom: selectedRoom ?? this.selectedRoom,
      selectedLight: selectedLight ?? this.selectedLight,
      plantedDate: plantedDate ?? this.plantedDate,
      timeCapsuleMessage: timeCapsuleMessage ?? this.timeCapsuleMessage,
      enableTimeCapsule: enableTimeCapsule ?? this.enableTimeCapsule,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
