import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/data/datasources/database_helper.dart';
import 'package:plenty/data/models/growth_log_model.dart';
import 'package:plenty/data/models/plant_model.dart';
import 'package:plenty/data/models/time_capsule_model.dart';
import 'package:plenty/data/repositories/growth_repository.dart';
import 'package:plenty/data/repositories/plant_repository.dart';
import 'package:plenty/presentation/plant_details/plant_details_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late GrowthRepository growthRepo;
  late PlantRepository plantRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final uniqueName = 'pdetails_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(uniqueName);
    await dbHelper.deleteDb();

    // Seed default user
    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      {
        'id': 1,
        'email': 'user@plenty.app',
        'display_name': 'Test User',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    growthRepo = GrowthRepository(dbHelper: dbHelper);
    plantRepo = PlantRepository(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('PlantDetailsScreen Rendering Tests', () {
    testWidgets('Renders plant nickname, Level/XP, and None Time Capsule CTA', (
      tester,
    ) async {
      final plant = PlantModel(
        id: 'plt_monstera_1',
        userId: '1',
        nickname: 'Super Pothos',
        isIndoor: true,
        initialHeightCm: 25.0,
        level: 2,
        xp: 130,
        adoptedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        final db = await dbHelper.database;
        await db.insert(DatabaseHelper.tableUserPlants, plant.toMap());
        await db.insert(
          DatabaseHelper.tableGrowthLogs,
          GrowthLogModel(
            id: 'log_1',
            userPlantId: plant.id,
            heightCm: 25.0,
            source: 'initial',
            loggedAt: DateTime.now().subtract(const Duration(days: 5)),
          ).toMap(),
        );
        await db.insert(
          DatabaseHelper.tableGrowthLogs,
          GrowthLogModel(
            id: 'log_2',
            userPlantId: plant.id,
            heightCm: 28.5,
            source: 'daily_task',
            loggedAt: DateTime.now(),
          ).toMap(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: PlantDetailsScreen(
                plant: plant,
                growthRepository: growthRepo,
                plantRepository: plantRepo,
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pump();

      expect(find.text('Super Pothos'), findsOneWidget);
      expect(find.text('Level 2'), findsWidgets);
      expect(find.text('30 / 100 XP'), findsOneWidget);
      expect(find.text('Grafik Pertumbuhan Tinggi'), findsOneWidget);
      expect(find.text('Kapsul Waktu (Time Capsule)'), findsOneWidget);
      expect(find.text('Buat Kapsul Waktu'), findsOneWidget);
      expect(find.text('Hapus Tanaman dari Koleksi'), findsOneWidget);
    });

    testWidgets(
      'Renders Locked Time Capsule countdown when capsule is locked',
      (tester) async {
        final plant = PlantModel(
          id: 'plant_test_2',
          userId: '1',
          nickname: 'Locked Calathea',
          isIndoor: true,
          initialHeightCm: 20.0,
          level: 1,
          xp: 40,
          adoptedAt: DateTime.now(),
        );

        await tester.runAsync(() async {
          final db = await dbHelper.database;
          await db.insert(DatabaseHelper.tableUserPlants, plant.toMap());
          await db.insert(
            DatabaseHelper.tableTimeCapsules,
            TimeCapsuleModel(
              id: 'capsule_test_locked',
              userPlantId: plant.id,
              photoPath: 'assets/images/capsule.png',
              note: 'Pesan rahasia',
              createdAt: DateTime.now(),
              unlockAt: DateTime.now().add(const Duration(days: 45)),
              isUnlocked: false,
            ).toMap(),
          );

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: PlantDetailsScreen(
                  plant: plant,
                  growthRepository: growthRepo,
                  plantRepository: plantRepo,
                ),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });

        await tester.pump();

        expect(find.text('Locked Calathea'), findsOneWidget);
        expect(find.text('Time Capsule Terkunci ⏳'), findsOneWidget);
      },
    );

    testWidgets('Opens Edit Plant Sheet when edit icon is tapped', (
      tester,
    ) async {
      final plant = PlantModel(
        id: 'plt_edit_test',
        userId: '1',
        nickname: 'Monstera To Edit',
        isIndoor: true,
        initialHeightCm: 25.0,
        level: 1,
        xp: 10,
        adoptedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        final db = await dbHelper.database;
        await db.insert(DatabaseHelper.tableUserPlants, plant.toMap());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: PlantDetailsScreen(
                plant: plant,
                growthRepository: growthRepo,
                plantRepository: plantRepo,
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pump();

      // Tap Edit button in AppBar
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Verify Edit sheet is shown
      expect(find.text('Edit Tanaman'), findsOneWidget);
      expect(find.text('Nama Panggilan Tanaman *'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });

    testWidgets('Opens Delete Confirmation Sheet when delete icon is tapped', (
      tester,
    ) async {
      final plant = PlantModel(
        id: 'plt_delete_test',
        userId: '1',
        nickname: 'Monstera To Delete',
        isIndoor: true,
        initialHeightCm: 25.0,
        level: 1,
        xp: 10,
        adoptedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        final db = await dbHelper.database;
        await db.insert(DatabaseHelper.tableUserPlants, plant.toMap());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: PlantDetailsScreen(
                plant: plant,
                growthRepository: growthRepo,
                plantRepository: plantRepo,
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pump();

      // Tap Delete button in AppBar
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      // Verify Delete confirmation sheet is shown
      expect(find.text('Hapus Monstera To Delete?'), findsOneWidget);
      expect(find.text('Ya, Hapus Tanaman'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });
  });
}
