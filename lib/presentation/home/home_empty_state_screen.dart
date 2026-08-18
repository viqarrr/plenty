import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/presentation/add_plant/add_plant_flow_controller.dart';
import 'package:plenty/presentation/add_plant/add_plant_flow_screen.dart';

class HomeEmptyStateScreen extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const HomeEmptyStateScreen({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.forest,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 82, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/empty_state.json',
                width: 220,
                height: 200,
                fit: BoxFit.contain,
                repeat: true,
              ),
              const SizedBox(height: 16),
              Text(
                'Koleksimu Masih Kosong',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.inkSoft,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada tanaman yang kamu koleksi. Mulai tambahkan tanaman pertamamu dan nikmati kemudahan mencatat pertumbuhannya!',
                textAlign: TextAlign.center,
                style: AppTypography.bodyRegular.copyWith(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              CustomButton(
                text: 'Tambah Tanaman Sekarang',
                icon: Icons.add,
                height: 52,
                borderRadius: BorderRadius.circular(30),
                onPressed: () {
                  context.push(
                    const AddPlantFlowScreen(
                      entryPoint: AddPlantEntryPoint.emptyState,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
