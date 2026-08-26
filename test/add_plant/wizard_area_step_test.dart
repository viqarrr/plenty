import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/features/garden/data/repositories/site_repository_impl.dart';
import 'package:plenty/features/garden/domain/repositories/site_repository.dart';
import 'package:plenty/features/garden/presentation/widgets/add_plant/steps/wizard_area_step.dart';
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
      expect(find.text('Ruang Kerja'), findsOneWidget);

      // Outdoor locations should NOT be displayed
      expect(find.text('Lokasi Outdoor'), findsNothing);
      expect(find.text('Balkon'), findsNothing);
      expect(find.text('Taman'), findsNothing);

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
      expect(find.text('Taman'), findsOneWidget);
      expect(find.text('Patio'), findsOneWidget);
      expect(find.text('Teras'), findsOneWidget);

      // Indoor locations should NOT be displayed
      expect(find.text('Lokasi Indoor'), findsNothing);
      expect(find.text('Ruang Tamu'), findsNothing);
      expect(find.text('Kamar Tidur'), findsNothing);

      // Tap on 'Taman'
      await tester.tap(find.text('Taman'));
      await tester.pumpAndSettle();

      expect(selectedRoom, 'Taman');
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
  });
}
