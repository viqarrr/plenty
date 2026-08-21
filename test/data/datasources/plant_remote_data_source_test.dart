import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/network/api_client.dart';
import 'package:plenty/features/plant_catalog/data/datasources/plant_remote_data_source.dart';
import 'package:plenty/features/plant_catalog/domain/models/perenual_species_list_response.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlantRemoteDataSource Unit Tests', () {
    test('PerenualSpeciesListResponse parses pagination metadata correctly', () {
      final json = {
        'data': [
          {
            'id': 1,
            'common_name': 'Silver Fir',
            'scientific_name': ['Abies alba'],
          }
        ],
        'total': 100,
        'per_page': 30,
        'current_page': 1,
        'last_page': 4,
        'from': 1,
        'to': 30,
      };

      final response = PerenualSpeciesListResponse.fromJson(json);
      expect(response.total, 100);
      expect(response.perPage, 30);
      expect(response.currentPage, 1);
      expect(response.lastPage, 4);
      expect(response.data.length, 1);
      expect(response.data.first.id, 1);
    });

    test('fetchSpeciesList returns parsed PerenualSpeciesModel list on HTTP 200',
        () async {
      final mockResponseData = {
        'data': [
          {
            'id': 1,
            'common_name': 'European Silver Fir',
            'scientific_name': ['Abies alba'],
            'other_name': ['Common Silver Fir'],
            'family': 'Pinaceae',
            'cycle': 'Perennial',
            'watering': 'Frequent',
            'sunlight': ['full sun', 'part shade'],
            'default_image': {
              'regular_url': 'https://perenual.com/storage/fir.jpg',
              'thumbnail': 'https://perenual.com/storage/fir_thumb.jpg',
            },
          },
          {
            'id': 2,
            'common_name': 'Monstera Deliciosa',
            'scientific_name': ['Monstera deliciosa'],
            'watering': 'Average',
            'sunlight': ['part shade'],
            'default_image': null,
          }
        ],
        'to': 2,
        'per_page': 30,
        'current_page': 1,
        'total': 2,
      };

      final client = MockClient((request) async {
        expect(request.url.path, contains('/species-list'));
        expect(request.url.queryParameters['key'], isNotEmpty);
        expect(request.url.queryParameters['q'], 'monstera');
        return http.Response(jsonEncode(mockResponseData), 200);
      });

      final apiClient = ApiClient(client: client);
      final dataSource = PlantRemoteDataSourceImpl(apiClient: apiClient);

      final result = await dataSource.fetchSpeciesList(query: 'monstera');

      expect(result.length, 2);
      expect(result[0].id, 1);
      expect(result[0].commonName, 'European Silver Fir');
      expect(result[0].scientificName, ['Abies alba']);
      expect(result[0].defaultImageUrl, 'https://perenual.com/storage/fir.jpg');
      expect(result[0].wateringIntervalDays, 3);
      expect(result[1].id, 2);
      expect(result[1].defaultImageUrl, isNull);
      expect(result[1].wateringIntervalDays, 7);
    });

    test('fetchSpeciesDetails returns parsed PerenualDetailModel on HTTP 200',
        () async {
      final mockDetailData = {
        'id': 123,
        'common_name': 'Monstera Deliciosa',
        'scientific_name': ['Monstera deliciosa'],
        'family': 'Araceae',
        'origin': ['Mexico', 'Central America'],
        'soil': ['Loam', 'Peat'],
        'type': 'Vine',
        'cycle': 'Perennial',
        'watering': 'Average',
        'watering_general_benchmark': {
          'value': '7-10',
          'unit': 'days',
        },
        'sunlight': ['bright indirect', 'part shade'],
        'care_level': 'Medium',
        'maintenance': 'Low',
        'poisonous_to_humans': 1,
        'poisonous_to_pets': 1,
        'description': 'Popular Swiss Cheese Plant.',
        'default_image': {
          'regular_url': 'https://perenual.com/storage/monstera.jpg',
        },
      };

      final client = MockClient((request) async {
        expect(request.url.path, contains('/species/details/123'));
        return http.Response(jsonEncode(mockDetailData), 200);
      });

      final apiClient = ApiClient(client: client);
      final dataSource = PlantRemoteDataSourceImpl(apiClient: apiClient);

      final result = await dataSource.fetchSpeciesDetails(123);

      expect(result.id, 123);
      expect(result.commonName, 'Monstera Deliciosa');
      expect(result.family, 'Araceae');
      expect(result.soil, ['Loam', 'Peat']);
      expect(result.poisonousToPets, isTrue);
      expect(result.poisonousToHumans, isTrue);
      expect(result.toxicityDescription,
          'Beracun untuk manusia & hewan peliharaan');
      expect(result.careLevelDisplay, 'INTERMEDIATE');
      expect(result.wateringIntervalDays, 9); // Average of 7-10 is 8.5 -> round to 9
      expect(result.defaultImageUrl, 'https://perenual.com/storage/monstera.jpg');
    });

    test('fetchSpeciesCareGuides returns parsed PerenualCareGuideModel list on HTTP 200',
        () async {
      final mockCareGuideData = {
        'data': [
          {
            'id': 1,
            'species_id': 123,
            'common_name': 'Monstera Deliciosa',
            'scientific_name': ['Monstera deliciosa'],
            'section': [
              {
                'id': 1,
                'type': 'watering',
                'description': 'Water when top 2 inches of soil are dry.',
              },
              {
                'id': 2,
                'type': 'sunlight',
                'description': 'Provide medium to bright indirect light.',
              },
              {
                'id': 3,
                'type': 'pruning',
                'description': 'Prune yellowing leaves near stem base.',
              }
            ]
          }
        ]
      };

      final client = MockClient((request) async {
        expect(request.url.path, contains('/species-care-guide-list'));
        expect(request.url.queryParameters['species_id'], '123');
        return http.Response(jsonEncode(mockCareGuideData), 200);
      });

      final apiClient = ApiClient(client: client);
      final dataSource = PlantRemoteDataSourceImpl(apiClient: apiClient);

      final result = await dataSource.fetchSpeciesCareGuides(123);

      expect(result.length, 1);
      expect(result.first.speciesId, 123);
      expect(result.first.sections.length, 3);
      expect(result.first.wateringAdvice,
          'Water when top 2 inches of soil are dry.');
      expect(result.first.sunlightAdvice,
          'Provide medium to bright indirect light.');
      expect(result.first.pruningAdvice,
          'Prune yellowing leaves near stem base.');
    });

    test('fetchSpeciesDetails throws NotFoundFailure on HTTP 404', () async {
      final client = MockClient((request) async {
        return http.Response('{"message": "Not Found"}', 404);
      });

      final apiClient = ApiClient(client: client);
      final dataSource = PlantRemoteDataSourceImpl(apiClient: apiClient);

      expect(
        () => dataSource.fetchSpeciesDetails(99999),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('fetchSpeciesList throws ServerFailure on HTTP 429 Quota Exceeded',
        () async {
      final client = MockClient((request) async {
        return http.Response('{"message": "Too Many Requests"}', 429);
      });

      final apiClient = ApiClient(client: client);
      final dataSource = PlantRemoteDataSourceImpl(apiClient: apiClient);

      expect(
        () => dataSource.fetchSpeciesList(),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('fetchSpeciesList throws ServerFailure on HTTP 500 Internal Error',
        () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final apiClient = ApiClient(client: client);
      final dataSource = PlantRemoteDataSourceImpl(apiClient: apiClient);

      expect(
        () => dataSource.fetchSpeciesList(),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
