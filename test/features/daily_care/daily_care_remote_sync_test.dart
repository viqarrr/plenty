import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/storage/storage_remote_datasource.dart';
import 'package:plenty/features/daily_care/data/datasources/care_remote_datasource.dart';
import 'package:plenty/features/daily_care/data/repositories/daily_care_repository_impl.dart';
import 'package:plenty/features/daily_care/domain/models/care_action_log_model.dart';
import 'package:plenty/features/daily_care/domain/models/care_schedule_model.dart';
import 'package:plenty/features/garden/data/datasources/growth_remote_datasource.dart';
import 'package:plenty/features/garden/domain/models/growth_log_model.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockCareRemoteDataSource extends Mock implements CareRemoteDataSource {}
class MockGrowthRemoteDataSource extends Mock
    implements GrowthRemoteDataSource {}
class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}
class MockBadgeRepository extends Mock implements IBadgeRepository {}
class MockStorageRemoteDataSource extends Mock
    implements StorageRemoteDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late MockCareRemoteDataSource mockCareRemote;
  late MockGrowthRemoteDataSource mockGrowthRemote;
  late MockProfileRemoteDataSource mockProfileRemote;
  late MockBadgeRepository mockBadgeRepo;
  late DailyCareRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(CareActionLogModel(
      id: 'fallback_log',
      userPlantId: 'plant_1',
      taskType: 'siram',
      completedAt: DateTime.now(),
      logDate: '2026-09-09',
    ));
    registerFallbackValue(CareScheduleModel(
      id: 'fallback_sched',
      userPlantId: 'plant_1',
      taskType: 'siram',
      intervalDays: 3,
      nextDueDate: DateTime.now(),
    ));
    registerFallbackValue(GrowthLogModel(
      id: 'fallback_growth',
      userPlantId: 'plant_1',
      loggedAt: DateTime.now(),
    ));
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting('daily_care_sync_test.db');
    await dbHelper.deleteDb();

    mockCareRemote = MockCareRemoteDataSource();
    mockGrowthRemote = MockGrowthRemoteDataSource();
    mockProfileRemote = MockProfileRemoteDataSource();
    mockBadgeRepo = MockBadgeRepository();

    repository = DailyCareRepositoryImpl(
      dbHelper: dbHelper,
      badgeRepo: mockBadgeRepo,
      remoteDataSource: mockProfileRemote,
      careRemoteDataSource: mockCareRemote,
      growthRemoteDataSource: mockGrowthRemote,
    );

    final db = await dbHelper.database;
    await db.insert(DatabaseHelper.tableUsers, {
      'id': 1,
      'email': 'care_sync@plenty.app',
      'display_name': 'Care Sync User',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert(DatabaseHelper.tableUserPlants, {
      'id': 'plant_1',
      'user_id': '1',
      'nickname': 'Aglaonema',
      'initial_height_cm': 25.0,
      'current_height': 25.0,
      'is_archived': 0,
      'adopted_at': DateTime.now().toIso8601String(),
    });

    await db.insert(DatabaseHelper.tableCareSchedules, {
      'id': 'sched_plant_1_siram',
      'user_plant_id': 'plant_1',
      'task_type': 'siram',
      'interval_days': 3,
      'next_due_date': DateTime.now().toIso8601String(),
      'is_active': 1,
    });
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('DailyCareRepositoryImpl Remote Sync Tests', () {
    test('completeRoutineTask dual-writes care action log and updated schedule to Firestore', () async {
      when(() => mockCareRemote.saveCareActionLog(any()))
          .thenAnswer((_) async {});
      when(() => mockCareRemote.updateSchedule(any()))
          .thenAnswer((_) async {});
      when(() => mockProfileRemote.updateUserXpAndLevel(
            any(),
            totalXp: any(named: 'totalXp'),
            level: any(named: 'level'),
          )).thenAnswer((_) async {});

      final plant = PlantModel(
        id: 'plant_1',
        userId: '1',
        nickname: 'Aglaonema',
      );

      final result = await repository.completeRoutineTask(
        plant: plant,
        taskType: 'siram',
        notes: 'Disiram segar',
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockCareRemote.saveCareActionLog(any())).called(1);
      verify(() => mockCareRemote.updateSchedule(any())).called(1);

      // Verify SQLite state
      final db = await dbHelper.database;
      final logs = await db.query(
        DatabaseHelper.tableCareActionLogs,
        where: 'user_plant_id = ? AND task_type = ?',
        whereArgs: ['plant_1', 'siram'],
      );
      expect(logs.length, 1);
      expect(logs.first['xp_awarded'], 10);
    });

    test('completeHeightTask dual-writes growth log, care log, and schedule to remote datasources', () async {
      when(() => mockGrowthRemote.saveGrowthLog(any()))
          .thenAnswer((_) async {});
      when(() => mockCareRemote.saveCareActionLog(any()))
          .thenAnswer((_) async {});
      when(() => mockCareRemote.updateSchedule(any()))
          .thenAnswer((_) async {});
      when(() => mockProfileRemote.updateUserXpAndLevel(
            any(),
            totalXp: any(named: 'totalXp'),
            level: any(named: 'level'),
          )).thenAnswer((_) async {});

      final plant = PlantModel(
        id: 'plant_1',
        userId: '1',
        nickname: 'Aglaonema',
      );

      final result = await repository.completeHeightTask(
        plant: plant,
        heightCm: 28.0,
        note: 'Tinggi bertambah 3cm',
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockGrowthRemote.saveGrowthLog(any())).called(1);
      verify(() => mockCareRemote.saveCareActionLog(any())).called(1);
      verify(() => mockCareRemote.updateSchedule(any())).called(1);
    });

    test('getCareHistory fetches remote logs and caches in SQLite', () async {
      final now = DateTime.now();
      final remoteLogs = [
        CareActionLogModel(
          id: 'care_remote_1',
          userPlantId: 'plant_1',
          taskType: 'siram',
          completedAt: now,
          logDate: '2026-09-09',
          xpAwarded: 10,
        ),
      ];

      when(() => mockCareRemote.getCareActionLogs(userPlantId: 'plant_1'))
          .thenAnswer((_) async => remoteLogs);

      final result = await repository.getCareHistory(userPlantId: 'plant_1');

      expect(result.isSuccess, isTrue);
      verify(() => mockCareRemote.getCareActionLogs(userPlantId: 'plant_1')).called(1);

      // Verify cached in SQLite
      final db = await dbHelper.database;
      final cached = await db.query(
        DatabaseHelper.tableCareActionLogs,
        where: 'id = ?',
        whereArgs: ['care_remote_1'],
      );
      expect(cached.length, 1);
    });

    test('updateGrowthLog updates SQLite and writes to GrowthRemoteDataSource', () async {
      final db = await dbHelper.database;
      await db.insert(DatabaseHelper.tableGrowthLogs, {
        'id': 'log_to_update',
        'user_plant_id': 'plant_1',
        'height_cm': 25.0,
        'logged_at': DateTime.now().toIso8601String(),
        'source': 'manual',
      });

      when(() => mockGrowthRemote.updateGrowthLog(any(), any()))
          .thenAnswer((_) async {});

      final result = await repository.updateGrowthLog(
        logId: 'log_to_update',
        userPlantId: 'plant_1',
        heightCm: 27.5,
        note: 'Koreksi ukuran',
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockGrowthRemote.updateGrowthLog('log_to_update', any())).called(1);

      final rows = await db.query(
        DatabaseHelper.tableGrowthLogs,
        where: 'id = ?',
        whereArgs: ['log_to_update'],
      );
      expect(rows.first['height_cm'], 27.5);
      expect(rows.first['note'], 'Koreksi ukuran');
    });

    test('offline resilience: tasks succeed even if remote datasource throws', () async {
      when(() => mockCareRemote.saveCareActionLog(any()))
          .thenThrow(Exception('Firestore unreachable'));

      final plant = PlantModel(
        id: 'plant_1',
        userId: '1',
        nickname: 'Aglaonema',
      );

      final result = await repository.completeRoutineTask(
        plant: plant,
        taskType: 'bersih',
      );

      expect(result.isSuccess, isTrue);
    });

    test('completeHeightTask with photo uploads to StorageRemoteDataSource and persists storage download URL', () async {
      final mockStorage = MockStorageRemoteDataSource();
      final repoWithStorage = DailyCareRepositoryImpl(
        dbHelper: dbHelper,
        badgeRepo: mockBadgeRepo,
        remoteDataSource: mockProfileRemote,
        careRemoteDataSource: mockCareRemote,
        growthRemoteDataSource: mockGrowthRemote,
        storageRemoteDataSource: mockStorage,
      );

      when(() => mockGrowthRemote.saveGrowthLog(any())).thenAnswer((_) async {});
      when(() => mockCareRemote.saveCareActionLog(any())).thenAnswer((_) async {});
      when(() => mockCareRemote.updateSchedule(any())).thenAnswer((_) async {});
      when(() => mockProfileRemote.updateUserXpAndLevel(any(),
              totalXp: any(named: 'totalXp'), level: any(named: 'level')))
          .thenAnswer((_) async {});

      when(() => mockStorage.uploadFile(
            filePath: any(named: 'filePath'),
            destinationPath: any(named: 'destinationPath'),
          )).thenAnswer((_) async => 'https://firebasestorage.googleapis.com/growth_photo.jpg');

      final plant = PlantModel(
        id: 'plant_1',
        userId: '1',
        nickname: 'Aglaonema',
      );

      final result = await repoWithStorage.completeHeightTask(
        plant: plant,
        heightCm: 30.0,
        photoPath: '/local/cache/plant_snap.jpg',
        note: 'Ada daun baru',
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockStorage.uploadFile(
            filePath: '/local/cache/plant_snap.jpg',
            destinationPath: any(named: 'destinationPath'),
          )).called(1);

      // Verify that Firestore growth log was passed the storage download URL
      final capturedLog = verify(() => mockGrowthRemote.saveGrowthLog(captureAny())).captured.first as GrowthLogModel;
      expect(capturedLog.photoPath, 'https://firebasestorage.googleapis.com/growth_photo.jpg');

      // Verify that SQLite plant and growth_logs also updated with the storage download URL
      final db = await dbHelper.database;
      final plantRow = await db.query(DatabaseHelper.tableUserPlants, where: 'id = ?', whereArgs: ['plant_1']);
      expect(plantRow.first['cover_photo_path'], 'https://firebasestorage.googleapis.com/growth_photo.jpg');
    });

    test('updateGrowthLog with photo uploads to StorageRemoteDataSource and updates SQLite and Firestore', () async {
      final mockStorage = MockStorageRemoteDataSource();
      final repoWithStorage = DailyCareRepositoryImpl(
        dbHelper: dbHelper,
        growthRemoteDataSource: mockGrowthRemote,
        storageRemoteDataSource: mockStorage,
      );

      final db = await dbHelper.database;
      await db.insert(DatabaseHelper.tableGrowthLogs, {
        'id': 'log_storage_update',
        'user_plant_id': 'plant_1',
        'height_cm': 25.0,
        'photo_path': '/old/photo.jpg',
        'logged_at': DateTime.now().toIso8601String(),
        'source': 'manual',
      });

      when(() => mockStorage.uploadFile(
            filePath: any(named: 'filePath'),
            destinationPath: any(named: 'destinationPath'),
          )).thenAnswer((_) async => 'https://firebasestorage.googleapis.com/new_growth_photo.jpg');

      when(() => mockGrowthRemote.updateGrowthLog(any(), any())).thenAnswer((_) async {});

      final result = await repoWithStorage.updateGrowthLog(
        logId: 'log_storage_update',
        userPlantId: 'plant_1',
        heightCm: 32.0,
        photoPath: '/local/cache/new_snap.jpg',
        note: 'Foto baru diupload',
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockStorage.uploadFile(
            filePath: '/local/cache/new_snap.jpg',
            destinationPath: any(named: 'destinationPath'),
          )).called(1);

      final rows = await db.query(DatabaseHelper.tableGrowthLogs, where: 'id = ?', whereArgs: ['log_storage_update']);
      expect(rows.first['photo_path'], 'https://firebasestorage.googleapis.com/new_growth_photo.jpg');
    });
  });
}
