import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/domain/models/growth_log_model.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/daily_care/data/repositories/daily_care_repository_impl.dart';
import 'package:plenty/features/daily_care/presentation/widgets/monitor_tinggi_input_sheet.dart';
import 'package:plenty/features/garden/data/repositories/growth_repository_impl.dart';
import 'package:plenty/features/garden/data/repositories/plant_repository_impl.dart';
import 'package:plenty/features/garden/domain/models/plant_model.dart';
import 'package:plenty/features/garden/domain/models/time_capsule_model.dart';
import 'package:plenty/features/garden/domain/repositories/growth_repository.dart';
import 'package:plenty/features/garden/domain/repositories/plant_repository.dart';
import 'package:plenty/features/garden/presentation/screens/plant_details_screen.dart';
import 'package:plenty/features/garden/presentation/widgets/first_reward_popup.dart';
import 'package:plenty/features/garden/presentation/widgets/photo_timeline_stepper.dart';
import 'package:plenty/features/plant_catalog/presentation/widgets/time_capsule_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late IGrowthRepository growthRepo;
  late IPlantRepository plantRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();

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

    growthRepo = GrowthRepositoryImpl(dbHelper: dbHelper);
    plantRepo = PlantRepositoryImpl(dbHelper: dbHelper);
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
          MaterialApp(
            home: PlantDetailsScreen(
              plant: plant,
              growthRepository: growthRepo,
              plantRepository: plantRepo,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });

      await tester.pump();

      expect(find.text('Super Pothos'), findsOneWidget);
      expect(find.text('Usia Tanaman'), findsOneWidget);
      expect(find.text('1 Hari'), findsOneWidget);
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
            MaterialApp(
              home: PlantDetailsScreen(
                plant: plant,
                growthRepository: growthRepo,
                plantRepository: plantRepo,
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
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
          MaterialApp(
            home: PlantDetailsScreen(
              plant: plant,
              growthRepository: growthRepo,
              plantRepository: plantRepo,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
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
          MaterialApp(
            home: PlantDetailsScreen(
              plant: plant,
              growthRepository: growthRepo,
              plantRepository: plantRepo,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });

      await tester.pump();
      // Tap Delete button in AppBar
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      // Verify Delete confirmation sheet is shown
      expect(find.text('Hapus Tanaman?'), findsOneWidget);
      expect(find.text('Ya, Hapus Tanaman'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('Editing growth log updates plant height and closes sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final plant = PlantModel(
        id: 'plt_height_update',
        userId: '1',
        nickname: 'Height Test Plant',
        isIndoor: true,
        initialHeightCm: 25.0,
        level: 1,
        xp: 10,
        adoptedAt: DateTime.now(),
      );

      final dailyCareRepo = DailyCareRepositoryImpl(dbHelper: dbHelper);

      await tester.runAsync(() async {
        final db = await dbHelper.database;
        await db.insert(DatabaseHelper.tableUserPlants, plant.toMap());
        await db.insert(
          DatabaseHelper.tableGrowthLogs,
          GrowthLogModel(
            id: 'log_h1',
            userPlantId: plant.id,
            heightCm: 25.0,
            source: 'initial',
            loggedAt: DateTime.now(),
          ).toMap(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PlantDetailsScreen(
              plant: plant,
              growthRepository: growthRepo,
              plantRepository: plantRepo,
              dailyCareRepository: dailyCareRepo,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });

      await tester.pump();

      expect(find.text('25.0 cm'), findsOneWidget);

      await tester.tap(find.text('Linimasa & Foto Pertumbuhan'));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoTimelineStepper), findsOneWidget);

      final editIcon = find.descendant(
        of: find.byType(PhotoTimelineStepper),
        matching: find.byIcon(Icons.edit_outlined),
      );
      await tester.tap(editIcon);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(find.byType(MonitorTinggiInputSheet), findsOneWidget);

      final heightField = find.byType(TextField).first;
      await tester.enterText(heightField, '55.0');
      await tester.pump();

      PlantModel? updatedPlant;
      await tester.runAsync(() async {
        await tester.tap(find.text('Simpan Perubahan'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        final plantRes = await plantRepo.getPlantById('plt_height_update');
        updatedPlant = plantRes.dataOrNull;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Sheets should be closed and plant height in details screen updated
      expect(find.byType(MonitorTinggiInputSheet), findsNothing);
      expect(find.byType(PhotoTimelineStepper), findsNothing);

      expect(updatedPlant?.currentHeightCm, 55.0);
      expect(find.text('55.0 cm'), findsOneWidget);
    });

    testWidgets(
        'Creating time capsule from PlantDetailsScreen unlocks badge and shows FirstRewardPopup',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final plant = PlantModel(
        id: 'plt_tc_reward_test',
        userId: '1',
        nickname: 'Philo Capsule',
        isIndoor: true,
        initialHeightCm: 30.0,
        level: 1,
        xp: 0,
        adoptedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        final db = await dbHelper.database;
        await db.insert(DatabaseHelper.tableUserPlants, plant.toMap());
        await db.insert(
          DatabaseHelper.tableGrowthLogs,
          GrowthLogModel(
            id: 'log_tc_init',
            userPlantId: plant.id,
            heightCm: 30.0,
            source: 'initial',
            loggedAt: DateTime.now(),
          ).toMap(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlantDetailsScreen(
                plant: plant,
                growthRepository: growthRepo,
                plantRepository: plantRepo,
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Open modal, enter note, and save all inside runAsync
      expect(find.text('Buat Kapsul Waktu'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Buat Kapsul Waktu'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.enterText(
          find.byType(TextField).first,
          'Semoga tambah subur dan sehat!',
        );
        await tester.pump();
        await tester.tap(find.text('Simpan Kapsul Waktu'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify FirstRewardPopup appears for Time Capsule badge
      expect(find.byType(FirstRewardPopup), findsOneWidget);
      expect(find.text('Kapsul Waktu Terbuka! ⏳'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FirstRewardPopup),
          matching: find.textContaining('Philo Capsule'),
        ),
        findsOneWidget,
      );

      // Dismiss popup
      await tester.tap(find.text('Klaim & Lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.byType(FirstRewardPopup), findsNothing);
    });
  });
}
