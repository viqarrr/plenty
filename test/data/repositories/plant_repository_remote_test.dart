import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/garden/data/data_sources/plant_remote_data_source.dart';
import 'package:plenty/features/garden/data/datasources/garden_remote_datasource.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/core/storage/storage_remote_datasource.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockPlantRemoteDataSource extends Mock implements PlantRemoteDataSource {}
class MockGardenRemoteDataSource extends Mock
    implements GardenRemoteDataSource {}
class MockStorageRemoteDataSource extends Mock
    implements StorageRemoteDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late MockPlantRemoteDataSource mockPerenualDataSource;
  late MockGardenRemoteDataSource mockGardenRemoteDataSource;
  late PlantRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(
      PlantModel(
        id: 'fallback_plant',
        userId: 'fallback_user',
        nickname: 'Fallback',
      ),
    );
  });

  setUp(() async {
    final uniqueName =
        'plant_repo_remote_test_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(uniqueName);
    await dbHelper.deleteDb();

    mockPerenualDataSource = MockPlantRemoteDataSource();
    mockGardenRemoteDataSource = MockGardenRemoteDataSource();

    repository = PlantRepositoryImpl(
      dbHelper: dbHelper,
      remoteDataSource: mockPerenualDataSource,
      gardenRemoteDataSource: mockGardenRemoteDataSource,
    );
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('PlantRepository Remote Sync & Offline Resilience Tests', () {
    test('addPlant dual-writes plant to local SQLite and Cloud Firestore', () async {
      when(() => mockGardenRemoteDataSource.savePlant(any()))
          .thenAnswer((_) async {});

      final addResult = await repository.addPlant(
        userId: 'user_cloud_123',
        nickname: 'Monstera Albo',
        isIndoor: true,
      );

      expect(addResult, isA<Success<AddPlantResult>>());
      final plant = (addResult as Success<AddPlantResult>).data.plant;
      expect(plant.nickname, 'Monstera Albo');

      verify(() => mockGardenRemoteDataSource.savePlant(any())).called(1);

      // Verify stored locally in SQLite
      final localFetch = await repository.getUserPlants('user_cloud_123');
      expect(localFetch.dataOrNull!.any((p) => p.id == plant.id), isTrue);
    });

    test('getUserPlants syncs remote plants into local SQLite cache', () async {
      final remotePlant = PlantModel(
        id: 'plant_remote_cloud_1',
        userId: 'user_cloud_123',
        nickname: 'Philodendron Pink Princess',
        siteId: 'site_default_ruang_tamu',
        level: 3,
        xp: 120,
        adoptedAt: DateTime.now(),
      );

      when(() => mockGardenRemoteDataSource.getUserPlants('user_cloud_123'))
          .thenAnswer((_) async => [remotePlant]);

      final result = await repository.getUserPlants('user_cloud_123');

      expect(result, isA<Success<List<PlantModel>>>());
      final plants = result.dataOrNull!;
      expect(plants.any((p) => p.id == 'plant_remote_cloud_1'), isTrue);
      expect(plants.firstWhere((p) => p.id == 'plant_remote_cloud_1').nickname,
          'Philodendron Pink Princess');
    });

    test('getPlantById queries Cloud Firestore if missing in SQLite and caches locally', () async {
      final remotePlant = PlantModel(
        id: 'plant_absent_in_sqlite',
        userId: 'user_cloud_123',
        nickname: 'Anthurium Clarinervium',
        siteId: 'site_default_ruang_tamu',
      );

      when(() => mockGardenRemoteDataSource.getPlantById('plant_absent_in_sqlite'))
          .thenAnswer((_) async => remotePlant);

      final result = await repository.getPlantById('plant_absent_in_sqlite');

      expect(result, isA<Success<PlantModel?>>());
      expect(result.dataOrNull, isNotNull);
      expect(result.dataOrNull!.nickname, 'Anthurium Clarinervium');
      verify(() => mockGardenRemoteDataSource.getPlantById('plant_absent_in_sqlite'))
          .called(1);
    });

    test('archivePlant updates local SQLite and remote data source', () async {
      when(() => mockGardenRemoteDataSource.savePlant(any()))
          .thenAnswer((_) async {});
      when(() => mockGardenRemoteDataSource.archivePlant(any()))
          .thenAnswer((_) async {});

      final addResult = await repository.addPlant(
        userId: 'user_cloud_123',
        nickname: 'Tanaman Arsip',
        isIndoor: true,
      );
      final plantId = (addResult as Success<AddPlantResult>).data.plant.id;

      final archiveRes = await repository.archivePlant(plantId);
      expect(archiveRes, isA<Success<void>>());

      verify(() => mockGardenRemoteDataSource.archivePlant(plantId)).called(1);

      // Verify it is no longer returned in active user plants
      final activePlants = await repository.getUserPlants('user_cloud_123');
      expect(activePlants.dataOrNull!.any((p) => p.id == plantId), isFalse);
    });

    test('updatePlantInfo updates local SQLite and remote data source', () async {
      when(() => mockGardenRemoteDataSource.savePlant(any()))
          .thenAnswer((_) async {});
      when(() => mockGardenRemoteDataSource.updatePlant(any(), any()))
          .thenAnswer((_) async {});

      final addResult = await repository.addPlant(
        userId: 'user_cloud_123',
        nickname: 'Nama Lama',
        isIndoor: true,
      );
      final plantId = (addResult as Success<AddPlantResult>).data.plant.id;

      final updateRes = await repository.updatePlantInfo(
        plantId: plantId,
        nickname: 'Nama Baru Super',
      );
      expect(updateRes, isA<Success<void>>());

      verify(() => mockGardenRemoteDataSource.updatePlant(plantId, any())).called(1);

      final fetched = await repository.getPlantById(plantId);
      expect(fetched.dataOrNull!.nickname, 'Nama Baru Super');
    });

    test('deletePlant deletes from local SQLite and remote data source', () async {
      when(() => mockGardenRemoteDataSource.savePlant(any()))
          .thenAnswer((_) async {});
      when(() => mockGardenRemoteDataSource.deletePlant(any()))
          .thenAnswer((_) async {});

      final addResult = await repository.addPlant(
        userId: 'user_cloud_123',
        nickname: 'Tanaman Hapus',
        isIndoor: true,
      );
      final plantId = (addResult as Success<AddPlantResult>).data.plant.id;

      final delRes = await repository.deletePlant(plantId);
      expect(delRes, isA<Success<void>>());

      verify(() => mockGardenRemoteDataSource.deletePlant(plantId)).called(1);

      final fetched = await repository.getPlantById(plantId);
      expect(fetched.dataOrNull, isNull);
    });

    test('Offline resilience: operations succeed locally even if remote throws', () async {
      when(() => mockGardenRemoteDataSource.savePlant(any()))
          .thenThrow(Exception('No internet'));
      when(() => mockGardenRemoteDataSource.getUserPlants(any()))
          .thenThrow(Exception('No internet'));

      final addResult = await repository.addPlant(
        userId: 'user_cloud_123',
        nickname: 'Tanaman Offline',
        isIndoor: true,
      );
      expect(addResult, isA<Success<AddPlantResult>>());

      final getResult = await repository.getUserPlants('user_cloud_123');
      expect(getResult, isA<Success<List<PlantModel>>>());
      expect(getResult.dataOrNull!.any((p) => p.nickname == 'Tanaman Offline'), isTrue);
    });

    test('addPlant with customPhotoPath uploads photo to StorageRemoteDataSource and persists storage URL', () async {
      final mockStorage = MockStorageRemoteDataSource();
      when(() => mockStorage.uploadFile(
            filePath: any(named: 'filePath'),
            destinationPath: any(named: 'destinationPath'),
          )).thenAnswer((_) async => 'https://storage.googleapis.com/plant_custom.jpg');
      when(() => mockGardenRemoteDataSource.savePlant(any()))
          .thenAnswer((_) async {});

      final repoWithStorage = PlantRepositoryImpl(
        dbHelper: dbHelper,
        remoteDataSource: mockPerenualDataSource,
        gardenRemoteDataSource: mockGardenRemoteDataSource,
        storageRemoteDataSource: mockStorage,
      );

      final addResult = await repoWithStorage.addPlant(
        userId: 'user_cloud_123',
        nickname: 'Monstera Albo',
        isIndoor: true,
        customPhotoPath: '/local/cache/plant.jpg',
      );

      expect(addResult, isA<Success<AddPlantResult>>());
      verify(() => mockStorage.uploadFile(
            filePath: '/local/cache/plant.jpg',
            destinationPath: any(named: 'destinationPath'),
          )).called(1);

      final savedPlants = await repoWithStorage.getUserPlants('user_cloud_123');
      expect(savedPlants.dataOrNull!.first.coverPhotoPath,
          'https://storage.googleapis.com/plant_custom.jpg');
    });
  });
}
