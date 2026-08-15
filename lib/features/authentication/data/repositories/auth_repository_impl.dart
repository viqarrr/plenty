import 'package:plenty/core/database/preference_handler.dart';
import 'package:plenty/core/error/failure.dart';
import 'package:plenty/core/utils/result.dart';
import 'package:plenty/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:plenty/features/authentication/data/models/user_model.dart';
import 'package:plenty/features/authentication/domain/entities/user_entity.dart';
import 'package:plenty/features/authentication/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _dataSource;

  AuthRepositoryImpl([AuthLocalDataSource? dataSource])
    : _dataSource = dataSource ?? AuthLocalDataSourceImpl();

  @override
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _dataSource.loginUser(email, password);
      if (userModel != null) {
        await PreferenceHandler.setLogin(true);
        await PreferenceHandler.setProfileName(userModel.displayName);
        return Success(userModel.toEntity());
      }
      return const Error(AuthFailure('Email atau password tidak sesuai'));
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> register(UserEntity user) async {
    try {
      final model = UserModel.fromEntity(user);
      final success = await _dataSource.registerUser(model);
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
  Future<Result<List<UserEntity>>> getAllUsers() async {
    try {
      final models = await _dataSource.getAllUsers();
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> updateUser(UserEntity user) async {
    try {
      final model = UserModel.fromEntity(user);
      final success = await _dataSource.updateUser(model);
      return Success(success);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await PreferenceHandler.logOut();
      return Success(null);
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
