import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/widgets/custom_button.dart';

/// Modal bottom sheet for selecting the application theme.
///
/// Configured to enforce Light mode as the current default.
class ThemeSelectorSheet extends StatelessWidget {
  final String currentTheme;

  const ThemeSelectorSheet({super.key, required this.currentTheme});

  /// Opens the modal bottom sheet and returns the selected theme label.
  static Future<String?> show(
    BuildContext context, {
    required String currentTheme,
  }) {
    return context.showAppBottomSheet<String>(
      ThemeSelectorSheet(currentTheme: currentTheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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
          const SizedBox(height: 16),

          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tema Aplikasi',
                style: AppTypography.title2Bold.copyWith(
                  fontSize: 18,
                  color: AppColors.inkSoft,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.muted),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _ThemeOptionTile(
            title: 'Mode Terang (Light)',
            subtitle: 'Tema bawaan aplikasi Plenty saat ini (Aktif)',
            icon: Icons.wb_sunny_outlined,
            isSelected: currentTheme == 'Mode Terang' || currentTheme == 'Light',
            onTap: () => context.pop('Mode Terang'),
          ),
          const SizedBox(height: 8),

          _ThemeOptionTile(
            title: 'Sistem (Mengikuti Perangkat)',
            subtitle: 'Menggunakan preferensi sistem (Default: Terang)',
            icon: Icons.phone_android_outlined,
            isSelected: currentTheme == 'Sistem',
            onTap: () => context.pop('Sistem'),
          ),
          const SizedBox(height: 8),

          _ThemeOptionTile(
            title: 'Mode Gelap (Dark)',
            subtitle: 'Tampilan tema gelap',
            icon: Icons.nightlight_outlined,
            isSelected: currentTheme == 'Mode Gelap' || currentTheme == 'Dark',
            onTap: () => context.pop('Mode Gelap'),
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Tutup',
            isOutlined: true,
            height: 48,
            borderRadius: BorderRadius.circular(24),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pastelGreenBg : AppColors.searchBarSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.forest : AppColors.muted,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: isSelected
            ? AppTypography.calloutBold.copyWith(color: AppColors.forest)
            : AppTypography.calloutBold,
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption1Regular.copyWith(color: AppColors.muted),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.forest, size: 22)
          : const Icon(Icons.circle_outlined, color: AppColors.borderSubtle, size: 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.forest : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      tileColor: isSelected ? AppColors.pastelGreenBg.withValues(alpha: 0.3) : AppColors.surface,
      onTap: onTap,
    );
  }
}
