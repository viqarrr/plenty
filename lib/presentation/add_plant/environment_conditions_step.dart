import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

class EnvironmentConditionsStep extends StatelessWidget {
  final bool isIndoor;
  final String sunlight;
  final String potSize;
  final String windowDistance;
  final void Function({
    required bool isIndoor,
    String? sunlight,
    String? potSize,
    String? windowDistance,
  })
  onEnvironmentChanged;

  const EnvironmentConditionsStep({
    super.key,
    required this.isIndoor,
    required this.sunlight,
    required this.potSize,
    required this.windowDistance,
    required this.onEnvironmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kondisi Lingkungan',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.inkSoft,
              fontSize: 26,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Beri tahu kami di mana tanaman ini akan ditempatkan.',
            style: AppTypography.bodyRegular.copyWith(
              color: AppColors.muted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Lokasi Penempatan',
            style: AppTypography.title2Bold.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildChoiceCard(
                  title: 'Indoor',
                  subtitle: 'Dalam Ruangan',
                  icon: Icons.home_outlined,
                  isSelected: isIndoor,
                  onTap: () => onEnvironmentChanged(
                    isIndoor: true,
                    sunlight: sunlight,
                    potSize: potSize,
                    windowDistance: windowDistance,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChoiceCard(
                  title: 'Outdoor',
                  subtitle: 'Balkon / Teras',
                  icon: Icons.wb_sunny_outlined,
                  isSelected: !isIndoor,
                  onTap: () => onEnvironmentChanged(
                    isIndoor: false,
                    sunlight: sunlight,
                    potSize: potSize,
                    windowDistance: windowDistance,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Intensitas Cahaya',
            style: AppTypography.title2Bold.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildSelectTile(
            title: 'Sinar Tidak Langsung Terang (Bright Indirect)',
            isSelected: sunlight == 'Sinar Tidak Langsung',
            onTap: () => onEnvironmentChanged(
              isIndoor: isIndoor,
              sunlight: 'Sinar Tidak Langsung',
              potSize: potSize,
              windowDistance: windowDistance,
            ),
          ),
          const SizedBox(height: 8),
          _buildSelectTile(
            title: 'Cahaya Rendah / Teduh (Low Light)',
            isSelected: sunlight == 'Cahaya Rendah',
            onTap: () => onEnvironmentChanged(
              isIndoor: isIndoor,
              sunlight: 'Cahaya Rendah',
              potSize: potSize,
              windowDistance: windowDistance,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Drainase Pot',
            style: AppTypography.title2Bold.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildSelectTile(
            title: 'Ada Lubang Drainase (Rekomendasi)',
            isSelected: potSize == 'Ada Lubang Drainase',
            onTap: () => onEnvironmentChanged(
              isIndoor: isIndoor,
              sunlight: sunlight,
              potSize: 'Ada Lubang Drainase',
              windowDistance: windowDistance,
            ),
          ),
          const SizedBox(height: 8),
          _buildSelectTile(
            title: 'Tanpa Lubang Drainase (Pot Hias)',
            isSelected: potSize == 'Tanpa Lubang Drainase',
            onTap: () => onEnvironmentChanged(
              isIndoor: isIndoor,
              sunlight: sunlight,
              potSize: 'Tanpa Lubang Drainase',
              windowDistance: windowDistance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pastelGreenBg : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.forest : AppColors.muted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.calloutBold.copyWith(
                color: isSelected ? AppColors.forest : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption1Regular.copyWith(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pastelGreenBg : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.forest : AppColors.muted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.footnoteBold.copyWith(
                  color: isSelected ? AppColors.forest : AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WizardEnvironmentStep extends StatelessWidget {
  final String environment;
  final String drainage;
  final ValueChanged<String> onEnvironmentChanged;
  final ValueChanged<String> onDrainageChanged;

  const WizardEnvironmentStep({
    super.key,
    required this.environment,
    required this.drainage,
    required this.onEnvironmentChanged,
    required this.onDrainageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lingkungan',
          style: AppTypography.headline.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildChoiceCard(
                'Indoor',
                Icons.home_filled,
                environment == 'Indoor',
                () => onEnvironmentChanged('Indoor'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChoiceCard(
                'Outdoor',
                Icons.wb_cloudy_rounded,
                environment == 'Outdoor',
                () => onEnvironmentChanged('Outdoor'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Detail Wadah',
          style: AppTypography.headline.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 12),
        _buildRadioRow(
          'Ada Lubang Drainase',
          'Di dalam ruangan menggunakan pot.',
          drainage == 'Ada Lubang Drainase',
          () => onDrainageChanged('Ada Lubang Drainase'),
        ),
        const SizedBox(height: 12),
        _buildRadioRow(
          'Tanpa Lubang Drainase',
          'Di luar ruangan menggunakan pot.',
          drainage == 'Tanpa Lubang Drainase',
          () => onDrainageChanged('Tanpa Lubang Drainase'),
        ),
      ],
    );
  }

  Widget _buildChoiceCard(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pastelGreenBg : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.forest : AppColors.muted,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.headline.copyWith(
                color: isSelected ? AppColors.forest : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioRow(
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pastelGreenBg : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headline.copyWith(
                      fontSize: 14,
                      color: isSelected ? AppColors.forest : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption1Regular.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.forest : AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
