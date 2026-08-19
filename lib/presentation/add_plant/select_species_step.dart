import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/data/models/plant_catalog_model.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/presentation/add_plant/catalog_plant_card.dart';
import 'package:plenty/presentation/add_plant/catalog_search_bar.dart';

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
  String _selectedFilter = 'Semua';

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
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query.toLowerCase();
      });
      _loadCatalog(query: query);
    });
  }

  List<PlantCatalogModel> get _filteredSpecies {
    var list = _catalog;
    if (_searchQuery.isNotEmpty) {
      list = list.where((item) {
        final name = item.commonName.toLowerCase();
        final sci = (item.scientificName ?? '').toLowerCase();
        return name.contains(_searchQuery) || sci.contains(_searchQuery);
      }).toList();
    }

    if (_selectedFilter == 'Easy Care') {
      list = list.where((item) {
        final care = (item.careLevel ?? '').toLowerCase();
        return care.contains('easy') || care.contains('mudah');
      }).toList();
    } else if (_selectedFilter == 'Pencahayaan Rendah') {
      list = list.where((item) {
        final sun = (item.sunlightLevel ?? '').toLowerCase();
        return sun.contains('low') || sun.contains('rendah');
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Spesies Tanaman',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.inkSoft,
              fontSize: 32,
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
          const SizedBox(height: 12),
          CatalogSearchBar(
            controller: _searchController,
            onQueryChanged: _onSearchChanged,
            selectedFilter: _selectedFilter,
            onFilterSelected: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
          const SizedBox(height: 12),
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
                : ListView.builder(
                    itemCount: _filteredSpecies.length,
                    itemBuilder: (context, index) {
                      final species = _filteredSpecies[index];
                      return CatalogPlantCard(
                        species: species,
                        isSelected: widget.selectedSpecies?.id == species.id,
                        onTap: () => widget.onSpeciesSelected(species),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
