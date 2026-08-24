import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/domain/models/badge_item.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/profile/presentation/screens/all_badges_screen.dart';
import 'package:plenty/features/profile/presentation/screens/badge_detail_screen.dart';
import 'package:plenty/features/profile/presentation/screens/profile_tab.dart';
import 'package:plenty/features/profile/presentation/widgets/badge_highlight_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();
  });

  final sampleBadges = [
    const BadgeItem(
      id: 'first_plant',
      title: 'Adopsi Pertama',
      desc: 'Mengadopsi tanaman pertama untuk memulai perjalanan berkebunmu.',
      iconName: 'eco',
      isUnlocked: true,
      unlockedDate: '23 Ags 2026',
      level: 1,
      progress: 1,
      total: 1,
      bgColorHex: '#EBF7F1',
      accentColorHex: '#2D6A4F',
    ),
    const BadgeItem(
      id: 'water_streak',
      title: 'Penyiram Setia',
      desc: 'Menyiram tanaman tepat waktu selama 7 kali berturut-turut.',
      iconName: 'water_drop',
      isUnlocked: true,
      unlockedDate: '20 Ags 2026',
      level: 1,
      progress: 7,
      total: 7,
      bgColorHex: '#FBF3DB',
      accentColorHex: '#956400',
    ),
    const BadgeItem(
      id: 'plant_collector',
      title: 'Kolektor Rimbun',
      desc: 'Memiliki minimal 5 tanaman aktif di kebun virtualmu.',
      iconName: 'park',
      isUnlocked: false,
      level: 1,
      progress: 2,
      total: 5,
      bgColorHex: '#EBF7F1',
      accentColorHex: '#2D6A4F',
    ),
  ];

  group('BadgeHighlightSection Widget Tests', () {
    testWidgets('Renders PENCAPAIAN header and max 4 badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BadgeHighlightSection(badges: sampleBadges)),
        ),
      );

      expect(find.text('PENCAPAIAN'), findsOneWidget);
      expect(find.text('Lihat Semua'), findsOneWidget);
      expect(find.text('Adopsi Pertama'), findsOneWidget);
      expect(find.text('Penyiram Setia'), findsOneWidget);
      expect(find.text('Kolektor Rimbun'), findsOneWidget);
    });

    testWidgets('Tapping Lihat Semua navigates to AllBadgesScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BadgeHighlightSection(badges: sampleBadges)),
        ),
      );

      await tester.tap(find.text('Lihat Semua'));
      await tester.pumpAndSettle();

      expect(find.byType(AllBadgesScreen), findsOneWidget);
      expect(find.text('Pencapaian'), findsOneWidget);
      expect(find.text('SEMUA PENCAPAIAN'), findsOneWidget);
      expect(find.text('2/3 Terbuka'), findsOneWidget);
    });
  });

  group('AllBadgesScreen Widget Tests', () {
    testWidgets('Renders 3-column grid and shows full screen detail on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: AllBadgesScreen(badges: sampleBadges)),
      );

      expect(find.text('Pencapaian'), findsOneWidget);
      expect(find.text('SEMUA PENCAPAIAN'), findsOneWidget);
      expect(find.text('2/3 Terbuka'), findsOneWidget);

      // Tap on the unlocked badge
      await tester.tap(find.text('Adopsi Pertama'));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
      expect(find.text('23 Ags 2026'), findsOneWidget);
      expect(find.text('Bagikan ke Komunitas'), findsOneWidget);

      // Close screen via back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsNothing);

      // Tap on locked badge
      await tester.tap(find.text('Kolektor Rimbun'));
      await tester.pumpAndSettle();

      expect(find.byType(BadgeDetailScreen), findsOneWidget);
      expect(find.text('Progres Pencapaian'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BadgeDetailScreen),
          matching: find.text('2 / 5 (40%)'),
        ),
        findsOneWidget,
      );
      expect(find.text('Terkunci'), findsOneWidget);
    });
  });

  group('BadgeDetailScreen Widget Tests', () {
    testWidgets(
      'Unlocked state displays illuminated elements and share button',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: BadgeDetailScreen(badge: sampleBadges[0])),
        );

        expect(find.text('Adopsi Pertama'), findsOneWidget);
        expect(find.text('23 Ags 2026'), findsOneWidget);
        expect(find.text('Bagikan ke Komunitas'), findsOneWidget);
      },
    );

    testWidgets('Time Capsule badge displays blue theme gradient and accents', (
      tester,
    ) async {
      const timeCapsuleBadge = BadgeItem(
        id: 'time_capsule',
        title: 'Kapsul Waktu',
        desc: 'Membuat pesan kapsul waktu pertama saat menanam.',
        iconName: 'hourglass',
        isUnlocked: true,
        unlockedDate: '24 Ags 2026',
        level: 1,
        progress: 1,
        total: 1,
        bgColorHex: '#E3F0FF',
        accentColorHex: '#1F6C9F',
      );

      await tester.pumpWidget(
        const MaterialApp(home: BadgeDetailScreen(badge: timeCapsuleBadge)),
      );

      expect(find.text('Kapsul Waktu'), findsOneWidget);
      expect(find.text('24 Ags 2026'), findsOneWidget);
      expect(find.text('Bagikan ke Komunitas'), findsOneWidget);

      // Verify the background Container has a gradient derived from blue accentColor
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.gradient, isA<LinearGradient>());
      final gradient = decoration!.gradient as LinearGradient;
      expect(gradient.colors.length, 3);
    });

    testWidgets('Locked state displays criteria narrative and progress bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: BadgeDetailScreen(badge: sampleBadges[2])),
      );

      expect(find.text('Kolektor Rimbun'), findsOneWidget);
      expect(find.text('Progres Pencapaian'), findsOneWidget);
      expect(find.text('2 / 5 (40%)'), findsOneWidget);
      expect(find.text('Terkunci'), findsOneWidget);
    });
  });

  group('ProfileTab Integration Tests', () {
    testWidgets(
      'Renders CurrentProgressCard, BadgeHighlightSection, and ActivitySummaryGrid in sequence',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProfileTab(
                profileName: 'Sarah Gardener',
                username: 'sarah_green',
                email: '@sarahgreen.gmail.com',
                streakCount: 5,
                totalPlants: 3,
                totalXp: 450,
                userLevel: 2,
                badgeCount: 2,
                badges: sampleBadges,
                onLogout: () {},
              ),
            ),
          ),
        );

        // Verify Header
        expect(find.text('Sarah Gardener'), findsOneWidget);
        expect(find.text('@sarah_green'), findsOneWidget);

        // Verify CurrentProgressCard
        expect(find.text('Level 2'), findsOneWidget);

        // Verify BadgeHighlightSection
        expect(find.text('PENCAPAIAN'), findsOneWidget);
        expect(find.text('Lihat Semua'), findsOneWidget);
        expect(find.text('Adopsi Pertama'), findsOneWidget);

        // Verify ActivitySummaryGrid
        expect(find.text('RINGKASAN AKTIVITAS'), findsOneWidget);
        expect(find.text('Total Poin XP'), findsOneWidget);
        expect(find.text('450'), findsOneWidget);
        expect(find.text('3 Tanaman'), findsOneWidget);
      },
    );
  });
}
