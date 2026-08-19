import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/growth_log_model.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/data/repositories/growth_repository.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/presentation/add_plant/time_capsule_modal.dart';
import 'package:plenty/presentation/plant_details/plant_growth_specs.dart';
import 'package:plenty/presentation/plant_details/plant_stat_card.dart';
import 'package:plenty/presentation/plant_details/plant_toxicity_banner.dart';
import 'package:plenty/presentation/plant_details/widgets/growth_height_chart.dart';
import 'package:plenty/presentation/plant_details/widgets/level_xp_bar.dart';
import 'package:plenty/presentation/plant_details/widgets/photo_timeline_stepper.dart';
import 'package:plenty/presentation/plant_details/widgets/time_capsule_status_widget.dart';

/// Screen displaying in-depth botanical specifications, growth tracking,
/// height chart, vertical photo timeline, and time capsule status.
class PlantDetailsScreen extends StatefulWidget {
  final PlantModel plant;
  final DatabaseHelper? dbHelper;
  final GrowthRepository? growthRepository;
  final PlantRepository? plantRepository;

  const PlantDetailsScreen({
    super.key,
    required this.plant,
    this.dbHelper,
    this.growthRepository,
    this.plantRepository,
  });

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  late final GrowthRepository _growthRepo;
  List<GrowthLogModel> _growthLogs = [];
  List<GrowthLogModel> _photoLogs = [];
  TimeCapsuleModel? _timeCapsule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _growthRepo =
        widget.growthRepository ?? GrowthRepository(dbHelper: widget.dbHelper);
    _loadData();
  }

  Future<void> _loadData() async {
    final logs = await _growthRepo.getGrowthHistory(widget.plant.id);
    final photos = await _growthRepo.getPhotoGallery(widget.plant.id);
    final capsule = await _growthRepo.getTimeCapsule(widget.plant.id);
    if (!mounted) return;
    setState(() {
      _growthLogs = logs;
      _photoLogs = photos;
      _timeCapsule = capsule;
      _isLoading = false;
    });
  }

  Future<void> _handleCreateTimeCapsule() async {
    final draft = await showModalBottomSheet<TimeCapsuleDraft?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TimeCapsuleModal(),
    );
    if (draft != null && draft.message.isNotEmpty) {
      await _growthRepo.createTimeCapsule(
        userPlantId: widget.plant.id,
        message: draft.message,
        durationMonths: draft.durationMonths,
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.forest),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverHeader(plant),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.nickname,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 26,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plant.scientificName,
                          style: AppTypography.footnoteRegular.copyWith(
                            color: AppColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LevelXpBar(plant: plant),
                        const SizedBox(height: 24),
                        PlantToxicityBanner(toxicityInfo: plant.toxicity),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: PlantStatCard(
                                label: 'Tinggi Saat Ini',
                                value: '${plant.currentHeightCm} cm',
                                icon: Icons.straighten,
                                iconColor: AppColors.forest,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PlantStatCard(
                                label: 'Kesehatan',
                                value: plant.healthStatus.toUpperCase(),
                                icon: Icons.favorite_border,
                                iconColor: AppColors.pastelGreenText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        PlantGrowthSpecs(plant: plant),
                        const SizedBox(height: 28),
                        Text(
                          'Grafik Pertumbuhan Tinggi',
                          style: AppTypography.title2Bold.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GrowthHeightChart(growthLogs: _growthLogs),
                        const SizedBox(height: 28),
                        Text(
                          'Linimasa Pertumbuhan (Photo Stepper)',
                          style: AppTypography.title2Bold.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PhotoTimelineStepper(logs: _photoLogs),
                        const SizedBox(height: 28),
                        Text(
                          'Kapsul Waktu (Time Capsule)',
                          style: AppTypography.title2Bold.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TimeCapsuleStatusWidget(
                          capsule: _timeCapsule,
                          plantNickname: plant.nickname,
                          onCreatePressed: _handleCreateTimeCapsule,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverHeader(PlantModel plant) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.surface,
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
          onPressed: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
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
              child: const Center(
                child: Icon(
                  Icons.local_florist,
                  color: AppColors.forest,
                  size: 90,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level ${plant.level}',
                  style: AppTypography.footnoteBold.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
