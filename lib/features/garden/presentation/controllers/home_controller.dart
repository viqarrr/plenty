import 'package:flutter/foundation.dart';
import 'package:plenty/core/constants/xp_config.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/daily_care/domain/models/care_task_model.dart';
import 'package:plenty/features/daily_care/domain/repositories/daily_care_repository.dart';
import 'package:plenty/features/garden/domain/models/custom_site_model.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/features/garden/domain/repositories/site_repository.dart';
import 'package:plenty/features/garden/domain/repositories/streak_repository.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:plenty/features/profile/domain/repositories/user_repository.dart';

enum HomeStatus { empty, populated }

class HomeState {
  final HomeStatus status;
  final List<PlantModel> userPlants;
  final List<CareTaskModel> dailyTasks;
  final List<CustomSiteModel> customSites;
  final String selectedRoomFilter;
  final int streakCount;
  final int streakTier;
  final int totalXp;
  final int userLevel;
  final int badgeCount;
  final String profileName;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final bool isLoading;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.empty,
    this.userPlants = const [],
    this.dailyTasks = const [],
    this.customSites = const [],
    this.selectedRoomFilter = 'Semua',
    this.streakCount = 0,
    this.streakTier = 1,
    this.totalXp = 0,
    this.userLevel = 1,
    this.badgeCount = 0,
    this.profileName = 'User',
    this.username = 'alex_plants',
    this.email = '',
    this.avatarUrl,
    this.bio,
    this.isLoading = false,
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<PlantModel>? userPlants,
    List<CareTaskModel>? dailyTasks,
    List<CustomSiteModel>? customSites,
    String? selectedRoomFilter,
    int? streakCount,
    int? streakTier,
    int? totalXp,
    int? userLevel,
    int? badgeCount,
    String? profileName,
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      userPlants: userPlants ?? this.userPlants,
      dailyTasks: dailyTasks ?? this.dailyTasks,
      customSites: customSites ?? this.customSites,
      selectedRoomFilter: selectedRoomFilter ?? this.selectedRoomFilter,
      streakCount: streakCount ?? this.streakCount,
      streakTier: streakTier ?? this.streakTier,
      totalXp: totalXp ?? this.totalXp,
      userLevel: userLevel ?? this.userLevel,
      badgeCount: badgeCount ?? this.badgeCount,
      profileName: profileName ?? this.profileName,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  List<String> get availableRoomFilters {
    const defaultFilters = [
      'Semua',
      'Ruang Tamu',
      'Kamar Tidur',
      'Dapur',
      'Ruang Kerja',
      'Balkon',
      'Taman',
    ];
    final filters = <String>[...defaultFilters];

    for (final s in customSites) {
      final siteName = s.name.trim();
      if (siteName.isNotEmpty &&
          !filters.any((f) => f.toLowerCase() == siteName.toLowerCase())) {
        filters.add(siteName);
      }
    }

    for (final plant in userPlants) {
      final site = plant.siteName.trim();
      if (site.isNotEmpty &&
          !filters.any(
            (f) =>
                f.toLowerCase() == site.toLowerCase() ||
                site.toLowerCase().contains(f.toLowerCase()),
          )) {
        filters.add(site);
      }
    }
    return filters;
  }

  List<PlantModel> get filteredPlants {
    if (selectedRoomFilter == 'Semua') return userPlants;
    final filter = selectedRoomFilter.trim().toLowerCase();

    return userPlants.where((p) {
      final plantSite = p.siteName.trim().toLowerCase();

      if (plantSite == filter) return true;
      if (plantSite.isNotEmpty &&
          (plantSite.contains(filter) || filter.contains(plantSite))) {
        return true;
      }

      if ((filter == 'kamar' || filter == 'kamar tidur') &&
          (plantSite.contains('kamar') || plantSite.contains('tidur'))) {
        return true;
      }
      if (filter == 'dapur' &&
          (plantSite.contains('dapur') || plantSite.contains('makan'))) {
        return true;
      }
      if (filter == 'ruang tamu' &&
          (plantSite.contains('tamu') ||
              (p.isIndoor &&
                  (plantSite.isEmpty || plantSite.contains('jendela'))))) {
        return true;
      }
      if (filter == 'ruang kerja' &&
          (plantSite.contains('kerja') || plantSite.contains('kantor'))) {
        return true;
      }
      if (filter == 'balkon' &&
          (plantSite.contains('balkon') ||
              plantSite.contains('teras') ||
              !p.isIndoor)) {
        return true;
      }
      if (filter == 'taman' &&
          (plantSite.contains('taman') ||
              plantSite.contains('halaman') ||
              plantSite.contains('patio'))) {
        return true;
      }

      return false;
    }).toList();
  }
}

/// Dashboard / Home Controller coordinating user garden, daily care tasks, and gamification state.
///
/// NOTE: HomeController serves as the central home dashboard aggregator, coordinating across
/// plant, care, streak, badge, site, and user domains via explicit interface injection.
class HomeController extends ChangeNotifier {
  final IPlantRepository _plantRepo;
  final IDailyCareRepository _careRepo;
  final IStreakRepository _streakRepo;
  final IBadgeRepository _badgeRepo;
  final IUserRepository _userRepo;
  final ISiteRepository _siteRepo;
  final String userId;

  HomeState _state = const HomeState(isLoading: true);
  HomeState get state => _state;

  bool _isDisposed = false;

  HomeController({
    IPlantRepository? plantRepo,
    IDailyCareRepository? careRepo,
    IStreakRepository? streakRepo,
    IBadgeRepository? badgeRepo,
    IUserRepository? userRepo,
    ISiteRepository? siteRepo,
    this.userId = 'usr_default',
  }) : _plantRepo = plantRepo ?? Injector.plantRepository,
       _careRepo = careRepo ?? Injector.dailyCareRepository,
       _streakRepo = streakRepo ?? Injector.streakRepository,
       _badgeRepo = badgeRepo ?? Injector.badgeRepository,
       _userRepo = userRepo ?? Injector.userRepository,
       _siteRepo = siteRepo ?? Injector.siteRepository {
    loadDashboard();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _updateState(HomeState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    _updateState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final userProfileResult = await _userRepo.getUserProfile();
      final user =
          userProfileResult.dataOrNull ?? await PreferenceHandler.getUser();
      final userIdVal = user?.id;
      final effectiveUserId = (userIdVal != null && userIdVal > 0)
          ? userIdVal.toString()
          : (userId.isNotEmpty ? userId : 'usr_default');

      final plantsResult = await _plantRepo.getUserPlants(effectiveUserId);
      final plants = plantsResult.dataOrNull ?? [];

      final streakResult = await _streakRepo.getStreak(effectiveUserId);
      final streakModel = streakResult.dataOrNull;

      final xpResult = await _careRepo.getTotalUserXp(effectiveUserId);
      final totalXp = xpResult.dataOrNull ?? 0;

      final badgeCountResult = await _badgeRepo.getUserBadgeCount(
        effectiveUserId,
      );
      final badgeCount = badgeCountResult.dataOrNull ?? 0;

      final sitesResult = await _siteRepo.getCustomSites(effectiveUserId);
      final customSites = sitesResult.dataOrNull ?? [];

      final userLevel = XpConfig.levelForXp(totalXp);
      final name = (user?.displayName.trim().isNotEmpty ?? false)
          ? user!.displayName
          : (_state.profileName.isNotEmpty &&
                    _state.profileName != 'Teman Plenty'
                ? _state.profileName
                : 'Alice');
      final usernameVal = (user?.username.trim().isNotEmpty ?? false)
          ? user!.username
          : (user?.email.contains('@') ?? false
                ? user!.email.split('@').first
                : 'alex_plants');
      final emailVal = (user?.email.trim().isNotEmpty ?? false)
          ? user!.email
          : (user?.email.contains('@') ?? false
                ? user!.email.split('@').first
                : 'alex_plants');
      final avatarUrlVal = user?.avatarUrl;
      final bioVal = user?.bio;

      if (plants.isEmpty) {
        _updateState(
          _state.copyWith(
            status: HomeStatus.empty,
            userPlants: [],
            dailyTasks: [],
            customSites: customSites,
            streakCount: streakModel?.currentStreak ?? 0,
            streakTier: streakModel?.currentTier ?? 1,
            totalXp: totalXp,
            userLevel: userLevel,
            badgeCount: badgeCount,
            profileName: name,
            username: usernameVal,
            email: emailVal,
            avatarUrl: avatarUrlVal,
            bio: bioVal,
            isLoading: false,
          ),
        );
        return;
      }

      final tasks = <CareTaskModel>[];
      for (final plant in plants) {
        final taskTypesResult = await _careRepo.getTodaysTaskTypes(plant.id);
        final taskTypes = taskTypesResult.dataOrNull ?? [];
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

      _updateState(
        _state.copyWith(
          status: HomeStatus.populated,
          userPlants: plants,
          dailyTasks: tasks,
          customSites: customSites,
          streakCount: streakModel?.currentStreak ?? 0,
          streakTier: streakModel?.currentTier ?? 1,
          totalXp: totalXp,
          userLevel: userLevel,
          badgeCount: badgeCount,
          profileName: name,
          username: usernameVal,
          avatarUrl: avatarUrlVal,
          bio: bioVal,
          isLoading: false,
        ),
      );
    } catch (e) {
      _updateState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat data kebun: $e',
        ),
      );
    }
  }

  void setRoomFilter(String filter) {
    _updateState(_state.copyWith(selectedRoomFilter: filter));
  }

  Future<void> completeTask(CareTaskModel task) async {
    final result = await _careRepo.completeRoutineTask(
      plant: task.plant,
      taskType: task.type.dbString,
    );
    switch (result) {
      case Success():
        await loadDashboard();
      case Error(:final failure):
        _updateState(_state.copyWith(errorMessage: failure.message));
    }
  }

  Future<void> refresh() async {
    await loadDashboard();
  }
}
