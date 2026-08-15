// lib/features/authentication/domain/repositories/auth_repository.dart

import 'package:plenty/core/utils/result.dart';
import 'package:plenty/features/authentication/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Result<bool>> register(UserEntity user);

  Future<Result<List<UserEntity>>> getAllUsers();

  Future<Result<bool>> deleteUser(String id);

  Future<Result<bool>> updateUser(UserEntity user);

  Future<Result<void>> logout();
}
