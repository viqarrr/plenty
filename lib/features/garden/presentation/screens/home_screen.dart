import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/auth/domain/repositories/auth_repository.dart';
import 'package:plenty/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:plenty/features/auth/presentation/screens/auth_selection_screen.dart';
import 'package:plenty/features/daily_care/presentation/daily_care_controller.dart';
import 'package:plenty/features/daily_care/presentation/screens/daily_care_screen.dart';
import 'package:plenty/features/garden/presentation/controllers/home_controller.dart';
import 'package:plenty/features/garden/presentation/screens/home_empty_state_screen.dart';
import 'package:plenty/features/garden/presentation/screens/home_populated_screen.dart';
import 'package:plenty/features/garden/presentation/widgets/home_bottom_nav.dart';
import 'package:plenty/features/profile/presentation/widgets/profile_tab.dart';
import 'package:sqlite_viewer2/sqlite_viewer.dart';

class HomeScreen extends StatefulWidget {
  final AuthRepository? authRepository;
  final HomeController? homeController;
  final DailyCareController? dailyCareController;

  const HomeScreen({
    super.key,
    this.authRepository,
    this.homeController,
    this.dailyCareController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthRepository _authRepository;
  late final HomeController _homeController;
  late final DailyCareController _dailyCareController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
    _homeController = widget.homeController ?? HomeController();
    _dailyCareController =
        widget.dailyCareController ?? DailyCareController();
    _dailyCareController.addListener(_onDailyCareChanged);
  }

  void _onDailyCareChanged() {
    _homeController.loadDashboard();
  }

  @override
  void dispose() {
    _dailyCareController.removeListener(_onDailyCareChanged);
    if (widget.homeController == null) {
      _homeController.dispose();
    }
    if (widget.dailyCareController == null) {
      _dailyCareController.dispose();
    }
    super.dispose();
  }

  Future<void> _handleRefreshAll() async {
    await Future.wait([
      _homeController.loadDashboard(),
      _dailyCareController.loadTodayCare(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _homeController,
      builder: (context, _) {
        final homeState = _homeController.state;

        return Scaffold(
          backgroundColor: AppColors.canvasDefault,
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _selectedTab,
              children: [
                ExcludeSemantics(
                  excluding: _selectedTab != 0,
                  child: homeState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.forest,
                          ),
                        )
                      : homeState.status == HomeStatus.empty
                          ? HomeEmptyStateScreen(
                              onRefresh: _handleRefreshAll,
                            )
                          : HomePopulatedScreen(
                              state: homeState,
                              controller: _homeController,
                              onRefresh: _handleRefreshAll,
                              onNavigateToDailyCare: () {
                                _dailyCareController.loadTodayCare();
                                setState(() => _selectedTab = 1);
                              },
                            ),
                ),
                ExcludeSemantics(
                  excluding: _selectedTab != 1,
                  child: DailyCareScreen(controller: _dailyCareController),
                ),
                ExcludeSemantics(
                  excluding: _selectedTab != 2,
                  child: const DatabaseList(),
                ),
                ExcludeSemantics(
                  excluding: _selectedTab != 3,
                  child: ProfileTab(
                    profileName: homeState.profileName,
                    username: homeState.username,
                    avatarPath: homeState.avatarUrl,
                    bio: homeState.bio,
                    streakCount: homeState.streakCount,
                    totalPlants: homeState.userPlants.length,
                    totalXp: homeState.totalXp,
                    userLevel: homeState.userLevel,
                    badgeCount: homeState.badgeCount,
                    onProfileUpdated: () => _handleRefreshAll(),
                    onLogout: () async {
                      await _authRepository.logout();
                      if (context.mounted) {
                        context.pushAndRemoveAll(const AuthSelectionScreen());
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: HomeBottomNav(
            selectedIndex: _selectedTab,
            onTabSelected: (index) {
              if (index == 1) {
                _dailyCareController.loadTodayCare();
              } else if (index == 0 || index == 3) {
                _homeController.loadDashboard();
              }
              setState(() => _selectedTab = index);
            },
          ),
        );
      },
    );
  }
}
