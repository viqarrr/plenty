import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/repositories/plant_repository.dart';

class SelectSpeciesStep extends StatefulWidget {
  final PlantCatalogModel? selectedSpecies;
  final ValueChanged<PlantCatalogModel> onSpeciesSelected;

  const SelectSpeciesStep({
    super.key,
    required this.selectedSpecies,
    required this.onSpeciesSelected,
  });

  @override
  State<SelectSpeciesStep> createState() => _SelectSpeciesStepState();
}

class _SelectSpeciesStepState extends State<SelectSpeciesStep> {
  final _searchController = TextEditingController();
  final _plantRepo = PlantRepository();
  Timer? _debounceTimer;

  List<PlantCatalogModel> _catalog = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog({String query = ''}) async {
    setState(() => _isLoading = true);
    try {
      final list = await _plantRepo.getCatalogPlants(query: query);
      if (!mounted) return;
      setState(() {
        _catalog = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    final query = value.trim();

    // Batalkan timer sebelumnya bila user masih mengetik
    _debounceTimer?.cancel();

    // Tunggu 400ms sebelum memicu request/pencarian ke repository
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query.toLowerCase();
      });
      _loadCatalog(query: query);
    });
  }

  List<PlantCatalogModel> get _filteredSpecies {
    if (_searchQuery.isEmpty) return _catalog;
    return _catalog.where((item) {
      final name = item.commonName.toLowerCase();
      final sci = (item.scientificName ?? '').toLowerCase();
      return name.contains(_searchQuery) || sci.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Spesies Tanaman',
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.inkSoft,
            fontSize: 26,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pilih dari katalog botani atau cari berdasarkan nama.',
          style: AppTypography.bodyRegular.copyWith(
            color: AppColors.muted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Cari tanaman (e.g. Monstera, Pothos)...',
            hintStyle: AppTypography.calloutRegular.copyWith(
              color: AppColors.muted,
            ),
            prefixIcon: const Icon(Icons.search, color: AppColors.muted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _debounceTimer?.cancel();
                      setState(() => _searchQuery = '');
                      _loadCatalog(query: '');
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
        const SizedBox(height: 20),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.forest),
                )
              : _filteredSpecies.isEmpty
              ? Center(
                  child: Text(
                    'Tanaman tidak ditemukan',
                    style: AppTypography.headline.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredSpecies.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final species = _filteredSpecies[index];
                    final isSelected = widget.selectedSpecies?.id == species.id;

                    return InkWell(
                      onTap: () => widget.onSpeciesSelected(species),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.pastelGreenBg
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.forest
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.forest.withValues(alpha: 0.1),
                                      AppColors.emerald.withValues(alpha: 0.2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child:
                                    (species.imageUrl != null &&
                                        species.imageUrl!.isNotEmpty)
                                    ? Image.network(
                                        species.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.local_florist,
                                          color: AppColors.forest,
                                          size: 26,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.local_florist,
                                        color: AppColors.forest,
                                        size: 26,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    species.commonName,
                                    style: AppTypography.title2Bold.copyWith(
                                      fontSize: 16,
                                      color: isSelected
                                          ? AppColors.forest
                                          : AppColors.ink,
                                    ),
                                  ),
                                  if (species.scientificName != null &&
                                      species.scientificName!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      species.scientificName!,
                                      style: AppTypography.footnoteRegular
                                          .copyWith(
                                            color: AppColors.muted,
                                            fontStyle: FontStyle.italic,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildBadge(
                                        species.careLevel ?? 'EASY CARE',
                                        AppColors.pastelGreenBg,
                                        AppColors.pastelGreenText,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildBadge(
                                        'Siram tiap ${species.defaultWateringInterval} hari',
                                        AppColors.pastelBlueBg,
                                        AppColors.pastelBlueText,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.forest,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.caption1Bold.copyWith(color: text, fontSize: 9),
      ),
    );
  }
}
