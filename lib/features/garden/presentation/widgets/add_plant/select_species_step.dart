import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/features/garden/domain/models/plant_catalog_model.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/features/garden/presentation/widgets/catalog_plant_card.dart';
import 'package:plenty/features/garden/presentation/widgets/catalog_search_bar.dart';

class SelectSpeciesStep extends StatefulWidget {
  final PlantCatalogModel? selectedSpecies;
  final ValueChanged<PlantCatalogModel> onSpeciesSelected;
  final IPlantRepository? plantRepository;

  const SelectSpeciesStep({
    super.key,
    required this.selectedSpecies,
    required this.onSpeciesSelected,
    this.plantRepository,
  });

  @override
  State<SelectSpeciesStep> createState() => _SelectSpeciesStepState();
}

class _SelectSpeciesStepState extends State<SelectSpeciesStep> {
  final _searchController = TextEditingController();
  late final IPlantRepository _plantRepo;
  Timer? _debounceTimer;

  List<PlantCatalogModel> _catalog = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _plantRepo = widget.plantRepository ?? Injector.plantRepository;
    _loadCatalog();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await _plantRepo.getCatalogPlants(query: query);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _catalog = data;
          _isLoading = false;
          _errorMessage = null;
        });
      case Error(:final failure):
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
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
                : _errorMessage != null && _filteredSpecies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTypography.headline.copyWith(
                            color: AppColors.ink,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _loadCatalog(query: _searchQuery),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forest,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
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
