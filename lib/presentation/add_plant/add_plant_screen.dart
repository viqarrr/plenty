import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/theme/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/presentation/add_plant/catalog_plant_card.dart';
import 'package:plenty/presentation/add_plant/catalog_search_bar.dart';
import 'package:plenty/presentation/plant_details/plant_details_screen.dart';

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

  List<PlantModel> _catalog = [];
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
      _catalog = catalogList
          .map(
            (c) => PlantModel(
              id: c.id,
              userId: 'usr_default',
              catalogId: c.id,
              nickname: c.commonName,
              commonName: c.commonName,
              defaultWateringInterval: c.defaultWateringInterval,
              careLevel: c.careLevel,
              sunlightCondition: c.sunlightLevel,
              coverPhotoPath: c.imageUrl,
              adoptedAt: DateTime.now(),
            ),
          )
          .toList();
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

  List<PlantModel> get _filteredCatalog {
    return _catalog.where((plant) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          plant.name.toLowerCase().contains(_searchQuery) ||
          plant.scientificName.toLowerCase().contains(_searchQuery);

      bool matchesCare = true;
      if (_selectedCareFilter == 'Easy Care') {
        matchesCare = plant.careLevel.toLowerCase().contains('easy');
      } else if (_selectedCareFilter == 'Pencahayaan Rendah') {
        matchesCare = plant.lightIntensity.toLowerCase().contains('rendah');
      }

      return matchesSearch && matchesCare;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDefault,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tambah Tanaman',
          style: AppTypography.title2Bold.copyWith(color: AppColors.ink),
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
                        final plant = _filteredCatalog[index];
                        return CatalogPlantCard(
                          plant: plant,
                          onTap: () {
                            context.push(PlantDetailsScreen(plant: plant));
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
