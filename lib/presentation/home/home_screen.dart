import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/data/repositories/auth_repository.dart';
import 'package:plenty/data/repositories/auth_repository_impl.dart';
import 'package:plenty/daily_routine/daily_care_screen.dart';
import 'package:plenty/presentation/auth/auth_selection.dart';
import 'package:plenty/presentation/home/home_bottom_nav.dart';
import 'package:plenty/presentation/home/home_controller.dart';
import 'package:plenty/presentation/home/home_empty_state_screen.dart';
import 'package:plenty/presentation/home/home_populated_screen.dart';
import 'package:plenty/presentation/home/profile_tab.dart';
import 'package:sqlite_viewer2/sqlite_viewer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final AuthRepository? authRepository;

  const HomeScreen({super.key, this.authRepository});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AuthRepository _authRepository;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepositoryImpl();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);
    final homeController = ref.read(homeControllerProvider.notifier);

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
                      onRefresh: homeController.loadDashboard,
                    )
                  : HomePopulatedScreen(
                      onRefresh: homeController.loadDashboard,
                      onNavigateToDailyCare: () =>
                          setState(() => _selectedTab = 1),
                    ),
            ),
            ExcludeSemantics(
              excluding: _selectedTab != 1,
              child: const DailyCareScreen(),
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
                onProfileUpdated: () => homeController.loadDashboard(),
                onLogout: () async {
                  await _authRepository.logout();
                  if (context.mounted) {
                    context.pushAndRemoveAll(const AuthSelection());
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: _selectedTab,
        onTabSelected: (index) => setState(() => _selectedTab = index),
      ),
    );
  }
}
