import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:plenty/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:plenty/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late AuthRepositoryImpl authRepository;

  const testUser = UserModel(
    id: 'uid_test_123',
    email: 'test@plenty.app',
    displayName: 'Test User',
    username: 'testuser',
  );

  setUpAll(() {
    registerFallbackValue(testUser);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();

    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();

    authRepository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('AuthRepositoryImpl Login Tests', () {
    test('login succeeds and persists session to PreferenceHandler and local DB', () async {
      when(
        () => mockRemoteDataSource.signIn(
          email: 'test@plenty.app',
          password: 'password123',
        ),
      ).thenAnswer((_) async => testUser);

      when(() => mockLocalDataSource.registerUser(any()))
          .thenAnswer((_) async => true);

      final result = await authRepository.login(
        email: 'test@plenty.app',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, testUser);
      expect(PreferenceHandler.isLogin, isTrue);

      final cachedUser = await PreferenceHandler.getUser();
      expect(cachedUser?.id, testUser.id);
      expect(cachedUser?.email, testUser.email);

      verify(
        () => mockRemoteDataSource.signIn(
          email: 'test@plenty.app',
          password: 'password123',
        ),
      ).called(1);
    });

    test('login maps FirebaseAuthException to domain AuthFailure', () async {
      when(
        () => mockRemoteDataSource.signIn(
          email: 'wrong@plenty.app',
          password: 'wrongpassword',
        ),
      ).thenThrow(
        FirebaseAuthException(code: 'user-not-found', message: 'Not found'),
      );

      final result = await authRepository.login(
        email: 'wrong@plenty.app',
        password: 'wrongpassword',
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
      expect(
        result.failureOrNull?.message,
        'Email atau kata sandi tidak sesuai.',
      );
      expect(PreferenceHandler.isLogin, isFalse);
    });
  });

  group('AuthRepositoryImpl Register Tests', () {
    test('register successfully signs up user and updates session', () async {
      when(
        () => mockRemoteDataSource.signUp(
          email: 'new@plenty.app',
          password: 'password123',
          displayName: 'New User',
          username: 'newuser',
        ),
      ).thenAnswer(
        (_) async => const UserModel(
          id: 'uid_new_456',
          email: 'new@plenty.app',
          displayName: 'New User',
          username: 'newuser',
        ),
      );

      when(() => mockLocalDataSource.registerUser(any()))
          .thenAnswer((_) async => true);

      final result = await authRepository.register(
        const UserModel(
          email: 'new@plenty.app',
          password: 'password123',
          displayName: 'New User',
          username: 'newuser',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isTrue);
      expect(PreferenceHandler.isLogin, isTrue);
    });

    test('register maps email-already-in-use to ValidationFailure', () async {
      when(
        () => mockRemoteDataSource.signUp(
          email: 'exists@plenty.app',
          password: 'password123',
          displayName: 'Existing User',
          username: 'existing',
        ),
      ).thenThrow(
        FirebaseAuthException(code: 'email-already-in-use'),
      );

      final result = await authRepository.register(
        const UserModel(
          email: 'exists@plenty.app',
          password: 'password123',
          displayName: 'Existing User',
          username: 'existing',
        ),
      );

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull?.message,
        'Email sudah terdaftar. Silakan masuk.',
      );
    });
  });

  group('AuthRepositoryImpl Logout Tests', () {
    test('logout signs out from remote source and clears local session', () async {
      when(() => mockRemoteDataSource.signOut()).thenAnswer((_) async {});
      await PreferenceHandler.setLoginSession(testUser);
      expect(PreferenceHandler.isLogin, isTrue);

      final result = await authRepository.logout();

      expect(result.isSuccess, isTrue);
      expect(PreferenceHandler.isLogin, isFalse);
      final user = await PreferenceHandler.getUser();
      expect(user, isNull);
      verify(() => mockRemoteDataSource.signOut()).called(1);
    });
  });
}
