import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/presentation/add_plant/add_plant_flow_controller.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/steps/wizard_area_step.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/steps/wizard_environment_step.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/steps/wizard_light_step.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/steps/wizard_name_photo_step.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/steps/wizard_time_capsule_step.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/wizard_step_progress.dart';
import 'package:plenty/presentation/add_plant/select_species_step.dart';
import 'package:plenty/presentation/add_plant/species_detail_preview_screen.dart';
import 'package:plenty/presentation/gamification/first_reward_popup.dart';
import 'package:plenty/presentation/home/home_controller.dart';
import 'package:plenty/presentation/home/home_screen.dart';

/// Screen orchestrating species selection -> botanical preview -> 5-step custom wizard adoption flow.
/// Utilizes smooth PageView transitions across wizard steps inspired by RegisterScreen.
class AddPlantFlowScreen extends ConsumerStatefulWidget {
  final AddPlantEntryPoint entryPoint;

  const AddPlantFlowScreen({
    super.key,
    this.entryPoint = AddPlantEntryPoint.fabHome,
  });

  @override
  ConsumerState<AddPlantFlowScreen> createState() => _AddPlantFlowScreenState();
}

class _AddPlantFlowScreenState extends ConsumerState<AddPlantFlowScreen> {
  late final PageController _pageController;

  static const List<String> _wizardStepTitles = [
    'Nama & Foto',
    'Lingkungan',
    'Lokasi',
    'Pencahayaan',
    'Kapsul Waktu',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
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
    final state = ref.watch(addPlantFlowControllerProvider(widget.entryPoint));
    final controller = ref.read(
      addPlantFlowControllerProvider(widget.entryPoint).notifier,
    );

    // Sync PageController whenever wizardStepIndex changes
    ref.listen<int>(
      addPlantFlowControllerProvider(
        widget.entryPoint,
      ).select((s) => s.wizardStepIndex),
      (_, next) {
        if (_pageController.hasClients &&
            _pageController.page?.round() != next) {
          _navigateToWizardPage(next);
        }
      },
    );

    // Step 1: Botanical detail preview with sticky CTA
    if (state.currentStep == 1 && state.selectedSpecies != null) {
      return SpeciesDetailPreviewScreen(
        species: state.selectedSpecies!,
        onAddToCollection: () {
          controller.proceedFromPreviewToWizard();
        },
      );
    }

    // Step 0: Catalog Species Selection Step
    if (state.currentStep == 0) {
      return Scaffold(
        backgroundColor: AppColors.canvasDefault,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () {
              state.isLoading
                  ? null
                  : () {
                      if (state.currentStep > 2) {
                        controller.previousStep();
                      } else {
                        controller.goToStep(1);
                      }
                    };
            },
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

    // Steps 2 - 6: 5-Step Custom Wizard with Smooth PageView Transitions
    final isLastStep = state.currentStep == 6;

    final wizardPages = [
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
      WizardTimeCapsuleStep(
        plantedDate: state.plantedDate,
        timeCapsuleMessage: state.timeCapsuleMessage,
        enableTimeCapsule: state.enableTimeCapsule,
        onDateChanged: controller.setPlantedDate,
        onMessageChanged: controller.setTimeCapsuleMessage,
        onToggleTimeCapsule: controller.toggleTimeCapsule,
      ),
      WizardNamePhotoStep(
        plantName: state.plantName,
        imagePath: state.customPhotoPath,
        onNameChanged: controller.setPlantName,
        onPickImage: () {
          controller.setPhotoPath('assets/images/custom_plant.png');
        },
        onRemoveImage: () => controller.setPhotoPath(null),
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
              controller.goToStep(1); // Return to botanical detail preview
            }
          },
        ),
        title: Text(
          'Detail Adopsi Tanaman',
          style: AppTypography.title2Bold.copyWith(color: AppColors.ink),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Responsive step progress indicator
            WizardStepProgress(
              currentStep: state.wizardStepIndex,
              totalSteps: 5,
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

                      ref.read(homeControllerProvider.notifier).loadDashboard();

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
