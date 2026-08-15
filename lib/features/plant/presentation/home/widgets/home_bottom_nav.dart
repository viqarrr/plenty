import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';

/// Bottom tab navigation bar styled following native iOS design patterns.
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
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TabItem(
            index: 0,
            isSelected: selectedIndex == 0,
            icon: Icons.home_rounded,
            label: 'Beranda',
            onTap: () => onTabSelected(0),
          ),
          _TabItem(
            index: 1,
            isSelected: selectedIndex == 1,
            icon: Icons.assignment_outlined,
            label: 'Tugas',
            onTap: () => onTabSelected(1),
          ),
          _TabItem(
            index: 2,
            isSelected: selectedIndex == 2,
            icon: Icons.people_outline,
            label: 'Sosial',
            onTap: () => onTabSelected(2),
          ),
          _TabItem(
            index: 3,
            isSelected: selectedIndex == 3,
            icon: Icons.person_outline,
            label: 'Profil',
            onTap: () => onTabSelected(3),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final int index;
  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TabItem({
    required this.index,
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.forest : AppColors.muted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption1Bold.copyWith(
                color: color,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
