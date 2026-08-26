import 'package:plenty/core/constants/api_constants.dart';
import 'package:plenty/core/network/api_client.dart';
import 'package:plenty/features/plant_catalog/domain/models/perenual_care_guide_model.dart';
import 'package:plenty/features/plant_catalog/domain/models/perenual_detail_model.dart';
import 'package:plenty/features/plant_catalog/domain/models/perenual_species_model.dart';

/// Contract for fetching botanical plant data from the remote Perenual API.
abstract class PlantRemoteDataSource {
  /// Fetches a paginated list of plant species from Perenual.
  Future<List<PerenualSpeciesModel>> fetchSpeciesList({
    int page = 1,
    String? query,
    int? indoor,
    String? watering,
    String? sunlight,
  });

  /// Fetches detailed botanical and care information for a specific species ID.
  Future<PerenualDetailModel> fetchSpeciesDetails(int speciesId);

  /// Fetches structured care guides (watering, sunlight, pruning) for a specific species ID.
  Future<List<PerenualCareGuideModel>> fetchSpeciesCareGuides(int speciesId);
}

/// Implementation of [PlantRemoteDataSource] using [ApiClient].
class PlantRemoteDataSourceImpl implements PlantRemoteDataSource {
  final ApiClient _apiClient;

  PlantRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<PerenualSpeciesModel>> fetchSpeciesList({
    int page = 1,
    String? query,
    int? indoor,
    String? watering,
    String? sunlight,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
    };
    if (query != null && query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (indoor != null) {
      queryParams['indoor'] = indoor;
    }
    if (watering != null && watering.trim().isNotEmpty) {
      queryParams['watering'] = watering.trim();
    }
    if (sunlight != null && sunlight.trim().isNotEmpty) {
      queryParams['sunlight'] = sunlight.trim();
    }

    final response = await _apiClient.get(
      ApiConstants.speciesListEndpoint,
      queryParameters: queryParams,
    );

    if (response is Map<String, dynamic>) {
      final dataList = response['data'];
      if (dataList is List) {
        return dataList
            .whereType<Map<String, dynamic>>()
            .map((item) => PerenualSpeciesModel.fromJson(item))
            .toList();
      }
    }

    return const [];
  }

  @override
  Future<PerenualDetailModel> fetchSpeciesDetails(int speciesId) async {
    final endpoint = '${ApiConstants.speciesDetailsEndpoint}/$speciesId';
    final response = await _apiClient.get(endpoint);

    if (response is Map<String, dynamic>) {
      return PerenualDetailModel.fromJson(response);
    }

    throw const FormatException('Format data detail tanaman tidak valid');
  }

  @override
  Future<List<PerenualCareGuideModel>> fetchSpeciesCareGuides(
      int speciesId) async {
    final response = await _apiClient.get(
      ApiConstants.speciesCareGuideEndpoint,
      queryParameters: {
        'species_id': speciesId,
      },
    );

    if (response is Map<String, dynamic>) {
      final dataList = response['data'];
      if (dataList is List) {
        return dataList
            .whereType<Map<String, dynamic>>()
            .map((item) => PerenualCareGuideModel.fromJson(item))
            .toList();
      }
    }

    return const [];
  }
}
