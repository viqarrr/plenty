import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/core/di/injector.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/domain/repositories/auth_repository.dart';
import 'package:plenty/features/auth/presentation/screens/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;

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
      home: RegisterScreen(authRepository: mockAuthRepository),
    );
  }

  group('RegisterScreen Password Validation Unit Tests', () {
    test('returns error when password is empty', () {
      expect(RegisterScreen.validatePassword(''), 'Kata sandi tidak boleh kosong');
      expect(RegisterScreen.validatePassword(null), 'Kata sandi tidak boleh kosong');
    });

    test('returns error when password length is less than 8', () {
      expect(RegisterScreen.validatePassword('Aa1!'), 'Kata sandi minimal 8 karakter');
      expect(RegisterScreen.validatePassword('Pass1!'), 'Kata sandi minimal 8 karakter');
    });

    test('returns error when password has no uppercase letter', () {
      expect(
        RegisterScreen.validatePassword('password123!'),
        'Kata sandi harus menyertakan huruf besar',
      );
    });

    test('returns error when password has no lowercase letter', () {
      expect(
        RegisterScreen.validatePassword('PASSWORD123!'),
        'Kata sandi harus menyertakan huruf kecil',
      );
    });

    test('returns error when password has no number', () {
      expect(
        RegisterScreen.validatePassword('Password!!!!'),
        'Kata sandi harus menyertakan angka',
      );
    });

    test('returns error when password has no symbol', () {
      expect(
        RegisterScreen.validatePassword('Password123'),
        'Kata sandi harus menyertakan simbol',
      );
    });

    test('returns all missing requirements when multiple validations fail', () {
      // Missing number and symbol
      expect(
        RegisterScreen.validatePassword('HaloDunia'),
        'Kata sandi harus menyertakan angka dan simbol',
      );

      // Missing uppercase, number, and symbol
      expect(
        RegisterScreen.validatePassword('halodunia'),
        'Kata sandi harus menyertakan huruf besar, angka, dan simbol',
      );

      // Missing length, uppercase, number, and symbol
      expect(
        RegisterScreen.validatePassword('halo'),
        'Kata sandi harus menyertakan minimal 8 karakter, huruf besar, angka, dan simbol',
      );

      // Missing length and symbol
      expect(
        RegisterScreen.validatePassword('Halo123'),
        'Kata sandi harus menyertakan minimal 8 karakter dan simbol',
      );
    });

    test('accepts valid passwords with combination of upper, lower, number, and symbol', () {
      expect(RegisterScreen.validatePassword('Password123!'), isNull);
      expect(RegisterScreen.validatePassword('Pl@nt2026'), isNull);
      expect(RegisterScreen.validatePassword('Admin#999'), isNull);
      expect(RegisterScreen.validatePassword('Green_Thumb1'), isNull);
      expect(RegisterScreen.validatePassword('Secret-Pass8'), isNull);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders initial step for full name', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Beritahu kami siapa namamu'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    });

    testWidgets('blocks progression when full name is empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Lanjut'));
      await tester.pump();

      expect(find.text('Nama tidak boleh kosong'), findsOneWidget);
      expect(find.text('Beritahu kami siapa namamu'), findsOneWidget);
    });
  });
}
