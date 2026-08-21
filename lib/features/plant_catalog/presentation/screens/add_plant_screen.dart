import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/plant_catalog/domain/models/plant_catalog_model.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository.dart';
import 'package:plenty/features/plant_catalog/presentation/screens/add_plant_flow_screen.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/catalog_plant_card.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/catalog_search_bar.dart';
import 'package:plenty/features/plant_catalog/presentation/screens/species_detail_preview_screen.dart';

class AddPlantScreen extends StatefulWidget {
  final PlantRepository? plantRepository;

  const AddPlantScreen({super.key, this.plantRepository});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _searchController = TextEditingController();
  late final PlantRepository _plantRepository;
  Timer? _debounceTimer;

  List<PlantCatalogModel> _catalog = [];
  String _selectedCareFilter = 'Semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _plantRepository = widget.plantRepository ?? PlantRepository();
    _loadCatalog();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog({String query = ''}) async {
    final catalogList = await _plantRepository.getCatalogPlants(query: query);
    if (!mounted) return;
    setState(() {
      _catalog = catalogList;
    });
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
              child: _filteredCatalog.isEmpty
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
