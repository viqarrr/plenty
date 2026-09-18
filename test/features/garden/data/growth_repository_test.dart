import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/garden/data/datasources/growth_remote_datasource.dart';
import 'package:plenty/features/garden/data/repositories/growth_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/growth_log_model.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:plenty/core/error/result.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockGrowthRemoteDataSource extends Mock
    implements GrowthRemoteDataSource {}
class MockBadgeRepository extends Mock implements IBadgeRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late MockGrowthRemoteDataSource mockRemoteDataSource;
  late MockBadgeRepository mockBadgeRepo;
  late GrowthRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(GrowthLogModel(
      id: 'fallback_log',
      userPlantId: 'plant_1',
      loggedAt: DateTime.now(),
    ));
    registerFallbackValue(TimeCapsuleModel(
      id: 'fallback_capsule',
      userPlantId: 'plant_1',
      photoPath: 'fallback.jpg',
      createdAt: DateTime.now(),
      unlockAt: DateTime.now(),
    ));
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('growth_repo_test.db');
    await dbHelper.deleteDb();

    mockRemoteDataSource = MockGrowthRemoteDataSource();
    mockBadgeRepo = MockBadgeRepository();

    repository = GrowthRepositoryImpl(
      dbHelper: dbHelper,
      remoteDataSource: mockRemoteDataSource,
      badgeRepo: mockBadgeRepo,
    );

    final db = await dbHelper.database;
    await db.insert(DatabaseHelper.tableUsers, {
      'id': 1,
      'email': 'growth@plenty.app',
      'display_name': 'Growth User',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert(DatabaseHelper.tableUserPlants, {
      'id': 'plant_1',
      'user_id': '1',
      'nickname': 'Monstera',
      'initial_height_cm': 20.0,
      'current_height': 20.0,
      'is_archived': 0,
      'adopted_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('GrowthRepositoryImpl Tests', () {
    test('getHeightSeries syncs remote logs into SQLite and returns sorted series', () async {
      final now = DateTime.now();
      final remoteLogs = [
        GrowthLogModel(
          id: 'log_remote_1',
          userPlantId: 'plant_1',
          heightCm: 25.0,
          loggedAt: now.add(const Duration(days: 1)),
        ),
      ];

      when(() => mockRemoteDataSource.getGrowthLogs('plant_1'))
          .thenAnswer((_) async => remoteLogs);

      final result = await repository.getHeightSeries('plant_1');

      expect(result.dataOrNull, isNotNull);
      final list = result.dataOrNull!;
      expect(list.length, 1);
      expect(list.first.id, 'log_remote_1');
      expect(list.first.heightCm, 25.0);
    });

    test('addGrowthLog saves locally and dual-writes to remote datasource', () async {
      when(() => mockRemoteDataSource.saveGrowthLog(any()))
          .thenAnswer((_) async {});

      final log = GrowthLogModel(
        id: 'log_add_1',
        userPlantId: 'plant_1',
        heightCm: 28.0,
        loggedAt: DateTime.now(),
        note: 'Daun baru muncul',
      );

      final result = await repository.addGrowthLog(log);

      expect(result.isSuccess, isTrue);
      verify(() => mockRemoteDataSource.saveGrowthLog(any())).called(1);

      // Verify stored in SQLite
      final db = await dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableGrowthLogs,
        where: 'id = ?',
        whereArgs: ['log_add_1'],
      );
      expect(rows.length, 1);
      expect(rows.first['height_cm'], 28.0);
    });

    test('saveTimeCapsule dual-writes to SQLite and remote datasource and awards badge if first', () async {
      when(() => mockRemoteDataSource.saveTimeCapsule(any()))
          .thenAnswer((_) async {});
      when(() => mockBadgeRepo.awardBadge(
            userId: any(named: 'userId'),
            badgeId: 'time_capsule',
          )).thenAnswer((_) async => const Success(true));

      final capsule = TimeCapsuleModel(
        id: 'capsule_1',
        userPlantId: 'plant_1',
        photoPath: 'capsule.jpg',
        note: 'Pesan rahasia',
        createdAt: DateTime.now(),
        unlockAt: DateTime.now().add(const Duration(days: 30)),
        isUnlocked: false,
      );

      final result = await repository.saveTimeCapsule(capsule);

      expect(result.dataOrNull, isTrue);
      verify(() => mockRemoteDataSource.saveTimeCapsule(any())).called(1);
      verify(() => mockBadgeRepo.awardBadge(
            userId: any(named: 'userId'),
            badgeId: 'time_capsule',
          )).called(1);
    });

    test('unlockTimeCapsule updates SQLite and calls remote unlock', () async {
      final db = await dbHelper.database;
      await db.insert(DatabaseHelper.tableTimeCapsules, {
        'id': 'capsule_unlock',
        'user_plant_id': 'plant_1',
        'photo_path': 'photo.jpg',
        'is_unlocked': 0,
        'created_at': DateTime.now().toIso8601String(),
        'unlock_at': DateTime.now().toIso8601String(),
      });

      when(() => mockRemoteDataSource.unlockTimeCapsule('capsule_unlock'))
          .thenAnswer((_) async {});

      final result = await repository.unlockTimeCapsule('capsule_unlock');

      expect(result.isSuccess, isTrue);
      verify(() => mockRemoteDataSource.unlockTimeCapsule('capsule_unlock')).called(1);

      final rows = await db.query(
        DatabaseHelper.tableTimeCapsules,
        where: 'id = ?',
        whereArgs: ['capsule_unlock'],
      );
      expect(rows.first['is_unlocked'], 1);
    });

    test('offline resilience: methods succeed even if remote datasource throws', () async {
      when(() => mockRemoteDataSource.saveGrowthLog(any()))
          .thenThrow(Exception('No internet'));

      final log = GrowthLogModel(
        id: 'log_offline_1',
        userPlantId: 'plant_1',
        heightCm: 30.0,
        loggedAt: DateTime.now(),
      );

      final result = await repository.addGrowthLog(log);

      expect(result.isSuccess, isTrue);
    });
  });
}
