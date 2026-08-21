import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/widgets/custom_button.dart';
import 'package:plenty/features/plant_catalog/domain/models/plant_catalog_model.dart';
import 'package:plenty/features/garden/presentation/widgets/plant_stat_card.dart';
import 'package:plenty/features/garden/presentation/widgets/plant_toxicity_banner.dart';

/// Screen displaying botanical information of a catalog species before adoption.
/// Reads directly from [PlantCatalogModel] botanical attributes without hardcoded conditionals.
class SpeciesDetailPreviewScreen extends StatelessWidget {
  final PlantCatalogModel species;
  final VoidCallback onAddToCollection;
  final VoidCallback? onBack;

  const SpeciesDetailPreviewScreen({
    super.key,
    required this.species,
    required this.onAddToCollection,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.canvasDefault,
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Names & Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              species.commonName,
                              style: AppTypography.displayLarge.copyWith(
                                fontSize: 26,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            if (species.scientificName != null &&
                                species.scientificName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                species.scientificName!,
                                style: AppTypography.footnoteRegular.copyWith(
                                  color: AppColors.muted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (species.careLevel != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.pastelGreenBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.forest.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      species.careLevel!,
                                      style: AppTypography.caption1Bold
                                          .copyWith(color: AppColors.forest),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: species.isToxic
                                        ? AppColors.pastelRedBg
                                        : AppColors.petFriendlyBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          (species.isToxic
                                                  ? AppColors.pastelRedText
                                                  : AppColors.petFriendlyText)
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        species.isToxic
                                            ? Icons.warning_amber_rounded
                                            : Icons.pets,
                                        size: 14,
                                        color: species.isToxic
                                            ? AppColors.pastelRedText
                                            : AppColors.petFriendlyText,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        species.isToxic
                                            ? 'Beracun (Hewan)'
                                            : 'Pet Friendly',
                                        style: AppTypography.caption1Bold
                                            .copyWith(
                                              color: species.isToxic
                                                  ? AppColors.pastelRedText
                                                  : AppColors.petFriendlyText,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Key Stat Cards
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PlantStatCard(
                            label: 'Siram Setiap',
                            value: '${species.defaultWateringInterval} Hari',
                            icon: Icons.water_drop_outlined,
                            iconColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PlantStatCard(
                            label: 'Kebutuhan Cahaya',
                            value: species.sunlightLevel ?? 'Sedang',
                            icon: Icons.wb_sunny_outlined,
                            iconColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Section 1: "Tentang Tanaman Ini"
                  Text(
                    'Tentang Tanaman Ini',
                    style: AppTypography.title2Bold.copyWith(
                      fontSize: 18,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    species.overviewDisplay,
                    style: AppTypography.bodyRegular.copyWith(
                      color: AppColors.inkSoft,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Section 2: "Detail Pertumbuhan" (Directly reading from model)
                  Text(
                    'Detail Pertumbuhan',
                    style: AppTypography.title2Bold.copyWith(
                      fontSize: 18,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildGrowthRow(
                    label: 'Dimensi Maksimum',
                    value: species.dimensionDisplay,
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 24),
                  _buildGrowthRow(
                    label: 'Laju Pertumbuhan',
                    value: species.growthRateDisplay,
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 24),
                  _buildGrowthRow(label: 'Siklus', value: species.cycleDisplay),
                  const Divider(color: AppColors.borderSubtle, height: 24),
                  _buildGrowthRow(
                    label: 'Musim Pemangkasan',
                    value: species.pruningDisplay,
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 24),
                  _buildGrowthRow(
                    label: 'Berbunga',
                    value: species.floweringDisplay,
                  ),
                  const SizedBox(height: 24),

                  // 5. Toxicity & Pet Safety Banner
                  PlantToxicityBanner(
                    toxicityInfo: species.toxicityDescription,
                  ),
                  const SizedBox(height: 24),

                  // 6. Care Guide Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.pastelGreenBg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.forest.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          color: AppColors.forest,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tips Perawatan Plenty',
                                style: AppTypography.calloutBold.copyWith(
                                  color: AppColors.forest,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pastikan media tanam memiliki drainase yang baik dan biarkan permukaan tanah sedikit mengering sebelum jadwal siram berikutnya.',
                                style: AppTypography.footnoteRegular.copyWith(
                                  color: AppColors.inkSoft,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // Space for sticky bottom CTA
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.canvasDefault,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Tambahkan ke Koleksi',
            icon: Icons.add_circle_rounded,
            height: 52,
            borderRadius: BorderRadius.circular(30),
            onPressed: onAddToCollection,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.forest,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.ink,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: Container(
          width: double.infinity,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.canvasDefault,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.forest.withValues(alpha: 0.15),
                AppColors.emerald.withValues(alpha: 0.25),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: (species.imageUrl != null && species.imageUrl!.isNotEmpty)
              ? Image.network(
                  species.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.local_florist,
                    color: AppColors.forest,
                    size: 80,
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.local_florist,
                    color: AppColors.forest,
                    size: 80,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGrowthRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.footnoteRegular.copyWith(
            color: AppColors.muted,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: AppTypography.calloutBold.copyWith(
            color: AppColors.inkSoft,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
