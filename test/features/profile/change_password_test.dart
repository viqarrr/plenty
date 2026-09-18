import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/profile/data/repositories/user_repository_impl.dart';
import 'package:plenty/features/profile/domain/repositories/user_repository.dart';
import 'package:plenty/features/profile/presentation/widgets/change_password_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late IUserRepository userRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();

    dbHelper = DatabaseHelper.forTesting(
      'change_password_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await dbHelper.deleteDb();
    final db = await dbHelper.database;
    await db.insert(DatabaseHelper.tableUsers, {
      'id': 1,
      'email': 'default@plenty.app',
      'username': 'user_default',
      'password': '',
      'display_name': 'Pecinta Tanaman',
      'streak_count': 0,
      'longest_streak': 0,
      'total_xp': 0,
      'level': 1,
      'unlocked_badges_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    userRepository = UserRepositoryImpl(dbHelper: dbHelper);
    Injector.databaseHelper = dbHelper;
    Injector.userRepository = userRepository;
  });

  tearDown(() async {
    Injector.reset();
    await dbHelper.close();
  });

  group('UserRepository.updatePassword Unit Tests', () {
    test('updatePassword updates password in database for active user', () async {
      // First update from default empty password to 'Password123'
      final result1 = await userRepository.updatePassword(
        userId: '1',
        currentPassword: '',
        newPassword: 'Password123',
      );
      expect(result1.isSuccess, isTrue);

      // Updating with correct current password succeeds
      final result2 = await userRepository.updatePassword(
        userId: '1',
        currentPassword: 'Password123',
        newPassword: 'NewSecretPassword456',
      );
      expect(result2.isSuccess, isTrue);

      // Updating with wrong current password fails
      final result3 = await userRepository.updatePassword(
        userId: '1',
        currentPassword: 'WrongPassword',
        newPassword: 'AnotherPassword789',
      );
      expect(result3.isError, isTrue);
    });
  });

  group('ChangePasswordSheet Widget Tests', () {
    testWidgets('renders all 3 password fields and submit button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangePasswordSheet(
              userRepository: userRepository,
              userId: '1',
            ),
          ),
        ),
      );

      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
      expect(find.text('Kata Sandi Saat Ini'), findsOneWidget);
      expect(find.text('Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Simpan Kata Sandi Baru'), findsOneWidget);
    });

    testWidgets('validates required fields and confirmation match', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangePasswordSheet(
              userRepository: userRepository,
              userId: '1',
            ),
          ),
        ),
      );

      // Tap submit without entering anything
      await tester.tap(find.text('Simpan Kata Sandi Baru'));
      await tester.pump();

      expect(find.text('Kata sandi saat ini wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi baru wajib diisi'), findsOneWidget);
      expect(find.text('Konfirmasi kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('successfully submits and updates password via ChangePasswordSheet', (tester) async {
      bool? sheetResult;

      await tester.runAsync(() async {
        await userRepository.updatePassword(
          userId: '1',
          currentPassword: '',
          newPassword: 'OldPassword123',
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  sheetResult = await ChangePasswordSheet.show(
                    context,
                    userRepository: userRepository,
                    userId: '1',
                  );
                },
                child: const Text('Open Change Password'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Change Password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ChangePasswordSheet), findsOneWidget);

      final textFields = find.byType(TextField);
      // Fill current password
      await tester.enterText(textFields.at(0), 'OldPassword123');
      // Fill new password
      await tester.enterText(textFields.at(1), 'SecretPass123');
      // Fill confirm password
      await tester.enterText(textFields.at(2), 'SecretPass123');
      await tester.pump();

      await tester.tap(find.text('Simpan Kata Sandi Baru'));
      await tester.pump();

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(sheetResult, isTrue);
    });
  });
}
