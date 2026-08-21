import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';

class HomeBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const HomeBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTabSelected,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.pastelGreenBg,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, color: AppColors.muted),
            selectedIcon: const Icon(Icons.home, color: AppColors.forest),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined, color: AppColors.muted),
            selectedIcon: const Icon(Icons.checklist, color: AppColors.forest),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline, color: AppColors.muted),
            selectedIcon: const Icon(Icons.people, color: AppColors.forest),
            label: 'Komunitas',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline, color: AppColors.muted),
            selectedIcon: const Icon(Icons.person, color: AppColors.forest),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
