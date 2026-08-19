import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/add_custom_plant_controller.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/steps/wizard_area_step.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/steps/wizard_environment_step.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/steps/wizard_light_step.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/steps/wizard_name_photo_step.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/steps/wizard_time_capsule_step.dart';
import 'package:plenty/presentation/add_plant/custom_wizard/wizard_step_progress.dart';

/// Parent Screen for the Multi-Step "Add Custom Plant" Wizard Flow.
class AddCustomPlantWizardScreen extends ConsumerStatefulWidget {
  const AddCustomPlantWizardScreen({super.key});

  @override
  ConsumerState<AddCustomPlantWizardScreen> createState() =>
      _AddCustomPlantWizardScreenState();
}

class _AddCustomPlantWizardScreenState
    extends ConsumerState<AddCustomPlantWizardScreen> {
  late final PageController _pageController;

  static const List<String> _stepTitles = [
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addCustomPlantControllerProvider);
    final controller = ref.read(addCustomPlantControllerProvider.notifier);

    // Sync PageController if step is updated from controller
    ref.listen<int>(
      addCustomPlantControllerProvider.select((s) => s.currentStep),
      (_, next) {
        if (_pageController.hasClients && _pageController.page?.round() != next) {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
    );

    final isLastStep = state.currentStep == 4;

    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (state.currentStep > 0) {
              controller.previousStep();
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          'Tambah Tanaman Kustom',
          style: AppTypography.title2Bold.copyWith(color: AppColors.ink),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            WizardStepProgress(
              currentStep: state.currentStep,
              totalSteps: 5,
              stepTitle: _stepTitles[state.currentStep],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  WizardNamePhotoStep(
                    plantName: state.plantName,
                    imagePath: state.imagePath,
                    onNameChanged: controller.setPlantName,
                    onPickImage: () {
                      // Demo asset picker for custom plant
                      controller.setImagePath('assets/images/custom_plant.png');
                    },
                    onRemoveImage: () => controller.setImagePath(null),
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
                  WizardTimeCapsuleStep(
                    plantedDate: state.plantedDate,
                    timeCapsuleMessage: state.timeCapsuleMessage,
                    enableTimeCapsule: state.enableTimeCapsule,
                    onDateChanged: controller.setPlantedDate,
                    onMessageChanged: controller.setTimeCapsuleMessage,
                    onToggleTimeCapsule: controller.toggleTimeCapsule,
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
                        : () => controller.previousStep(),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: isLastStep ? 'Simpan Tanaman' : 'Lanjutkan',
                  isLoading: state.isSubmitting,
                  icon: isLastStep ? Icons.check_circle_outline : Icons.arrow_forward,
                  height: 50,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: !state.isCurrentStepValid
                      ? null
                      : () async {
                          if (isLastStep) {
                            final success = await controller.submitCustomPlant();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tanaman berhasil ditambahkan ke koleksi!'),
                                  backgroundColor: AppColors.forest,
                                ),
                              );
                              context.pop();
                            }
                          } else {
                            controller.nextStep();
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
