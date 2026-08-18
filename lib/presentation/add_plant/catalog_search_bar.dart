import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';

class CatalogSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const CatalogSearchBar({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  static const List<String> careFilters = [
    'Semua',
    'Easy Care',
    'Pencahayaan Rendah',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Cari spesies tanaman...',
              hintStyle: AppTypography.calloutRegular.copyWith(
                color: AppColors.muted,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.muted,
                        size: 20,
                      ),
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.forest, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: careFilters.map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => onFilterSelected(filter),
                    selectedColor: AppColors.forest,
                    backgroundColor: AppColors.surface,
                    labelStyle: AppTypography.footnoteBold.copyWith(
                      color: isSelected ? Colors.white : AppColors.inkSoft,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.forest : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
