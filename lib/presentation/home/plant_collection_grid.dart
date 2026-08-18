import 'package:flutter/material.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/presentation/add_plant/add_plant_flow_controller.dart';
import 'package:plenty/presentation/add_plant/add_plant_flow_screen.dart';
import 'package:plenty/presentation/home/add_new_plant_card.dart';
import 'package:plenty/presentation/home/plant_card.dart';
import 'package:plenty/presentation/plant_details/plant_details_screen.dart';

class PlantCollectionGrid extends StatelessWidget {
  final List<PlantModel> plants;

  const PlantCollectionGrid({super.key, required this.plants});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: plants.length + 1,
      itemBuilder: (context, index) {
        if (index == plants.length) {
          return AddNewPlantCard(
            onTap: () {
              context.push(
                const AddPlantFlowScreen(
                  entryPoint: AddPlantEntryPoint.fabHome,
                ),
              );
            },
          );
        }

        final plant = plants[index];
        return PlantCard(
          plant: plant,
          onTap: () {
            context.push(PlantDetailsScreen(plant: plant));
          },
        );
      },
    );
  }
}
