import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/daily_care/domain/repositories/daily_care_repository.dart';
import 'package:plenty/features/daily_care/presentation/widgets/monitor_tinggi_input_sheet.dart';
import 'package:plenty/features/garden/domain/models/growth_log_model.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/garden/domain/repositories/growth_repository.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/features/garden/presentation/controllers/home_controller.dart';
import 'package:plenty/features/garden/presentation/widgets/add_plant/time_capsule_modal.dart';
import 'package:plenty/features/garden/presentation/widgets/delete_plant_sheet.dart';
import 'package:plenty/features/garden/presentation/widgets/edit_plant_sheet.dart';
import 'package:plenty/features/garden/presentation/widgets/first_reward_popup.dart';
import 'package:plenty/features/garden/presentation/widgets/growth_height_chart.dart';
import 'package:plenty/features/garden/presentation/widgets/level_xp_bar.dart';
import 'package:plenty/features/garden/presentation/widgets/photo_timeline_stepper.dart';
import 'package:plenty/features/garden/presentation/widgets/plant_growth_specs.dart';
import 'package:plenty/features/garden/presentation/widgets/plant_stat_card.dart';
import 'package:plenty/features/garden/presentation/widgets/plant_toxicity_banner.dart';
import 'package:plenty/features/garden/presentation/widgets/time_capsule_status_widget.dart';

/// Screen displaying in-depth botanical specifications, growth tracking,
/// height chart, vertical photo timeline, and time capsule status.
class PlantDetailsScreen extends StatefulWidget {
  final PlantModel plant;
  final IGrowthRepository? growthRepository;
  final IPlantRepository? plantRepository;
  final IDailyCareRepository? dailyCareRepository;
  final HomeController? homeController;

  const PlantDetailsScreen({
    super.key,
    required this.plant,
    this.growthRepository,
    this.plantRepository,
    this.dailyCareRepository,
    this.homeController,
  });

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  late final IGrowthRepository _growthRepo;
  late final IPlantRepository _plantRepo;
  late final IDailyCareRepository _dailyCareRepo;
  late PlantModel _plant;

  List<GrowthLogModel> _growthLogs = [];
  List<GrowthLogModel> _photoLogs = [];
  TimeCapsuleModel? _timeCapsule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _growthRepo = widget.growthRepository ?? Injector.growthRepository;
    _plantRepo = widget.plantRepository ?? Injector.plantRepository;
    _dailyCareRepo = widget.dailyCareRepository ?? Injector.dailyCareRepository;
    _loadData();
  }

  Future<void> _loadData() async {
    final plantRes = await _plantRepo.getPlantById(_plant.id);
    final logsRes = await _growthRepo.getHeightSeries(_plant.id);
    final photosRes = await _growthRepo.getPhotoGallery(_plant.id);
    final capsuleRes = await _growthRepo.getTimeCapsule(_plant.id);
    if (!mounted) return;
    setState(() {
      if (plantRes.dataOrNull != null) {
        _plant = plantRes.dataOrNull!;
      }
      _growthLogs = logsRes.dataOrNull ?? [];
      _photoLogs = photosRes.dataOrNull ?? [];
      _timeCapsule = capsuleRes.dataOrNull;
      _isLoading = false;
    });
  }

  Future<void> _handleCreateTimeCapsule() async {
    final draft = await context.showAppBottomSheet<TimeCapsuleDraft?>(
      const TimeCapsuleModal(),
    );
    if (draft != null && draft.message.isNotEmpty) {
      final now = DateTime.now();
      final unlockAt = DateTime(
        now.year,
        now.month + draft.durationMonths,
        now.day,
      );
      final capsule = TimeCapsuleModel(
        id: 'tc_${now.millisecondsSinceEpoch}',
        userPlantId: _plant.id,
        unlockAt: unlockAt,
        photoPath: draft.photoPath,
        note: draft.message,
        isUnlocked: false,
        createdAt: now,
      );
      final result = await _growthRepo.saveTimeCapsule(capsule);
      if (mounted) {
        await _loadData();
        if (result.isSuccess && (result.dataOrNull ?? false)) {
          await context.showAppDialog(
            RewardPopup.timeCapsule(
              plantNickname: _plant.nickname,
              onDismiss: () => context.pop(),
            ),
            barrierDismissible: false,
          );
        }
      }
    }
  }

  Future<void> _showGrowthTimelineModal() async {
    final selectedLog = await context.showAppBottomSheet<GrowthLogModel>(
      Container(
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
                    onPressed: () => context.pop(),
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
                  onEditLog: (log) => Navigator.of(context).pop(log),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedLog != null && mounted) {
      _showEditGrowthLogSheet(selectedLog);
    }
  }

  void _showEditGrowthLogSheet(GrowthLogModel log) {
    final messenger = ScaffoldMessenger.of(context);
    context.showAppBottomSheet(
      MonitorTinggiInputSheet(
        plant: _plant,
        lastRecordedHeight: log.heightCm ?? _plant.currentHeightCm,
        isEditMode: true,
        initialNote: log.note,
        initialPhotoPath: log.photoPath,
        onSubmit: (heightCm, note, photoPath) async {
          await _dailyCareRepo.updateGrowthLog(
            logId: log.id,
            userPlantId: _plant.id,
            heightCm: heightCm,
            note: note,
            photoPath: photoPath,
          );
          if (mounted) {
            await _loadData();
            widget.homeController?.loadDashboard();
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
    context.showAppBottomSheet(
      EditPlantSheet(
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
    final result = await _plantRepo.updatePlantInfo(
      plantId: _plant.id,
      nickname: newNickname,
      coverPhotoPath: newPhotoPath,
      updatePhoto: photoChanged,
    );
    if (!mounted) return;

    switch (result) {
      case Success():
        setState(() {
          _plant = _plant.copyWith(
            nickname: newNickname,
            coverPhotoPath: photoChanged ? newPhotoPath : _plant.coverPhotoPath,
          );
        });
        widget.homeController?.loadDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_plant.nickname} berhasil diperbarui!'),
            backgroundColor: AppColors.forest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui tanaman: ${failure.message}'),
            backgroundColor: AppColors.pastelRedText,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _showDeleteConfirmationBottomSheet() {
    context.showAppBottomSheet(
      DeletePlantSheet(plant: _plant, onConfirmDelete: _handleDeletePlant),
    );
  }

  Future<void> _handleDeletePlant() async {
    final result = await _plantRepo.deletePlant(_plant.id);
    if (!mounted) return;

    switch (result) {
      case Success():
        widget.homeController?.loadDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_plant.nickname} berhasil dihapus dari koleksi.'),
            backgroundColor: AppColors.forest,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus tanaman: ${failure.message}'),
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
                                label: 'Usia Tanaman',
                                value: _plant.ageDisplay,
                                icon: Icons.history_rounded,
                                iconColor: AppColors.forest,
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
                              color: AppColors.pastelGreenBg.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.forest.withValues(alpha: 0.2),
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
                                      style: AppTypography.footnoteBold
                                          .copyWith(color: AppColors.forest),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${_photoLogs.length} Catatan',
                                      style: AppTypography.caption1Regular
                                          .copyWith(color: AppColors.forest),
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
                                color: AppColors.pastelRedText.withValues(
                                  alpha: 0.4,
                                ),
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
        child: Icon(Icons.local_florist, color: AppColors.forest, size: 90),
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
