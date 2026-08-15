import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/plant/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/plant/domain/entities/plant_entity.dart';
import 'package:plenty/features/plant/domain/repositories/plant_repository.dart';
import 'package:plenty/features/plant/presentation/detail/widgets/plant_growth_specs.dart';
import 'package:plenty/features/plant/presentation/detail/widgets/plant_stat_card.dart';
import 'package:plenty/features/plant/presentation/detail/widgets/plant_toxicity_banner.dart';

/// Full screen detail view of a plant with care requirements and collection trigger.
class PlantDetailScreen extends StatefulWidget {
  final PlantEntity plant;
  final PlantRepository? plantRepository;

  const PlantDetailScreen({
    super.key,
    required this.plant,
    this.plantRepository,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late final PlantRepository _plantRepository;
  bool _isAlreadyAdded = false;

  @override
  void initState() {
    super.initState();
    _plantRepository = widget.plantRepository ?? PlantRepositoryImpl();
    _checkCollection();
  }

  Future<void> _checkCollection() async {
    final result = await _plantRepository.getUserPlants();
    if (!mounted) return;
    final userPlants = result.dataOrNull ?? [];
    final exists = userPlants.any(
      (p) => p.name == widget.plant.name && p.scientificName == widget.plant.scientificName,
    );
    setState(() {
      _isAlreadyAdded = exists;
    });
  }

  Future<void> _addToCollection() async {
    final userPlant = widget.plant.copyWith(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      isCustom: false,
      nextWaterDate: 'Siram sekarang',
      lastCleanedDate: 'Bersihkan sekarang',
    );

    final addResult = await _plantRepository.addUserPlant(userPlant);
    await _plantRepository.incrementStreak();

    if (!mounted) return;

    addResult.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.plant.name} berhasil ditambahkan ke Koleksi!'),
            backgroundColor: AppColors.emerald,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      error: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.pastelRedText,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      body: Stack(
        children: [
          // Scrollable details content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Image Header
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.forest,
                          AppColors.emerald.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_florist,
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
                    ),
                  ),
                  // Content details block
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.name,
                          style: AppTypography.largeTitleBold.copyWith(
                            color: AppColors.ink,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plant.scientificName,
                          style: AppTypography.bodyRegular.copyWith(
                            color: AppColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Badge Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBadge(
                              plant.careLevel,
                              AppColors.pastelGreenBg,
                              AppColors.pastelGreenText,
                            ),
                            _buildBadge(
                              'Famili Araceae',
                              AppColors.pastelBlueBg,
                              AppColors.pastelBlueText,
                            ),
                            _buildBadge(
                              plant.location.toUpperCase(),
                              AppColors.pastelGrayBg,
                              AppColors.pastelGrayText,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Quick Stats Grid
                        Row(
                          children: [
                            Expanded(
                              child: PlantStatCard(
                                icon: Icons.water_drop,
                                color: Colors.blue,
                                title: 'PENYIRAMAN',
                                value: plant.waterSchedule,
                                subtitle: 'Standar Rata-rata',
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: PlantStatCard(
                                icon: Icons.wb_sunny_outlined,
                                color: Colors.orange,
                                title: 'PENCAHAYAAN',
                                value: 'Sinar Tidak Langsung',
                                subtitle: 'Teduh Sebagian',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Conditional Toxicity Warning
                        PlantToxicityBanner(toxicity: plant.toxicity),
                        if (plant.toxicity.isNotEmpty) const SizedBox(height: 24),
                        // About Section
                        Text(
                          'Tentang Tanaman',
                          style: AppTypography.title2Bold.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plant.description,
                          style: AppTypography.bodyRegular.copyWith(
                            color: AppColors.inkSoft,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Growth Specs
                        Text(
                          'Detail Pertumbuhan',
                          style: AppTypography.title2Bold.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        PlantGrowthSpecs(plant: plant),
                        const SizedBox(height: 24),
                        // Pest Warning
                        _buildPestCard(plant.pests),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Floating back navigation button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          // Floating Bottom fixed action button container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: ElevatedButton(
                onPressed: _isAlreadyAdded ? null : _addToCollection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAlreadyAdded ? AppColors.border : AppColors.forest,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isAlreadyAdded ? 'Sudah ada di Koleksi' : 'Tambahkan ke Koleksi',
                  style: AppTypography.calloutBold.copyWith(
                    color: _isAlreadyAdded ? AppColors.muted : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.caption1Bold.copyWith(color: text, fontSize: 10),
      ),
    );
  }

  Widget _buildPestCard(String pests) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pastelYellowBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.pastelYellowText.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.bug_report_outlined,
            color: AppColors.pastelYellowText,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HAMA',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.pastelYellowText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pests,
                  style: AppTypography.footnoteRegular.copyWith(
                    color: AppColors.pastelYellowText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
