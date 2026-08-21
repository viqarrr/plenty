import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/utils/image_picker_helper.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/features/plant_catalog/presentation/controllers/add_plant_flow_controller.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_area_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_environment_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_growth_stage_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_light_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_name_photo_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/steps/wizard_time_capsule_step.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/wizard_step_progress.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/select_species_step.dart';
import 'package:plenty/features/plant_catalog/presentation/screens/species_detail_preview_screen.dart';
import 'package:plenty/features/garden/presentation/widgets/first_reward_popup.dart';
import 'package:plenty/features/garden/presentation/screens/home_screen.dart';

/// Screen orchestrating species selection -> botanical preview -> 6-step custom wizard adoption flow.
class AddPlantFlowScreen extends StatefulWidget {
  final AddPlantEntryPoint entryPoint;
  final AddPlantFlowController? controller;

  const AddPlantFlowScreen({
    super.key,
    this.entryPoint = AddPlantEntryPoint.fabHome,
    this.controller,
  });

  @override
  State<AddPlantFlowScreen> createState() => _AddPlantFlowScreenState();
}

class _AddPlantFlowScreenState extends State<AddPlantFlowScreen> {
  late final PageController _pageController;
  late final AddPlantFlowController _controller;

  static const List<String> _wizardStepTitles = [
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
    _controller =
        widget.controller ?? AddPlantFlowController(entryPoint: widget.entryPoint);
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final next = _controller.state.wizardStepIndex;
    if (_pageController.hasClients && _pageController.page?.round() != next) {
      _navigateToWizardPage(next);
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

  void _navigateToWizardPage(int pageIndex) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return PopScope(
          canPop: state.currentStep == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (state.currentStep == 1) {
              _controller.goToStep(0);
            } else if (state.currentStep > 2) {
              _controller.previousStep();
            } else if (state.currentStep == 2) {
              _controller.goToStep(1);
            }
          },
          child: _buildContent(context, state, _controller),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AddPlantFlowState state,
    AddPlantFlowController controller,
  ) {
    if (state.currentStep == 0) {
      return Scaffold(
        backgroundColor: AppColors.canvasDefault,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SelectSpeciesStep(
            selectedSpecies: state.selectedSpecies,
            onSpeciesSelected: (species) {
              controller.setSpecies(species);
            },
          ),
        ),
      );
    }

    if (state.currentStep == 1 && state.selectedSpecies != null) {
      return SpeciesDetailPreviewScreen(
        species: state.selectedSpecies!,
        onAddToCollection: () => controller.proceedFromPreviewToWizard(),
        onBack: () => controller.goToStep(0),
      );
    }

    final isLastStep = state.currentStep == 7;

    final wizardPages = [
      WizardGrowthStageStep(
        selectedStage: state.growthStage,
        onStageChanged: controller.setGrowthStage,
      ),
      WizardEnvironmentStep(
        environment: state.environment,
        drainage: state.potSize,
        onEnvironmentChanged: controller.setEnvironment,
        onDrainageChanged: controller.setDrainage,
      ),
      WizardAreaStep(
        selectedRoom: state.selectedRoom,
        onRoomSelected: controller.setRoom,
      ),
      WizardLightStep(
        selectedLight: state.selectedLight,
        onLightSelected: controller.setLight,
      ),
      WizardNamePhotoStep(
        plantName: state.plantName,
        imagePath: state.customPhotoPath,
        initialHeightCm: state.initialHeightCm,
        onNameChanged: controller.setPlantName,
        onHeightChanged: controller.setInitialHeight,
        onPickImage: () {
          ImagePickerHelper.showPickerSheet(
            context: context,
            showRemoveOption: state.customPhotoPath != null,
            onImageSelected: (path) => controller.setPhotoPath(path),
          );
        },
        onRemoveImage: () => controller.setPhotoPath(null),
      ),
      WizardTimeCapsuleStep(
        plantedDate: state.plantedDate,
        timeCapsuleMessage: state.timeCapsuleMessage,
        enableTimeCapsule: state.enableTimeCapsule,
        onDateChanged: controller.setPlantedDate,
        onMessageChanged: controller.setTimeCapsuleMessage,
        onToggleTimeCapsule: controller.toggleTimeCapsule,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (state.currentStep > 2) {
              controller.previousStep();
            } else {
              controller.goToStep(1);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            WizardStepProgress(
              currentStep: state.wizardStepIndex,
              totalSteps: 6,
              stepTitle: _wizardStepTitles[state.wizardStepIndex],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: wizardPages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: isLastStep ? 'Simpan Tanaman' : 'Lanjutkan',
            isLoading: state.isLoading,
            icon: isLastStep ? Icons.check_circle : Icons.arrow_forward,
            height: 50,
            borderRadius: BorderRadius.circular(30),
            onPressed: !state.isCurrentStepValid
                ? null
                : () async {
                    if (isLastStep) {
                      final result = await controller.confirmAndSave();

                      if (context.mounted) {
                        if (result.isFirstPlant) {
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => FirstRewardPopup(
                              plantNickname: result.plant.nickname,
                              onDismiss: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        }

                        if (context.mounted) {
                          context.pushAndRemoveAll(const HomeScreen());
                        }
                      }
                    } else {
                      controller.nextStep();
                    }
                  },
          ),
        ),
      ),
    );
  }
}
