import 'package:plenty/core/utils/result.dart';
import 'package:plenty/features/auth/domain/models/user_model.dart';

/// Contract interface for Authentication Repository.
abstract interface class AuthRepository {
  Future<Result<UserModel>> login({
    required String email,
    required String password,
  });

  Future<Result<bool>> register(UserModel user);

  Future<Result<List<UserModel>>> getAllUsers();

  Future<Result<bool>> deleteUser(String id);

  Future<Result<bool>> updateUser(UserModel user);

  Future<Result<void>> logout();
}
