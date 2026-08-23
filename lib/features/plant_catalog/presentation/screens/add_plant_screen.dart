import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/features/plant_catalog/domain/models/plant_catalog_model.dart';
import 'package:plenty/features/plant_catalog/presentation/screens/add_plant_flow_screen.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/catalog_plant_card.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/catalog_search_bar.dart';
import 'package:plenty/features/plant_catalog/presentation/screens/species_detail_preview_screen.dart';

class AddPlantScreen extends StatefulWidget {
  final IPlantRepository? plantRepository;

  const AddPlantScreen({super.key, this.plantRepository});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _searchController = TextEditingController();
  late final IPlantRepository _plantRepository;
  Timer? _debounceTimer;

  List<PlantCatalogModel> _catalog = [];
  String _selectedCareFilter = 'Semua';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _plantRepository = widget.plantRepository ?? Injector.plantRepository;
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
    final result = await _plantRepository.getCatalogPlants(query: query);
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

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _searchQuery = query.trim().toLowerCase());
      _loadCatalog(query: query.trim());
    });
  }

  List<PlantCatalogModel> get _filteredCatalog {
    return _catalog.where((species) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          species.commonName.toLowerCase().contains(_searchQuery) ||
          (species.scientificName?.toLowerCase().contains(_searchQuery) ??
              false);

      bool matchesCare = true;
      if (_selectedCareFilter == 'Easy Care') {
        final care = (species.careLevel ?? '').toLowerCase();
        matchesCare = care.contains('easy') || care.contains('mudah');
      } else if (_selectedCareFilter == 'Pencahayaan Rendah') {
        final sun = (species.sunlightLevel ?? '').toLowerCase();
        matchesCare = sun.contains('low') || sun.contains('rendah');
      }

      return matchesSearch && matchesCare;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            CatalogSearchBar(
              controller: _searchController,
              onQueryChanged: _onQueryChanged,
              selectedFilter: _selectedCareFilter,
              onFilterSelected: (filter) =>
                  setState(() => _selectedCareFilter = filter),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.forest),
                    )
                  : _errorMessage != null && _filteredCatalog.isEmpty
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
                  : _filteredCatalog.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tanaman tidak ditemukan',
                            style: AppTypography.headline.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: _filteredCatalog.length,
                      itemBuilder: (context, index) {
                        final species = _filteredCatalog[index];
                        return CatalogPlantCard(
                          species: species,
                          onTap: () {
                            context.push(
                              SpeciesDetailPreviewScreen(
                                species: species,
                                onAddToCollection: () {
                                  context.push(const AddPlantFlowScreen());
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
