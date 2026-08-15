import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:plenty/features/authentication/domain/repositories/auth_repository.dart';
import 'package:plenty/features/authentication/presentation/auth_selection_screen.dart';
import 'package:plenty/features/plant/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/plant/domain/entities/care_task_entity.dart';
import 'package:plenty/features/plant/domain/entities/plant_entity.dart';
import 'package:plenty/features/plant/domain/repositories/plant_repository.dart';
import 'package:plenty/features/plant/presentation/catalog/add_plant_screen.dart';
import 'package:plenty/features/plant/presentation/custom_wizard/add_custom_plant_wizard_screen.dart';
import 'package:plenty/features/plant/presentation/detail/plant_detail_screen.dart';
import 'package:plenty/features/plant/presentation/home/widgets/dashboard_tab.dart';
import 'package:plenty/features/plant/presentation/home/widgets/home_bottom_nav.dart';
import 'package:plenty/features/plant/presentation/home/widgets/profile_tab.dart';
import 'package:plenty/features/plant/presentation/home/widgets/social_tab.dart';
import 'package:plenty/features/plant/presentation/home/widgets/tasks_tab.dart';

/// Main container screen with navigation between Dashboard, Tasks, Social, and Profile.
class HomeScreen extends StatefulWidget {
  final PlantRepository? plantRepository;
  final AuthRepository? authRepository;

  const HomeScreen({
    super.key,
    this.plantRepository,
    this.authRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PlantRepository _plantRepository;
  late final AuthRepository _authRepository;

  int _selectedTab = 0;
  String _profileName = 'John';
  int _streakCount = 1;
  List<PlantEntity> _userPlants = [];
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _plantRepository = widget.plantRepository ?? PlantRepositoryImpl();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
    _loadData();
  }

  Future<void> _loadData() async {
    final nameResult = await _plantRepository.getProfileName();
    final streakResult = await _plantRepository.getStreakCount();
    final plantsResult = await _plantRepository.getUserPlants();

    if (!mounted) return;

    setState(() {
      _profileName = nameResult.dataOrNull ?? 'John';
      _streakCount = streakResult.dataOrNull ?? 1;
      _userPlants = plantsResult.dataOrNull ?? [];
    });
  }

  List<CareTaskEntity> get _dynamicTasks {
    final tasks = <CareTaskEntity>[];
    for (final plant in _userPlants) {
      if (plant.nextWaterDate.toLowerCase().contains('sekarang')) {
        tasks.add(
          CareTaskEntity(
            plant: plant,
            type: TaskType.watering,
            description: '${plant.name} butuh disiram hari ini.',
          ),
        );
      }
      if (plant.lastCleanedDate.toLowerCase().contains('sekarang')) {
        tasks.add(
          CareTaskEntity(
            plant: plant,
            type: TaskType.cleaning,
            description: 'Lap debu pada daun ${plant.name}.',
          ),
        );
      }
    }
    return tasks;
  }

  Future<void> _handleCompleteTask(CareTaskEntity task) async {
    final result = await _plantRepository.completeTask(task);
    if (!mounted) return;

    result.when(
      success: (_) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil diselesaikan! Streak bertambah!'),
            backgroundColor: AppColors.emerald,
          ),
        );
      },
      error: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  DashboardTab(
                    profileName: _profileName,
                    streakCount: _streakCount,
                    plants: _userPlants,
                    tasks: _dynamicTasks,
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) =>
                        setState(() => _selectedFilter = filter),
                    onRefresh: _loadData,
                    onCheckTasks: () => setState(() => _selectedTab = 1),
                    onSeeAllCatalog: () async {
                      await context.push(const AddPlantScreen());
                      _loadData();
                    },
                    onSelectPlant: (plant) async {
                      await context.push(PlantDetailScreen(plant: plant));
                      _loadData();
                    },
                    onAddNewPlant: () async {
                      await context
                          .push(const AddCustomPlantWizardScreen());
                      _loadData();
                    },
                  ),
                  TasksTab(
                    tasks: _dynamicTasks,
                    onCompleteTask: _handleCompleteTask,
                  ),
                  const SocialTab(),
                  ProfileTab(
                    profileName: _profileName,
                    streakCount: _streakCount,
                    totalPlants: _userPlants.length,
                    onLogout: () async {
                      await _authRepository.logout();
                      if (context.mounted) {
                        context.pushAndRemoveAll(
                          const AuthSelectionScreen(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            HomeBottomNav(
              selectedIndex: _selectedTab,
              onTabSelected: (index) => setState(() => _selectedTab = index),
            ),
          ],
        ),
      ),
    );
  }
}
