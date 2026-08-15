import 'package:flutter/material.dart';
import 'package:plenty/core/constants/app_colors.dart';
import 'package:plenty/core/constants/app_typography.dart';
import 'package:plenty/core/utils/extensions/navigator_extension.dart';
import 'package:plenty/features/plant/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/plant/domain/entities/plant_entity.dart';
import 'package:plenty/features/plant/domain/repositories/plant_repository.dart';
import 'package:plenty/features/plant/presentation/catalog/widgets/catalog_plant_card.dart';
import 'package:plenty/features/plant/presentation/catalog/widgets/catalog_search_bar.dart';
import 'package:plenty/features/plant/presentation/detail/plant_detail_screen.dart';

/// Screen listing plant catalog with real-time search & filter chips.
class AddPlantScreen extends StatefulWidget {
  final PlantRepository? plantRepository;

  const AddPlantScreen({super.key, this.plantRepository});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _searchController = TextEditingController();
  late final PlantRepository _plantRepository;

  List<PlantEntity> _catalog = [];
  String _selectedCareFilter = 'Semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _plantRepository = widget.plantRepository ?? PlantRepositoryImpl();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final result = await _plantRepository.getCatalogPlants();
    if (!mounted) return;
    setState(() {
      _catalog = result.dataOrNull ?? [];
    });
  }

  List<PlantEntity> get _filteredCatalog {
    return _catalog.where((plant) {
      final matchesSearch = plant.name.toLowerCase().contains(_searchQuery) ||
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
              onQueryChanged: (query) => setState(() => _searchQuery = query.trim().toLowerCase()),
              selectedFilter: _selectedCareFilter,
              onFilterSelected: (filter) => setState(() => _selectedCareFilter = filter),
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
                            context.push(PlantDetailScreen(plant: plant));
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
