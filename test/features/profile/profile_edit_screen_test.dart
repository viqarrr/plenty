import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plenty/core/database/database_helper.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/profile/data/repositories/user_repository_impl.dart';
import 'package:plenty/features/profile/domain/repositories/user_repository.dart';
import 'package:plenty/features/profile/presentation/screens/profile_edit_screen.dart';
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
      'profile_edit_test_.db',
    );
    await dbHelper.deleteDb();
    userRepository = UserRepositoryImpl(dbHelper: dbHelper);
    Injector.databaseHelper = dbHelper;
    Injector.userRepository = userRepository;
  });

  tearDown(() async {
    Injector.reset();
    await dbHelper.close();
  });

  group('ProfileEditScreen Widget Tests', () {
    testWidgets('Renders initial email correctly in email settings tile', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileEditScreen(
            userRepo: userRepository,
            initialDisplayName: 'Test User',
            initialUsername: 'test_user',
            initialEmail: 'test@example.com',
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alamat email'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Resolves email from PreferenceHandler when default email passed', (
      tester,
    ) async {
      await PreferenceHandler.setUser(
        const UserModel(
          id: '1',
          displayName: 'Saved User',
          username: 'saved_user',
          email: 'saved@plenty.app',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileEditScreen(
            userRepo: userRepository,
            initialDisplayName: 'Saved User',
            initialUsername: 'saved_user',
            initialEmail: 'alex@gardner.com',
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('saved@plenty.app'), findsOneWidget);
    });

    testWidgets('Tapping email tile shows read-only SnackBar notification', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileEditScreen(
            userRepo: userRepository,
            initialDisplayName: 'Test User',
            initialUsername: 'test_user',
            initialEmail: 'user@plenty.app',
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('user@plenty.app'));
      await tester.pump();

      expect(find.text('Alamat email tidak dapat diubah.'), findsOneWidget);
    });
  });
}
