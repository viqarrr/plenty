import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/profile/data/repositories/user_repository.dart';
import 'package:plenty/features/profile/presentation/controllers/onboarding_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late UserRepository userRepo;
  late OnboardingController controller;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();

    final uniqueName =
        'onboarding_test_${DateTime.now().microsecondsSinceEpoch}.db';
    dbHelper = DatabaseHelper.forTesting(uniqueName);
    await dbHelper.deleteDb();

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

    userRepo = UserRepository(dbHelper: dbHelper);
    controller = OnboardingController(
      userRepo: userRepo,
      userId: '1',
    );
  });

  tearDown(() async {
    await dbHelper.close();
    await dbHelper.deleteDb();
  });

  group('OnboardingController 3-Step State Machine Tests', () {
    test('Initial state starts at step 0 with defaults', () {
      expect(controller.state.currentStep, 0);
      expect(controller.state.experienceLevel, 'beginner');
      expect(controller.state.dailyTimeMinutes, 15.0);
      expect(controller.state.hasPets, false);
      expect(controller.state.hasKids, false);
      expect(controller.state.isCompleted, false);
    });

    test(
      'Transitions from Step 0 -> Step 1 -> Step 2 -> Step 3 (CTA) and persists intermediate preferences',
      () async {
        // Step 1: Set Experience Level
        await controller.setExperienceLevel('intermediate');
        expect(controller.state.experienceLevel, 'intermediate');
        expect(controller.state.currentStep, 1);

        // Step 2: Set Daily Time Minutes
        await controller.setDailyTimeMinutes(30.0);
        expect(controller.state.dailyTimeMinutes, 30.0);
        expect(controller.state.currentStep, 2);

        // Step 3: Set Pets & Kids Safety -> Lands on Step 3
        await controller.setEnvironmentSafety(hasPets: true, hasKids: false);
        expect(controller.state.hasPets, true);
        expect(controller.state.hasKids, false);
        expect(controller.state.currentStep, 3);

        // Check SQLite persistence
        final savedPrefs = await userRepo.getUserPreferences('1');
        expect(savedPrefs, isNotNull);
        expect(savedPrefs!.experienceLevel, 'intermediate');
        expect(savedPrefs.dailyTimeMinutes, 30.0);
        expect(savedPrefs.hasPets, true);
        expect(savedPrefs.hasKids, false);
        expect(savedPrefs.hasCompletedOnboarding, false);
      },
    );

    test(
      'completeOnboarding sets hasCompletedOnboarding to true in DB and PreferenceHandler',
      () async {
        await controller.setExperienceLevel('advanced');
        await controller.setDailyTimeMinutes(20.0);
        await controller.setEnvironmentSafety(hasPets: true, hasKids: true);
        await controller.completeOnboarding();

        expect(controller.state.isCompleted, true);

        final savedPrefs = await userRepo.getUserPreferences('1');
        expect(savedPrefs, isNotNull);
        expect(savedPrefs!.hasCompletedOnboarding, true);
        expect(savedPrefs.hasPets, true);
        expect(savedPrefs.hasKids, true);

        final isOnboard = PreferenceHandler.isOnboard;
        expect(isOnboard, true);
      },
    );
  });
}
