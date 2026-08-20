import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/core/constants/xp_config.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/models/care_task_model.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/data/repositories/badge_repository.dart';
import 'package:plenty/data/repositories/care_repository.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/data/repositories/streak_repository.dart';
import 'package:plenty/data/repositories/user_repository.dart';

enum HomeStatus { empty, populated }

class HomeState {
  final HomeStatus status;
  final List<PlantModel> userPlants;
  final List<CareTaskModel> dailyTasks;
  final String selectedRoomFilter;
  final int streakCount;
  final int streakTier;
  final int totalXp;
  final int userLevel;
  final int badgeCount;
  final String profileName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final bool isLoading;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.empty,
    this.userPlants = const [],
    this.dailyTasks = const [],
    this.selectedRoomFilter = 'Semua',
    this.streakCount = 0,
    this.streakTier = 1,
    this.totalXp = 0,
    this.userLevel = 1,
    this.badgeCount = 0,
    this.profileName = 'User',
    this.username = 'alex_plants',
    this.avatarUrl,
    this.bio,
    this.isLoading = false,
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<PlantModel>? userPlants,
    List<CareTaskModel>? dailyTasks,
    String? selectedRoomFilter,
    int? streakCount,
    int? streakTier,
    int? totalXp,
    int? userLevel,
    int? badgeCount,
    String? profileName,
    String? username,
    String? avatarUrl,
    String? bio,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      userPlants: userPlants ?? this.userPlants,
      dailyTasks: dailyTasks ?? this.dailyTasks,
      selectedRoomFilter: selectedRoomFilter ?? this.selectedRoomFilter,
      streakCount: streakCount ?? this.streakCount,
      streakTier: streakTier ?? this.streakTier,
      totalXp: totalXp ?? this.totalXp,
      userLevel: userLevel ?? this.userLevel,
      badgeCount: badgeCount ?? this.badgeCount,
      profileName: profileName ?? this.profileName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  List<PlantModel> get filteredPlants {
    if (selectedRoomFilter == 'Semua') return userPlants;
    return userPlants.where((p) {
      if (selectedRoomFilter == 'Ruang Tamu') return p.isIndoor;
      if (selectedRoomFilter == 'Balkon') return !p.isIndoor;
      return true;
    }).toList();
  }
}

class HomeController extends StateNotifier<HomeState> {
  final PlantRepository _plantRepo;
  final CareRepository _careRepo;
  final StreakRepository _streakRepo;
  final BadgeRepository _badgeRepo;
  final UserRepository _userRepo;
  final String userId;

  HomeController({
    PlantRepository? plantRepo,
    CareRepository? careRepo,
    StreakRepository? streakRepo,
    BadgeRepository? badgeRepo,
    UserRepository? userRepo,
    this.userId = 'usr_default',
  }) : _plantRepo = plantRepo ?? PlantRepository(),
       _careRepo =
           careRepo ??
           CareRepository(dbHelper: (plantRepo ?? PlantRepository()).dbHelper),
       _streakRepo =
           streakRepo ??
           StreakRepository(dbHelper: (plantRepo ?? PlantRepository()).dbHelper),
       _badgeRepo =
           badgeRepo ??
           BadgeRepository(dbHelper: (plantRepo ?? PlantRepository()).dbHelper),
       _userRepo =
           userRepo ??
           UserRepository(dbHelper: (plantRepo ?? PlantRepository()).dbHelper),
       super(const HomeState(isLoading: true)) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _userRepo.getUserProfile() ?? await PreferenceHandler.getUser();
      final userIdVal = user?.id;
      final effectiveUserId = (userIdVal != null && userIdVal > 0)
          ? userIdVal.toString()
          : (userId.isNotEmpty ? userId : 'usr_default');
      final plants = await _plantRepo.getUserPlants(effectiveUserId);
      final streakModel = await _streakRepo.getStreak(effectiveUserId);
      final totalXp = await _careRepo.getTotalUserXp(effectiveUserId);
      final badgeCount = await _badgeRepo.getUserBadgeCount(effectiveUserId);
      final userLevel = XpConfig.levelForXp(totalXp);
      final name = (user?.displayName.trim().isNotEmpty ?? false)
          ? user!.displayName
          : (state.profileName.isNotEmpty && state.profileName != 'Teman Plenty'
              ? state.profileName
              : 'Alice');
      final usernameVal = (user?.username.trim().isNotEmpty ?? false)
          ? user!.username
          : (user?.email.contains('@') ?? false
              ? user!.email.split('@').first
              : 'alex_plants');
      final avatarUrlVal = user?.avatarUrl;
      final bioVal = user?.bio;

      if (plants.isEmpty) {
        state = state.copyWith(
          status: HomeStatus.empty,
          userPlants: [],
          dailyTasks: [],
          streakCount: streakModel.currentStreak,
          streakTier: streakModel.currentTier,
          totalXp: totalXp,
          userLevel: userLevel,
          badgeCount: badgeCount,
          profileName: name,
          username: usernameVal,
          avatarUrl: avatarUrlVal,
          bio: bioVal,
          isLoading: false,
        );
        return;
      }

      final tasks = <CareTaskModel>[];
      for (final plant in plants) {
        final taskTypes = await _careRepo.getTodaysTaskTypes(plant.id);
        for (final typeStr in taskTypes) {
          final type = TaskType.fromDbString(typeStr);
          tasks.add(
            CareTaskModel(
              plant: plant,
              type: type,
              description: switch (type) {
                TaskType.siram => 'Siram tanah sampai lembap merata',
                TaskType.bersihBersih => 'Bersihkan debu dari permukaan daun',
                TaskType.monitorTinggi => 'Catat perkembangan tinggi tanaman',
              },
            ),
          );
        }
      }

      state = state.copyWith(
        status: HomeStatus.populated,
        userPlants: plants,
        dailyTasks: tasks,
        streakCount: streakModel.currentStreak,
        streakTier: streakModel.currentTier,
        totalXp: totalXp,
        userLevel: userLevel,
        badgeCount: badgeCount,
        profileName: name,
        username: usernameVal,
        avatarUrl: avatarUrlVal,
        bio: bioVal,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setRoomFilter(String filter) {
    state = state.copyWith(selectedRoomFilter: filter);
  }

  Future<void> completeTask({
    required CareTaskModel task,
    double? heightCm,
    String? note,
    String? photoPath,
  }) async {
    try {
      if (task.type == TaskType.monitorTinggi && heightCm != null) {
        await _careRepo.completeHeightTask(
          userPlantId: task.userPlantId,
          heightCm: heightCm,
          note: note,
          photoPath: photoPath,
        );
      } else {
        await _careRepo.completeRoutineTask(
          userPlantId: task.userPlantId,
          taskType: task.type.dbString,
        );
      }

      final updatedTasks = state.dailyTasks
          .where((t) => t.id != task.id)
          .toList();
      state = state.copyWith(dailyTasks: updatedTasks);

      final user = await _userRepo.getUserProfile() ?? await PreferenceHandler.getUser();
      final effectiveUserId =
          user?.id != null ? user!.id.toString() : userId;

      final plants = await _plantRepo.getUserPlants(effectiveUserId);
      final totalXp = await _careRepo.getTotalUserXp(effectiveUserId);
      final badgeCount = await _badgeRepo.getUserBadgeCount(effectiveUserId);
      final userLevel = XpConfig.levelForXp(totalXp);
      
      // Re-evaluate streak upon completing tasks
      final updatedStreak =
          await _streakRepo.evaluateDailyStreak(effectiveUserId);

      state = state.copyWith(
        userPlants: plants,
        streakCount: updatedStreak.currentStreak,
        streakTier: updatedStreak.currentTier,
        totalXp: totalXp,
        userLevel: userLevel,
        badgeCount: badgeCount,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    return HomeController();
  },
);
