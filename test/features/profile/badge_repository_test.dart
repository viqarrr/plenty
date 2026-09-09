import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/features/profile/data/repositories/badge_repository_impl.dart';
import 'package:plenty/features/profile/domain/repositories/badge_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late IBadgeRepository badgeRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forTesting(
      'profile_badge_repo_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await dbHelper.deleteDb();
    badgeRepository = BadgeRepositoryImpl(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('Profile BadgeRepository', () {
    test('getBadges returns all 4 seeded master badges starting with 0 progress for new user', () async {
      final badgesRes = await badgeRepository.getBadges(userId: 1);
      final badges = badgesRes.dataOrNull ?? [];

      expect(badges.length, equals(4));

      final firstPlant = badges.firstWhere((b) => b.id == 'first_plant');
      expect(firstPlant.title, 'Adopsi Pertama');
      expect(firstPlant.isUnlocked, isFalse);
      expect(firstPlant.progress, 0);
      expect(firstPlant.total, 1);
      expect(firstPlant.unlockedDate, isNull);

      final waterStreak = badges.firstWhere((b) => b.id == 'water_streak');
      expect(waterStreak.title, 'Penyiram Setia');
      expect(waterStreak.isUnlocked, isFalse);
      expect(waterStreak.progress, 0);
      expect(waterStreak.total, 7);

      final timeCapsule = badges.firstWhere((b) => b.id == 'time_capsule');
      expect(timeCapsule.title, 'Kapsul Waktu');
      expect(timeCapsule.isUnlocked, isFalse);
      expect(timeCapsule.progress, 0);

      final plantCollector = badges.firstWhere((b) => b.id == 'plant_collector');
      expect(plantCollector.isUnlocked, isFalse);
      expect(plantCollector.progress, 0);
      expect(plantCollector.total, 5);
    });

    test('getUnlockedBadges returns empty list initially', () async {
      final unlockedBadgesRes = await badgeRepository.getUnlockedBadges(userId: 1);
      final unlockedBadges = unlockedBadgesRes.dataOrNull ?? [];
      expect(unlockedBadges.isEmpty, isTrue);
    });

    test('getUnlockedBadgeCount returns 0 initially', () async {
      final countRes = await badgeRepository.getUnlockedBadgeCount(userId: 1);
      final count = countRes.dataOrNull ?? 0;
      expect(count, equals(0));
    });

    test('getBadgeById retrieves specific badge item', () async {
      final badgeRes = await badgeRepository.getBadgeById('plant_collector', userId: 1);
      final badge = badgeRes.dataOrNull;

      expect(badge, isNotNull);
      expect(badge?.title, 'Kolektor Rimbun');
      expect(badge?.isUnlocked, isFalse);
      expect(badge?.progress, 0);
      expect(badge?.total, 5);
    });
  });
}
