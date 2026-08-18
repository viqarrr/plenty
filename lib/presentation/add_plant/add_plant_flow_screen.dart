import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/presentation/add_plant/add_plant_flow_controller.dart';
import 'package:plenty/presentation/add_plant/environment_conditions_step.dart';
import 'package:plenty/presentation/add_plant/nickname_height_step.dart';
import 'package:plenty/presentation/add_plant/select_species_step.dart';
import 'package:plenty/presentation/gamification/first_reward_popup.dart';
import 'package:plenty/presentation/home/home_screen.dart';

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
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addPlantFlowControllerProvider(widget.entryPoint));
    final controller = ref.read(
      addPlantFlowControllerProvider(widget.entryPoint).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (state.currentStep > 0) {
              controller.goToStep(state.currentStep - 1);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (state.currentStep + 1) / 3,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
                color: AppColors.forest,
                backgroundColor: AppColors.borderSubtle,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: switch (state.currentStep) {
                  0 => SelectSpeciesStep(
                    selectedSpecies: state.selectedSpecies,
                    onSpeciesSelected: (species) {
                      _nicknameController.text = species.commonName;
                      controller.setSpecies(species);
                    },
                  ),
                  1 => EnvironmentConditionsStep(
                    isIndoor: state.isIndoor,
                    sunlight: state.sunlightCondition,
                    potSize: state.potSize,
                    windowDistance: state.windowDistance,
                    onEnvironmentChanged:
                        ({
                          required isIndoor,
                          sunlight,
                          potSize,
                          windowDistance,
                        }) {
                          controller.setEnvironment(
                            isIndoor: isIndoor,
                            sunlight: sunlight,
                            potSize: potSize,
                            windowDistance: windowDistance,
                          );
                        },
                  ),
                  2 => NicknameHeightStep(
                    nicknameController: _nicknameController,
                    currentHeightCm: state.initialHeightCm,
                    onHeightChanged: (val) {
                      controller.setNicknameAndHeight(
                        _nicknameController.text,
                        val,
                      );
                    },
                    timeCapsuleDraft: state.timeCapsuleDraft,
                    onTimeCapsuleChanged: (draft) {
                      if (draft != null && draft.message.isEmpty) {
                        controller.setTimeCapsule(null);
                      } else {
                        controller.setTimeCapsule(draft);
                      }
                    },
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
              if (state.currentStep == 1) ...[
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Lanjutkan',
                  height: 52,
                  borderRadius: BorderRadius.circular(30),
                  onPressed: () {
                    controller.goToStep(2);
                  },
                ),
              ] else if (state.currentStep == 2) ...[
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Simpan Tanaman',
                  height: 52,
                  borderRadius: BorderRadius.circular(30),
                  isLoading: state.isLoading,
                  onPressed: () async {
                    controller.setNicknameAndHeight(
                      _nicknameController.text,
                      state.initialHeightCm,
                    );
                    final result = await controller.confirmAndSave();

                    if (!context.mounted) return;

                    if (result.isFirstPlant) {
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => FirstRewardPopup(
                          plantNickname: result.plant.nickname,
                          onDismiss: () => Navigator.of(context).pop(),
                        ),
                      );
                    }

                    if (!context.mounted) return;
                    context.pushAndRemoveAll(const HomeScreen());
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
