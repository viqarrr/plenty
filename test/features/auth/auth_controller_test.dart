import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/auth/domain/repositories/auth_repository.dart';
import 'package:plenty/features/auth/presentation/controllers/auth_controller.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late StreamController<UserModel?> authStateController;

  const testUser = UserModel(
    id: 'uid_test_123',
    email: 'test@plenty.app',
    displayName: 'Test User',
    username: 'testuser',
  );

  setUpAll(() {
    registerFallbackValue(testUser);
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authStateController = StreamController<UserModel?>.broadcast();

    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => authStateController.stream);
    when(() => mockAuthRepository.currentUser).thenReturn(null);
  });

  tearDown(() {
    authStateController.close();
  });

  group('AuthController Tests', () {
    test('initial state has null user and not loading', () {
      final controller = AuthController(authRepo: mockAuthRepository);
      expect(controller.state.user, isNull);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
    });

    test('login succeeds and updates state with user', () async {
      when(
        () => mockAuthRepository.login(
          email: 'test@plenty.app',
          password: 'password123',
        ),
      ).thenAnswer((_) async => const Success(testUser));

      final controller = AuthController(authRepo: mockAuthRepository);

      final success = await controller.login('test@plenty.app', 'password123');

      expect(success, isTrue);
      expect(controller.state.user, testUser);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
    });

    test('login fails and updates state with errorMessage', () async {
      when(
        () => mockAuthRepository.login(
          email: 'wrong@plenty.app',
          password: 'wrongpassword',
        ),
      ).thenAnswer(
        (_) async => const Error(AuthFailure('Email atau kata sandi tidak sesuai.')),
      );

      final controller = AuthController(authRepo: mockAuthRepository);

      final success = await controller.login('wrong@plenty.app', 'wrongpassword');

      expect(success, isFalse);
      expect(controller.state.user, isNull);
      expect(controller.state.isLoading, isFalse);
      expect(
        controller.state.errorMessage,
        'Email atau kata sandi tidak sesuai.',
      );
    });

    test('register succeeds and updates state', () async {
      when(() => mockAuthRepository.register(any()))
          .thenAnswer((_) async => const Success(true));

      final controller = AuthController(authRepo: mockAuthRepository);

      final success = await controller.register(
        'new@plenty.app',
        'password123',
        'New User',
      );

      expect(success, isTrue);
      expect(controller.state.user?.email, 'new@plenty.app');
      expect(controller.state.user?.displayName, 'New User');
    });

    test('logout resets user state', () async {
      when(
        () => mockAuthRepository.login(
          email: 'test@plenty.app',
          password: 'password123',
        ),
      ).thenAnswer((_) async => const Success(testUser));

      when(() => mockAuthRepository.logout())
          .thenAnswer((_) async => const Success(null));

      final controller = AuthController(authRepo: mockAuthRepository);
      await controller.login('test@plenty.app', 'password123');
      expect(controller.state.user, isNotNull);

      await controller.logout();
      expect(controller.state.user, isNull);
    });

    test('sendPasswordResetEmail calls repository', () async {
      when(() => mockAuthRepository.sendPasswordResetEmail('reset@plenty.app'))
          .thenAnswer((_) async => const Success(null));

      final controller = AuthController(authRepo: mockAuthRepository);
      final result = await controller.sendPasswordResetEmail('reset@plenty.app');

      expect(result, isTrue);
      verify(
        () => mockAuthRepository.sendPasswordResetEmail('reset@plenty.app'),
      ).called(1);
    });
  });
}
