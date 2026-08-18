import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/utils/result.dart';
import 'package:plenty/data/datasources/auth_local_datasource.dart';
import 'package:plenty/data/datasources/preference_handler.dart';
import 'package:plenty/data/models/user_model.dart';
import 'package:plenty/data/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _dataSource;

  AuthRepositoryImpl([AuthLocalDataSource? dataSource])
    : _dataSource = dataSource ?? AuthLocalDataSourceImpl();

  @override
  Future<Result<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _dataSource.loginUser(email, password);
      if (userModel != null) {
        await PreferenceHandler.setLoginSession(userModel);
        return Success(userModel);
      }
      return const Error(AuthFailure('Email atau password tidak sesuai'));
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> register(UserModel user) async {
    try {
      final success = await _dataSource.registerUser(user);
      if (success) {
        return const Success(true);
      }
      return const Error(
        ValidationFailure(
          'Gagal mendaftarkan user. Email atau username sudah ada.',
        ),
      );
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<UserModel>>> getAllUsers() async {
    try {
      final models = await _dataSource.getAllUsers();
      return Success(models);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> updateUser(UserModel user) async {
    try {
      final success = await _dataSource.updateUser(user);
      return Success(success);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await PreferenceHandler.logOut();
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> deleteUser(String id) async {
    try {
      final success = await _dataSource.deleteUser(id);
      return Success(success);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }
}
