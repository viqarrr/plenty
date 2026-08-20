import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/growth_log_model.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/data/repositories/growth_repository.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/daily_routine/monitor_tinggi_input_sheet.dart';
import 'package:plenty/presentation/add_plant/time_capsule_modal.dart';
import 'package:plenty/presentation/home/home_controller.dart';
import 'package:plenty/presentation/plant_details/plant_growth_specs.dart';
import 'package:plenty/presentation/plant_details/plant_stat_card.dart';
import 'package:plenty/presentation/plant_details/plant_toxicity_banner.dart';
import 'package:plenty/presentation/plant_details/widgets/delete_plant_sheet.dart';
import 'package:plenty/presentation/plant_details/widgets/edit_plant_sheet.dart';
import 'package:plenty/presentation/plant_details/widgets/growth_height_chart.dart';
import 'package:plenty/presentation/plant_details/widgets/level_xp_bar.dart';
import 'package:plenty/presentation/plant_details/widgets/photo_timeline_stepper.dart';
import 'package:plenty/presentation/plant_details/widgets/time_capsule_status_widget.dart';

/// Screen displaying in-depth botanical specifications, growth tracking,
/// height chart, vertical photo timeline, and time capsule status.
class PlantDetailsScreen extends ConsumerStatefulWidget {
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
  ConsumerState<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends ConsumerState<PlantDetailsScreen> {
  late final GrowthRepository _growthRepo;
  late final PlantRepository _plantRepo;
  late PlantModel _plant;

  List<GrowthLogModel> _growthLogs = [];
  List<GrowthLogModel> _photoLogs = [];
  TimeCapsuleModel? _timeCapsule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _growthRepo =
        widget.growthRepository ?? GrowthRepository(dbHelper: widget.dbHelper);
    _plantRepo =
        widget.plantRepository ?? PlantRepository(dbHelper: widget.dbHelper);
    _loadData();
  }

  Future<void> _loadData() async {
    final logs = await _growthRepo.getGrowthHistory(_plant.id);
    final photos = await _growthRepo.getPhotoGallery(_plant.id);
    final capsule = await _growthRepo.getTimeCapsule(_plant.id);
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
        userPlantId: _plant.id,
        message: draft.message,
        durationMonths: draft.durationMonths,
      );
      _loadData();
    }
  }

  void _showGrowthTimelineModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.canvasDefault,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linimasa Pertumbuhan',
                        style: AppTypography.title2Bold.copyWith(
                          fontSize: 18,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_photoLogs.length} Catatan Jurnal & Foto',
                        style: AppTypography.caption1Regular.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: PhotoTimelineStepper(
                  logs: _photoLogs,
                  onEditLog: _showEditGrowthLogSheet,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGrowthLogSheet(GrowthLogModel log) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MonitorTinggiInputSheet(
        plant: _plant,
        lastRecordedHeight: log.heightCm ?? _plant.currentHeightCm,
        isEditMode: true,
        initialNote: log.note,
        initialPhotoPath: log.photoPath,
        onSubmit: (heightCm, note, photoPath) async {
          await _growthRepo.updateGrowthLog(
            logId: log.id,
            userPlantId: _plant.id,
            heightCm: heightCm,
            note: note,
            photoPath: photoPath,
          );
          if (mounted) {
            await _loadData();
            ref.read(homeControllerProvider.notifier).loadDashboard();
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Log pertumbuhan berhasil diperbarui!'),
                backgroundColor: AppColors.forest,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditPlantBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPlantSheet(
        plant: _plant,
        onSave: (newNickname, newPhotoPath, photoChanged) async {
          await _handleUpdatePlantInfo(
            newNickname: newNickname,
            newPhotoPath: newPhotoPath,
            photoChanged: photoChanged,
          );
        },
      ),
    );
  }

  Future<void> _handleUpdatePlantInfo({
    required String newNickname,
    required String? newPhotoPath,
    required bool photoChanged,
  }) async {
    try {
      await _plantRepo.updatePlantInfo(
        plantId: _plant.id,
        nickname: newNickname,
        coverPhotoPath: newPhotoPath,
        updatePhoto: photoChanged,
      );
      if (!mounted) return;

      setState(() {
        _plant = _plant.copyWith(
          nickname: newNickname,
          coverPhotoPath: photoChanged ? newPhotoPath : _plant.coverPhotoPath,
        );
      });

      // Refresh Home Dashboard grid
      ref.read(homeControllerProvider.notifier).loadDashboard();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_plant.nickname} berhasil diperbarui!'),
          backgroundColor: AppColors.forest,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui tanaman: $e'),
          backgroundColor: AppColors.pastelRedText,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteConfirmationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeletePlantSheet(
        plant: _plant,
        onConfirmDelete: _handleDeletePlant,
      ),
    );
  }

  Future<void> _handleDeletePlant() async {
    try {
      await _plantRepo.deletePlant(_plant.id);
      if (!mounted) return;

      // Refresh Home Dashboard
      ref.read(homeControllerProvider.notifier).loadDashboard();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_plant.nickname} berhasil dihapus dari koleksi.'),
          backgroundColor: AppColors.forest,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop(); // Back to Home
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus tanaman: $e'),
          backgroundColor: AppColors.pastelRedText,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.forest),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverHeader(_plant),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _plant.nickname,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 26,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _plant.scientificName,
                          style: AppTypography.footnoteRegular.copyWith(
                            color: AppColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LevelXpBar(plant: _plant),
                        const SizedBox(height: 24),
                        PlantToxicityBanner(toxicityInfo: _plant.toxicity),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: PlantStatCard(
                                label: 'Tinggi Saat Ini',
                                value: '${_plant.currentHeightCm} cm',
                                icon: Icons.straighten,
                                iconColor: AppColors.forest,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PlantStatCard(
                                label: 'Kesehatan',
                                value: _plant.healthStatus.toUpperCase(),
                                icon: Icons.favorite_border,
                                iconColor: AppColors.pastelGreenText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        PlantGrowthSpecs(plant: _plant),
                        const SizedBox(height: 28),
                        Text(
                          'Grafik Pertumbuhan Tinggi',
                          style: AppTypography.title2Bold.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GrowthHeightChart(growthLogs: _growthLogs),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _showGrowthTimelineModal,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pastelGreenBg
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppColors.forest.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.history_toggle_off,
                                      color: AppColors.forest,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Linimasa & Foto Pertumbuhan',
                                      style:
                                          AppTypography.footnoteBold.copyWith(
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${_photoLogs.length} Catatan',
                                      style: AppTypography.caption1Regular
                                          .copyWith(
                                        color: AppColors.forest,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: AppColors.forest,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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
                          plantNickname: _plant.nickname,
                          onCreatePressed: _handleCreateTimeCapsule,
                        ),
                        const SizedBox(height: 36),

                        // Delete Plant Action Card
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showDeleteConfirmationBottomSheet,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.pastelRedText,
                              size: 20,
                            ),
                            label: Text(
                              'Hapus Tanaman dari Koleksi',
                              style: AppTypography.calloutBold.copyWith(
                                color: AppColors.pastelRedText,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.pastelRedText
                                    .withValues(alpha: 0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
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

  Widget _buildPlantCover(PlantModel plant) {
    final photo = plant.coverPhotoPath;
    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return Image.network(
          photo,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackCover(),
        );
      } else if (photo.startsWith('assets/')) {
        return Image.asset(
          photo,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackCover(),
        );
      } else {
        final file = File(photo);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallbackCover(),
          );
        }
      }
    }
    return _buildFallbackCover();
  }

  Widget _buildFallbackCover() {
    return Container(
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
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.forest,
            ),
            tooltip: 'Edit Tanaman',
            onPressed: _showEditPlantBottomSheet,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.pastelRedText,
            ),
            tooltip: 'Hapus Tanaman',
            onPressed: _showDeleteConfirmationBottomSheet,
          ),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildPlantCover(plant),
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
