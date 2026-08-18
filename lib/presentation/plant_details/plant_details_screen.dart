import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';
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
    final capsule = await _growthRepo.getTimeCapsule(widget.plant.id);
    if (!mounted) return;
    setState(() {
      _growthLogs = logs;
      _timeCapsule = capsule;
      _isLoading = false;
    });
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
                SliverAppBar(
                  expandedHeight: 280,
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
                              size: 100,
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
                ),
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
                        _buildXpBar(plant),
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
                        _buildGrowthChart(),
                        const SizedBox(height: 28),
                        Text(
                          'Kapsul Waktu (Time Capsule)',
                          style: AppTypography.title2Bold.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTimeCapsuleSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildXpBar(PlantModel plant) {
    final progress = (plant.xp % 100) / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level ${plant.level}',
              style: AppTypography.footnoteBold.copyWith(color: AppColors.ink),
            ),
            Text(
              '${plant.xp % 100} / 100 XP',
              style: AppTypography.caption1Regular.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: AppColors.forest,
          backgroundColor: AppColors.borderSubtle,
        ),
      ],
    );
  }

  Widget _buildGrowthChart() {
    if (_growthLogs.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Belum ada riwayat pengukuran tinggi',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < _growthLogs.length; i++) {
      spots.add(FlSpot(i.toDouble(), _growthLogs[i].heightCm ?? 0.0));
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.forest,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.pastelGreenBg.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCapsuleSection() {
    final capsule = _timeCapsule;

    if (capsule == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_clock, size: 36, color: AppColors.muted),
            const SizedBox(height: 8),
            Text(
              'Belum ada Kapsul Waktu untuk tanaman ini.',
              style: AppTypography.footnoteRegular.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Buat',
              height: 42,
              borderRadius: BorderRadius.circular(20),
              onPressed: () async {
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
              },
            ),
          ],
        ),
      );
    }

    final isUnlocked =
        capsule.isUnlocked || DateTime.now().isAfter(capsule.unlockAt);

    if (!isUnlocked) {
      final daysRemaining = capsule.unlockAt.difference(DateTime.now()).inDays;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pastelYellowBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.pastelYellowText.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock, color: AppColors.pastelYellowText, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Capsule Terkunci ⏳',
                    style: AppTypography.calloutBold.copyWith(
                      color: AppColors.pastelYellowText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dapat dibuka dalam $daysRemaining hari lagi.',
                    style: AppTypography.footnoteRegular.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pastelGreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_open, color: AppColors.forest, size: 24),
              const SizedBox(width: 8),
              Text(
                'Kapsul Waktu Terbuka! 🎉',
                style: AppTypography.calloutBold.copyWith(
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${capsule.message}"',
            style: AppTypography.bodyRegular.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
