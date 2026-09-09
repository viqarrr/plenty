import 'package:firebase_auth/firebase_auth.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/error/result.dart';
import 'package:plenty/core/storage/preference_handler.dart';
import 'package:plenty/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:plenty/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';
import 'package:plenty/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] combining Firebase Auth
/// for authentication and local SQLite for backwards-compatible transitional caching.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
  })  : _remoteDataSource =
            remoteDataSource ?? FirebaseAuthRemoteDataSourceImpl(),
        _localDataSource = localDataSource ?? AuthLocalDataSourceImpl();

  @override
  Stream<UserModel?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  UserModel? get currentUser => _remoteDataSource.currentUser;

  @override
  Future<Result<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );
      await PreferenceHandler.setLoginSession(userModel);

      // Transitional sync with SQLite users table for downstream relational integrity
      try {
        await _localDataSource.registerUser(userModel);
      } catch (_) {}

      return Success(userModel);
    } on FirebaseAuthException catch (e) {
      return Error(_mapFirebaseAuthException(e));
    } on FirebaseException catch (e) {
      return Error(DatabaseFailure(e.message ?? 'Terjadi kesalahan basis data Firebase.'));
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> register(UserModel user) async {
    try {
      final createdUser = await _remoteDataSource.signUp(
        email: user.email,
        password: user.password,
        displayName: user.displayName,
        username: user.username,
      );
      await PreferenceHandler.setLoginSession(createdUser);

      // Transitional sync with SQLite users table
      try {
        await _localDataSource.registerUser(createdUser);
      } catch (_) {}

      return const Success(true);
    } on FirebaseAuthException catch (e) {
      return Error(_mapFirebaseAuthException(e));
    } on FirebaseException catch (e) {
      return Error(DatabaseFailure(e.message ?? 'Terjadi kesalahan basis data Firebase.'));
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Error(_mapFirebaseAuthException(e));
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remoteDataSource.signOut();
      await PreferenceHandler.logOut();
      return const Success(null);
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<UserModel>>> getAllUsers() async {
    try {
      final models = await _localDataSource.getAllUsers();
      return Success(models);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> updateUser(UserModel user) async {
    try {
      final success = await _localDataSource.updateUser(user);
      return Success(success);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> deleteUser(String id) async {
    try {
      final success = await _localDataSource.deleteUser(id);
      return Success(success);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  /// Maps Firebase [FirebaseAuthException] to domain [Failure] types.
  Failure _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure('Email atau kata sandi tidak sesuai.');
      case 'email-already-in-use':
        return const ValidationFailure('Email sudah terdaftar. Silakan masuk.');
      case 'weak-password':
        return const ValidationFailure(
          'Kata sandi terlalu lemah (minimal 6 karakter).',
        );
      case 'invalid-email':
        return const ValidationFailure('Format email tidak valid.');
      case 'network-request-failed':
        return const NetworkFailure(
          'Koneksi internet bermasalah. Periksa sambungan Anda.',
        );
      case 'too-many-requests':
        return const AuthFailure(
          'Terlalu banyak percobaan gagal. Silakan coba sesaat lagi.',
        );
      default:
        return AuthFailure(e.message ?? 'Terjadi kesalahan autentikasi.');
    }
  }
}
