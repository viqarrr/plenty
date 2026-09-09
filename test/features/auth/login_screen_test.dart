import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/auth/domain/repositories/auth_repository.dart';
import 'package:plenty/features/auth/presentation/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;

  const testUser = UserModel(
    id: 'uid_test_123',
    email: 'test@plenty.app',
    displayName: 'Test User',
    username: 'testuser',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();
    mockAuthRepository = MockAuthRepository();
    Injector.authRepository = mockAuthRepository;

    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAuthRepository.currentUser).thenReturn(null);
  });

  tearDown(() {
    Injector.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: LoginScreen(authRepository: mockAuthRepository),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders email and password fields and submit button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Masuk ke akun anda'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Masuk'));
      await tester.pump();

      expect(find.text('Email atau username wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('calls login with email and password when form is valid', (tester) async {
      when(
        () => mockAuthRepository.login(
          email: 'test@plenty.app',
          password: 'password123',
        ),
      ).thenAnswer((_) async => const Success(testUser));

      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'test@plenty.app');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pump();

      await tester.tap(find.text('Masuk'));
      await tester.pump();

      verify(
        () => mockAuthRepository.login(
          email: 'test@plenty.app',
          password: 'password123',
        ),
      ).called(1);
    });

    testWidgets('shows snackbar error when login fails', (tester) async {
      when(
        () => mockAuthRepository.login(
          email: 'test@plenty.app',
          password: 'wrongpassword',
        ),
      ).thenAnswer(
        (_) async => const Error(AuthFailure('Email atau kata sandi tidak sesuai.')),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'test@plenty.app');
      await tester.enterText(textFields.at(1), 'wrongpassword');
      await tester.pump();

      await tester.tap(find.text('Masuk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Email atau kata sandi tidak sesuai.'), findsOneWidget);
    });
  });
}
