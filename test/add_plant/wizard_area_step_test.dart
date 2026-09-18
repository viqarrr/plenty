import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/garden/data/repositories/site_repository_impl.dart';
import 'package:plenty/features/garden/domain/repositories/site_repository.dart';
import 'package:plenty/features/garden/presentation/widgets/add_plant/steps/wizard_area_step.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late ISiteRepository siteRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();
    dbHelper = DatabaseHelper.forTesting(
      'wizard_area_step_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await dbHelper.deleteDb();
    siteRepo = SiteRepositoryImpl(dbHelper: dbHelper);
    Injector.databaseHelper = dbHelper;
    Injector.siteRepository = siteRepo;
  });

  tearDown(() async {
    Injector.reset();
    await dbHelper.close();
  });

  group('WizardAreaStep Widget Tests', () {
    testWidgets('renders Indoor locations when isIndoor is true', (
      tester,
    ) async {
      String selectedRoom = 'Ruang Tamu';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return WizardAreaStep(
                  selectedRoom: selectedRoom,
                  isIndoor: true,
                  siteRepo: siteRepo,
                  onRoomSelected: (room) {
                    setState(() => selectedRoom = room);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lokasi Ruangan'), findsOneWidget);
      expect(find.text('Lokasi Indoor'), findsOneWidget);
      expect(find.text('Ruang Tamu'), findsOneWidget);
      expect(find.text('Kamar Tidur'), findsOneWidget);
      expect(find.text('Dapur'), findsOneWidget);

      // Outdoor locations should NOT be displayed
      expect(find.text('Lokasi Outdoor'), findsNothing);
      expect(find.text('Balkon'), findsNothing);
      expect(find.text('Teras'), findsNothing);

      // Tap on 'Kamar Tidur'
      await tester.tap(find.text('Kamar Tidur'));
      await tester.pumpAndSettle();

      expect(selectedRoom, 'Kamar Tidur');
    });

    testWidgets('renders Outdoor locations when isIndoor is false', (
      tester,
    ) async {
      String selectedRoom = 'Balkon';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return WizardAreaStep(
                  selectedRoom: selectedRoom,
                  isIndoor: false,
                  siteRepo: siteRepo,
                  onRoomSelected: (room) {
                    setState(() => selectedRoom = room);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lokasi Area Outdoor'), findsOneWidget);
      expect(find.text('Lokasi Outdoor'), findsOneWidget);
      expect(find.text('Balkon'), findsOneWidget);
      expect(find.text('Teras'), findsOneWidget);

      // Indoor locations should NOT be displayed
      expect(find.text('Lokasi Indoor'), findsNothing);
      expect(find.text('Ruang Tamu'), findsNothing);
      expect(find.text('Kamar Tidur'), findsNothing);

      // Tap on 'Teras'
      await tester.tap(find.text('Teras'));
      await tester.pumpAndSettle();

      expect(selectedRoom, 'Teras');
    });

    testWidgets('switches shown locations when isIndoor toggles', (
      tester,
    ) async {
      bool isIndoor = true;
      String selectedRoom = 'Ruang Tamu';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      onPressed: () {
                        setState(() {
                          isIndoor = !isIndoor;
                        });
                      },
                    ),
                  ],
                ),
                body: WizardAreaStep(
                  selectedRoom: selectedRoom,
                  isIndoor: isIndoor,
                  siteRepo: siteRepo,
                  onRoomSelected: (room) {
                    setState(() => selectedRoom = room);
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lokasi Indoor'), findsOneWidget);
      expect(find.text('Ruang Tamu'), findsOneWidget);

      // Toggle to Outdoor
      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lokasi Outdoor'), findsOneWidget);
      expect(find.text('Balkon'), findsOneWidget);
      expect(find.text('Ruang Tamu'), findsNothing);
    });

    testWidgets('adds custom site, renders in grid, and retains site on step re-render', (tester) async {
      String selectedRoom = 'Ruang Tamu';
      int currentStep = 2; // Step 2 is Area Step

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          currentStep = currentStep == 2 ? 1 : 2;
                        });
                      },
                      child: Text('Toggle Step: $currentStep'),
                    ),
                  ],
                ),
                body: currentStep == 2
                    ? WizardAreaStep(
                        selectedRoom: selectedRoom,
                        isIndoor: true,
                        siteRepo: siteRepo,
                        onRoomSelected: (room) {
                          debugPrint('TEST onRoomSelected: $room (was $selectedRoom)');
                          setState(() => selectedRoom = room);
                        },
                      )
                    : const Center(child: Text('Step 1 (Environment)')),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap 'Custom' button to open sheet
      expect(find.text('Custom'), findsOneWidget);
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      // Verify custom site modal sheet opened
      expect(find.text('Beri nama dan tentukan ikon untuk lokasi baru Anda.'), findsOneWidget);
      expect(find.text('Nama Lokasi'), findsOneWidget);

      // Enter custom site name
      await tester.enterText(find.byType(TextField).last, 'Kamar Mandi');
      await tester.pump();

      // Tap Simpan Lokasi
      await tester.ensureVisible(find.text('Simpan Lokasi'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Simpan Lokasi'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Verify custom site is now displayed and selected
      expect(find.text('Kamar Mandi'), findsOneWidget);
      expect(selectedRoom, 'Kamar Mandi');

      // Now simulate navigating back to previous step
      await tester.tap(find.text('Toggle Step: 2'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 (Environment)'), findsOneWidget);

      // Now navigate forward back to Area Step
      await tester.tap(find.text('Toggle Step: 1'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Verify custom site 'Kamar Mandi' is STILL present and NOT lost
      expect(find.text('Kamar Mandi'), findsOneWidget);
      expect(selectedRoom, 'Kamar Mandi');
    });
  });
}
