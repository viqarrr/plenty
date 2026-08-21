import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/utils/image_picker_helper.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/features/plant_catalog/presentation/controllers/add_custom_plant_controller.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_area_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_environment_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_growth_stage_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_light_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_name_photo_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_time_capsule_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/wizard_step_progress.dart';

/// Parent Screen for the Multi-Step "Add Custom Plant" Wizard Flow.
class AddCustomPlantWizardScreen extends StatefulWidget {
  final AddCustomPlantController? controller;

  const AddCustomPlantWizardScreen({super.key, this.controller});

  @override
  State<AddCustomPlantWizardScreen> createState() =>
      _AddCustomPlantWizardScreenState();
}

class _AddCustomPlantWizardScreenState
    extends State<AddCustomPlantWizardScreen> {
  late final PageController _pageController;
  late final AddCustomPlantController _controller;

  static const List<String> _stepTitles = [
    'Nama & Foto',
    'Asal Pertumbuhan',
    'Lingkungan',
    'Lokasi',
    'Pencahayaan',
    'Kapsul Waktu',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _controller = widget.controller ?? AddCustomPlantController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final next = _controller.state.currentStep;
    if (_pageController.hasClients && _pageController.page?.round() != next) {
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final isLastStep = state.currentStep == 5;

        return Scaffold(
          backgroundColor: AppColors.canvasDefault,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () {
                if (state.currentStep > 0) {
                  _controller.previousStep();
                } else {
                  context.pop();
                }
              },
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                WizardStepProgress(
                  currentStep: state.currentStep,
                  totalSteps: 6,
                  stepTitle: _stepTitles[state.currentStep],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      WizardGrowthStageStep(
                        selectedStage: state.growthStage,
                        onStageChanged: _controller.setGrowthStage,
                      ),
                      WizardEnvironmentStep(
                        environment: state.environment,
                        drainage: state.potSize,
                        onEnvironmentChanged: _controller.setEnvironment,
                        onDrainageChanged: _controller.setDrainage,
                      ),
                      WizardAreaStep(
                        selectedRoom: state.selectedRoom,
                        onRoomSelected: _controller.setRoom,
                      ),
                      WizardLightStep(
                        selectedLight: state.selectedLight,
                        onLightSelected: _controller.setLight,
                      ),
                      WizardNamePhotoStep(
                        plantName: state.plantName,
                        imagePath: state.imagePath,
                        initialHeightCm: state.initialHeightCm,
                        onNameChanged: _controller.setPlantName,
                        onHeightChanged: _controller.setInitialHeight,
                        onPickImage: () {
                          ImagePickerHelper.showPickerSheet(
                            context: context,
                            showRemoveOption: state.imagePath != null,
                            onImageSelected: (path) =>
                                _controller.setImagePath(path),
                          );
                        },
                        onRemoveImage: () => _controller.setImagePath(null),
                      ),
                      WizardTimeCapsuleStep(
                        plantedDate: state.plantedDate,
                        timeCapsuleMessage: state.timeCapsuleMessage,
                        enableTimeCapsule: state.enableTimeCapsule,
                        onDateChanged: _controller.setPlantedDate,
                        onMessageChanged: _controller.setTimeCapsuleMessage,
                        onToggleTimeCapsule: _controller.toggleTimeCapsule,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.canvasDefault,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (state.currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: CustomButton(
                        text: 'Kembali',
                        isOutlined: true,
                        height: 50,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: state.isSubmitting
                            ? null
                            : () => _controller.previousStep(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: isLastStep ? 'Simpan Tanaman' : 'Lanjutkan',
                      isLoading: state.isSubmitting,
                      icon: isLastStep
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward,
                      height: 50,
                      borderRadius: BorderRadius.circular(14),
                      onPressed: !state.isCurrentStepValid
                          ? null
                          : () async {
                              if (isLastStep) {
                                final success =
                                    await _controller.submitCustomPlant();
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tanaman berhasil ditambahkan ke koleksi!',
                                      ),
                                      backgroundColor: AppColors.forest,
                                    ),
                                  );
                                  context.pop();
                                }
                              } else {
                                _controller.nextStep();
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
