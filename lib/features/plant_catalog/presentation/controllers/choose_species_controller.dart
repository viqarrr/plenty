import 'package:flutter/foundation.dart';
import 'package:plenty/core/utils/debouncer.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository.dart';
import 'package:plenty/features/plant_catalog/domain/models/plant_catalog_model.dart';

/// Immutable state for botanical species search & selection screen.
class ChooseSpeciesState {
  final String query;
  final String careFilter;
  final List<PlantCatalogModel> speciesList;
  final List<PlantCatalogModel> filteredList;
  final bool isLoading;
  final String? errorMessage;

  const ChooseSpeciesState({
    this.query = '',
    this.careFilter = 'Semua',
    this.speciesList = const [],
    this.filteredList = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChooseSpeciesState copyWith({
    String? query,
    String? careFilter,
    List<PlantCatalogModel>? speciesList,
    List<PlantCatalogModel>? filteredList,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChooseSpeciesState(
      query: query ?? this.query,
      careFilter: careFilter ?? this.careFilter,
      speciesList: speciesList ?? this.speciesList,
      filteredList: filteredList ?? this.filteredList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// ChangeNotifier managing debounce search, catalog loading, and care level filtering.
class ChooseSpeciesController extends ChangeNotifier {
  final PlantRepository _plantRepository;
  final Debouncer _debouncer;

  ChooseSpeciesState _state = const ChooseSpeciesState();
  ChooseSpeciesState get state => _state;

  bool _isDisposed = false;

  ChooseSpeciesController({
    PlantRepository? plantRepository,
    Debouncer? debouncer,
    bool autoLoad = true,
  })  : _plantRepository = plantRepository ?? PlantRepository(),
        _debouncer =
            debouncer ?? Debouncer(delay: const Duration(milliseconds: 400)) {
    if (autoLoad) {
      loadInitialCatalog();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debouncer.dispose();
    super.dispose();
  }

  void _updateState(ChooseSpeciesState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  /// Loads the default catalog list.
  Future<void> loadInitialCatalog() async {
    _updateState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      final list = await _plantRepository.getCatalogPlants();
      _updateState(
        _state.copyWith(
          speciesList: list,
          filteredList: _applyFilter(list, _state.query, _state.careFilter),
          isLoading: false,
        ),
      );
    } catch (e) {
      _updateState(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat katalog: $e',
        ),
      );
    }
  }

  /// Triggers a debounced search query.
  void onSearchChanged(String query) {
    _updateState(_state.copyWith(query: query, isLoading: true));

    _debouncer.run(() async {
      try {
        final results = await _plantRepository.getCatalogPlants(query: query);
        _updateState(
          _state.copyWith(
            speciesList: results,
            filteredList: _applyFilter(results, query, _state.careFilter),
            isLoading: false,
          ),
        );
      } catch (e) {
        _updateState(
          _state.copyWith(
            isLoading: false,
            errorMessage: 'Gagal mencari tanaman: $e',
          ),
        );
      }
    });
  }

  /// Updates the care category filter and re-filters the displayed list.
  void setCareFilter(String careFilter) {
    _updateState(
      _state.copyWith(
        careFilter: careFilter,
        filteredList: _applyFilter(_state.speciesList, _state.query, careFilter),
      ),
    );
  }

  List<PlantCatalogModel> _applyFilter(
    List<PlantCatalogModel> list,
    String query,
    String careFilter,
  ) {
    final q = query.trim().toLowerCase();
    final filter = careFilter.trim().toLowerCase();

    return list.where((plant) {
      final matchesQuery = q.isEmpty ||
          plant.commonName.toLowerCase().contains(q) ||
          (plant.scientificName ?? '').toLowerCase().contains(q);

      bool matchesCare = true;
      if (filter == 'easy care' || filter == 'mudah') {
        matchesCare = (plant.careLevel ?? '').toLowerCase().contains('easy');
      } else if (filter == 'pencahayaan rendah' || filter == 'low light') {
        matchesCare =
            (plant.sunlightLevel ?? '').toLowerCase().contains('rendah') ||
                (plant.sunlightLevel ?? '').toLowerCase().contains('low');
      }

      return matchesQuery && matchesCare;
    }).toList();
  }
}
