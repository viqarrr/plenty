import 'package:flutter/material.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/presentation/controllers/home_controller.dart';
import 'package:plenty/features/garden/presentation/widgets/add_new_plant_card.dart';
import 'package:plenty/features/garden/presentation/widgets/plant_card.dart';
import 'package:plenty/features/garden/presentation/screens/plant_details_screen.dart';
import 'package:plenty/features/plant_catalog/presentation/controllers/add_plant_flow_controller.dart';
import 'package:plenty/features/plant_catalog/presentation/screens/add_plant_flow_screen.dart';

class PlantCollectionGrid extends StatelessWidget {
  final List<PlantModel> plants;
  final HomeController? controller;
  final VoidCallback? onPlantChanged;

  const PlantCollectionGrid({
    super.key,
    required this.plants,
    this.controller,
    this.onPlantChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == plants.length) {
            return AddNewPlantCard(
              onTap: () async {
                await context.push(
                  const AddPlantFlowScreen(
                    entryPoint: AddPlantEntryPoint.fabHome,
                  ),
                );
                controller?.loadDashboard();
                onPlantChanged?.call();
              },
            );
          }

          final plant = plants[index];
          return PlantCard(
            plant: plant,
            onTap: () async {
              final result = await context.push<bool?>(
                PlantDetailsScreen(
                  plant: plant,
                  homeController: controller,
                ),
              );
              if (result == true || controller != null) {
                controller?.loadDashboard();
              }
              onPlantChanged?.call();
            },
          );
        },
        childCount: plants.length + 1,
      ),
    );
  }
}
